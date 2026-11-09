# -*- coding: utf-8 -*-
"""
실시간 운동 자세 분석 서버 (LSTM 자동분류 없음 버전).

사용자가 앱에서 운동 종류를 먼저 고르고 들어온다는 전제로,
웹소켓 연결 시 쿼리파라미터로 운동명을 받아 그대로 사용한다.
  ws://.../ws/exercise-live?exercise=런지

이러면:
  - "35프레임 모아야 판단 가능" 같은 초반 대기(collecting) 단계가 아예 없다
  - 첫 프레임부터 바로 자세 채점(analyzing) 시작 → 반복횟수 누락 문제 해결
  - LSTM 오분류(플랭크/푸쉬업 등) 문제 자체가 발생하지 않음

프로토콜은 기존과 동일:
  - 클라이언트 → 서버: 카메라 프레임(JPEG bytes)
  - 서버 → 클라이언트: 프레임마다 분석 결과 JSON
  - 클라이언트가 텍스트로 "finish" 를 보내면 세션 요약(session_summary)을 보내고 종료
"""

import logging

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

# ⭐ GPU가 없는 환경(로컬 CPU 등)에서도 돌아가도록 자동 감지.
#    device=0으로 고정하면 CUDA가 없는 머신에서 predict() 호출 자체가 예외를 던지고,
#    그 예외가 while 루프를 감싼 try/except에 잡혀 세션이 바로 끊긴다 — "스켈레톤이 안 보임"의 원인.
YOLO_DEVICE = 0 if torch.cuda.is_available() else "cpu"
logger.info("YOLO 추론 디바이스: %s", YOLO_DEVICE)

VALID_EXERCISES = set(EXERCISE_RULES.keys())   # {"레그레이즈", "런지", "플랭크", "푸쉬업"}
MISS_TOLERANCE_FRAMES = 5


@app.get("/health")
def health():
    return {"status": "ok"}


@app.websocket("/ws/exercise-live")
async def exercise_live(ws: WebSocket):
    exercise_name = ws.query_params.get("exercise")
    await ws.accept()

    if exercise_name not in VALID_EXERCISES:
        await ws.send_json({
            "status": "error",
            "message": f"지원하지 않는 운동입니다: {exercise_name!r}. 가능한 값: {sorted(VALID_EXERCISES)}",
        })
        await ws.close()
        return

    session = ExerciseSession(exercise_name=exercise_name)
    evaluator = ExerciseEvaluator(exercise_name)   # 가까운 쪽 고정·반복당 극값 추적 등 상태를 가짐 (세션당 1개)
    last_score = 0
    logger.info("클라이언트 연결됨 (운동: %s)", exercise_name)

    try:
        while True:
            message = await ws.receive()

            if message["type"] == "websocket.disconnect":
                break

            text = message.get("text")
            if text is not None:
                if text == "finish":
                    summary = session.compute_summary()
                    await ws.send_json(summary)
                    logger.info("세션 요약 전송 후 종료: %s", summary)
                    break
                continue

            data = message.get("bytes")
            if data is None:
                continue

            # ⭐ 프레임 단위로 try/except를 둬서, 한 프레임 처리 중 에러가 나도
            #    세션(웹소켓 연결) 전체가 끊기지 않고 다음 프레임부터 계속 이어가도록 함.
            try:
                frame = cv2.imdecode(np.frombuffer(data, np.uint8), cv2.IMREAD_COLOR)
                if frame is None:
                    await ws.send_json({"status": "no_person"})   # 응답을 기다리는 클라이언트가 1초 타임아웃에 걸리지 않게
                    continue

                h, w = frame.shape[:2]

                result = pose_model.predict(frame, conf=DET_CONF, imgsz=IMGSZ, verbose=False, device=YOLO_DEVICE)[0]
                xy, conf = _pick_main(result)

                if xy is None:
                    session.mark_person_missed()
                    await ws.send_json({"status": "no_person"})
                    continue

                session.mark_person_seen()

                masked = _mask_low_conf(xy, conf, KP_CONF).astype(np.float32)
                norm = _normalize(masked, w, h)
                session.frame_count += 1

                # 운동 종류를 이미 알고 있으므로 첫 프레임부터 바로 채점
                #   conf: 가까운 쪽 판단용, aspect: 세로/가로 영상에서 각도가 찌그러지지 않게 보정
                #   자세를 잡기 전(phase=none)에는 채점하지 않고, 런지는 서 있는 대기 구간도 채점하지 않음(only_active=True)
                results, phase = evaluator.evaluate(norm, conf=conf, aspect=w / h, only_active=True)
                if any(not r.get("hint") for r in results):   # 안내(hint)만 있는 프레임은 점수를 건드리지 않음
                    last_score = calc_score(results)
                score = last_score   # 채점 안 하는 프레임은 직전 점수 유지 (화면에 0점이 깜빡이지 않게)
                session.rep_count = evaluator.rep_count
                session.record_frame(results, phase, score)
                keypoints_out = norm.tolist()

                await ws.send_json({
                    "status": "analyzing",
                    "exercise": exercise_name,
                    "phase": phase,
                    "phase_label": PHASE_LABEL.get(phase, phase),
                    "score": score,
                    "results": results,
                    "keypoints": keypoints_out,
                    # 실시간 카운팅 (반복 운동: rep_count / 플랭크: hold_seconds, good_hold_seconds)
                    **session.live_stats(),
                    "rep_event": evaluator.rep_event,   # 이 프레임에서 1회 완료됐으면 true (효과음·진동 트리거용)
                })
            except Exception:
                logger.exception("프레임 처리 중 오류 — 이 프레임만 건너뜀")
                try:
                    await ws.send_json({"status": "no_person"})   # 응답 대기 중인 클라이언트가 멈추지 않게
                except Exception:
                    pass
                continue

    except WebSocketDisconnect:
        logger.info("클라이언트 연결 끊김 (요약 없이 종료)")
    except Exception as e:
        logger.exception("세션 처리 중 오류")
        try:
            await ws.send_json({"status": "error", "message": str(e)})
        except Exception:
            pass