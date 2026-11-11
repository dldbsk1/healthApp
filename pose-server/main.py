# -*- coding: utf-8 -*-
"""
실시간 운동 자세 분석 서버

연결: ws://.../ws/exercise-live?exercise=<운동명>[&session_id=<id>][&token=<토큰>]
  - session_id : 연결이 끊겼다가 같은 값으로 다시 접속하면 세션(횟수·점수·시간)을 이어서 진행.
                 안 보내면 서버가 만들어서 응답마다 "session_id" 로 알려준다.
  - token      : 서버에 POSE_SERVER_TOKEN 환경변수가 설정된 경우에만 필요.
"""

import asyncio
import logging
import os
import re
import secrets
import uuid
from concurrent.futures import ThreadPoolExecutor
from time import time

import cv2
import numpy as np
import torch
from fastapi import FastAPI, WebSocket, WebSocketDisconnect

from analyzer import (
    load_models,
    _pick_main,
    _mask_low_conf,
    _normalize,
    IMGSZ,
    KP_CONF,
    DET_CONF,
)
from pose_rules import ExerciseEvaluator, calc_score, PHASE_LABEL, EXERCISE_RULES
from session_state import ExerciseSession

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("pose-server")

app = FastAPI(title="Pose Analysis Server")

# LSTM은 이 버전에서 안 쓰지만, YOLO 모델 로딩은 그대로 load_models()를 재사용
pose_model, _lstm_model_unused, _device_unused, _ = load_models()

YOLO_DEVICE = 0 if torch.cuda.is_available() else "cpu"
logger.info("YOLO 추론 디바이스: %s", YOLO_DEVICE)

VALID_EXERCISES = set(EXERCISE_RULES.keys())   # {"레그레이즈", "런지", "플랭크", "푸쉬업"}
MISS_TOLERANCE_FRAMES = 5

# ── 접근 제한 / 자원 보호 (환경변수로 조정) ──
SERVER_TOKEN = os.environ.get("POSE_SERVER_TOKEN") or None        # 설정하면 ?token= 이 일치해야 접속 가능 (미설정이면 인증 없음)
MAX_SESSIONS = int(os.environ.get("POSE_MAX_SESSIONS", "8"))      # 동시에 분석 중인 연결 수 상한 (GPU 1개를 나눠 씀)
MAX_FRAME_BYTES = 2 * 1024 * 1024    # 프레임 1장 최대 크기
LARGE_FRAME_BYTES = 200 * 1024       # 이보다 큰 JPEG는 1/2 크기로 디코딩 (YOLO 입력이 640px이라 결과 차이 없이 디코딩만 빨라짐)

SESSION_RESUME_SEC = 300             # 끊긴 세션을 보관하는 시간. 이 안에 같은 session_id로 재접속하면 이어서 진행
_SESSION_ID_RE = re.compile(r"^[A-Za-z0-9_-]{1,64}$")

# YOLO 추론은 이 스레드 1개에서만 실행: 이벤트 루프(다른 연결의 송수신)를 막지 않고,
# 모델 객체를 여러 스레드가 동시에 쓰지 않게 한다. (GPU 1개라 동시에 돌려도 빨라지지 않음)
_infer_executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="yolo")


def _infer(data: bytes):
    """JPEG 디코딩 + YOLO 추론 (추론 스레드에서 실행).
    반환: None(디코딩 실패) 또는 (xy, conf, w, h) — 사람이 없으면 xy, conf 가 None."""
    flag = cv2.IMREAD_REDUCED_COLOR_2 if len(data) > LARGE_FRAME_BYTES else cv2.IMREAD_COLOR
    frame = cv2.imdecode(np.frombuffer(data, np.uint8), flag)
    if frame is None:
        return None
    h, w = frame.shape[:2]
    result = pose_model.predict(frame, conf=DET_CONF, imgsz=IMGSZ, verbose=False, device=YOLO_DEVICE)[0]
    xy, conf = _pick_main(result)
    return xy, conf, w, h


class _LiveSession:
    """재접속해도 이어서 쓸 수 있게 보관하는 세션 상태 (집계 + 평가기)."""

    def __init__(self, sid: str, exercise_name: str):
        self.sid = sid
        self.session = ExerciseSession(exercise_name=exercise_name)
        self.evaluator = ExerciseEvaluator(exercise_name)
        self.last_score = 0
        self.ws = None           # 지금 이 세션을 쓰는 연결 (끊겨서 보관 중이면 None)
        self.parked_at = None


_sessions: dict[str, _LiveSession] = {}


def _purge_expired(now: float):
    expired = [sid for sid, e in _sessions.items()
               if e.ws is None and e.parked_at is not None and now - e.parked_at > SESSION_RESUME_SEC]
    for sid in expired:
        del _sessions[sid]
        logger.info("보관 시간이 지난 세션 삭제: %s", sid)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.websocket("/ws/exercise-live")
async def exercise_live(ws: WebSocket):
    query = ws.query_params
    exercise_name = query.get("exercise")
    await ws.accept()

    async def reject(message: str):
        await ws.send_json({"status": "error", "message": message})
        await ws.close(code=1008)

    if SERVER_TOKEN and not secrets.compare_digest(query.get("token", ""), SERVER_TOKEN):
        await reject("인증 실패: token 이 올바르지 않습니다.")
        return

    if exercise_name not in VALID_EXERCISES:
        await reject(f"지원하지 않는 운동입니다: {exercise_name!r}. 가능한 값: {sorted(VALID_EXERCISES)}")
        return

    sid = query.get("session_id")
    if sid is not None and not _SESSION_ID_RE.match(sid):
        await reject("session_id 는 영문·숫자·-·_ 로 64자 이내여야 합니다.")
        return

    _purge_expired(time())
    entry = _sessions.get(sid) if sid else None
    if entry is not None and entry.session.exercise_name != exercise_name:
        await reject(f"이 session_id 는 다른 운동({entry.session.exercise_name})에 사용 중입니다.")
        return

    active = sum(1 for e in _sessions.values() if e.ws is not None and e is not entry)
    if active >= MAX_SESSIONS:
        await reject("서버가 혼잡합니다. 잠시 후 다시 시도해주세요.")
        return

    if entry is None:
        sid = sid or uuid.uuid4().hex
        entry = _sessions[sid] = _LiveSession(sid, exercise_name)
        logger.info("클라이언트 연결됨 (운동: %s, 세션: %s)", exercise_name, sid)
    else:
        old_ws, entry.ws = entry.ws, None
        entry.session.resume()
        logger.info("세션 이어서 진행 (운동: %s, 세션: %s)", exercise_name, sid)
        if old_ws is not None:   # 서버가 아직 끊김을 모르는 이전 연결 → 정리하고 새 연결로 넘김
            try:
                await old_ws.close(code=1012)
            except Exception:
                pass
    entry.ws = ws
    entry.parked_at = None

    session, evaluator = entry.session, entry.evaluator
    loop = asyncio.get_running_loop()
    finished = False

    try:
        while True:
            message = await ws.receive()

            if message["type"] == "websocket.disconnect":
                break
            if entry.ws is not ws:   # 같은 session_id 로 새 연결이 들어와 넘겨줬음
                break

            text = message.get("text")
            if text is not None:
                if text == "finish":
                    summary = session.compute_summary()
                    summary["session_id"] = sid
                    finished = True
                    _sessions.pop(sid, None)
                    await ws.send_json(summary)
                    logger.info("세션 요약 전송 후 종료: %s", summary)
                    break
                continue

            data = message.get("bytes")
            if data is None:
                continue

            if len(data) > MAX_FRAME_BYTES:
                await ws.send_json({"status": "error", "session_id": sid,
                                    "message": f"프레임이 너무 큽니다 ({len(data) // 1024}KB). "
                                               f"{MAX_FRAME_BYTES // 1024 // 1024}MB 이하로 줄여서 보내주세요."})
                continue

            try:
                inferred = await loop.run_in_executor(_infer_executor, _infer, data)
                if entry.ws is not ws:
                    break
                if inferred is None:
                    await ws.send_json({"status": "no_person", "session_id": sid})   # 응답을 기다리는 클라이언트가 1초 타임아웃에 걸리지 않게
                    continue

                xy, conf, w, h = inferred
                if xy is None:
                    session.mark_person_missed()
                    await ws.send_json({"status": "no_person", "session_id": sid})
                    continue

                session.mark_person_seen()

                masked = _mask_low_conf(xy, conf, KP_CONF).astype(np.float32)
                norm = _normalize(masked, w, h)
                session.frame_count += 1

                now = time()
                results, phase = evaluator.evaluate(norm, conf=conf, aspect=w / h, only_active=True, t=now)
                if any(not r.get("hint") for r in results):
                    entry.last_score = calc_score(results)
                score = entry.last_score
                session.rep_count = evaluator.rep_count
                session.record_frame(results, phase, score, now=now)
                keypoints_out = norm.tolist()

                await ws.send_json({
                    "status": "analyzing",
                    "session_id": sid,
                    "exercise": exercise_name,
                    "phase": phase,
                    "phase_label": PHASE_LABEL.get(phase, phase),
                    "score": score,
                    "results": results,
                    "keypoints": keypoints_out,
                    **session.live_stats(),
                    "rep_event": evaluator.rep_event,
                    "move": evaluator.move,
                })
            except Exception:
                logger.exception("프레임 처리 중 오류 — 이 프레임만 건너뜀")
                try:
                    await ws.send_json({"status": "no_person", "session_id": sid})
                except Exception:
                    pass
                continue

    except WebSocketDisconnect:
        logger.info("클라이언트 연결 끊김 (세션: %s)", sid)
    except Exception as e:
        logger.exception("세션 처리 중 오류")
        try:
            await ws.send_json({"status": "error", "session_id": sid, "message": str(e)})
        except Exception:
            pass
    finally:
        if not finished and entry.ws is ws:
            entry.ws = None
            entry.parked_at = time()
            session.pause()
            logger.info("세션 %s 보관 — %d초 안에 같은 session_id로 재접속하면 이어서 진행", sid, SESSION_RESUME_SEC)
