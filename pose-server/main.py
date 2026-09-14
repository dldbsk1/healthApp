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
from pose_rules import evaluate_pose, calc_score, PHASE_LABEL, EXERCISE_RULES
from session_state import ExerciseSession

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("pose-server")

app = FastAPI(title="Pose Analysis Server")

# LSTM은 이 버전에서 안 쓰지만, YOLO 모델 로딩은 그대로 load_models()를 재사용
pose_model, _lstm_model_unused, _device_unused, _ = load_models()

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

            frame = cv2.imdecode(np.frombuffer(data, np.uint8), cv2.IMREAD_COLOR)
            if frame is None:
                continue

            h, w = frame.shape[:2]

            result = pose_model.predict(frame, conf=DET_CONF, imgsz=IMGSZ, verbose=False, device=0)[0]
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
            results, phase = evaluate_pose(exercise_name, norm, only_active=False)
            score = calc_score(results)
            session.record_frame(results, phase, score)

            await ws.send_json({
                "status": "analyzing",
                "exercise": exercise_name,
                "phase": phase,
                "phase_label": PHASE_LABEL.get(phase, phase),
                "score": score,
                "results": results,
            })

    except WebSocketDisconnect:
        logger.info("클라이언트 연결 끊김 (요약 없이 종료)")
    except Exception as e:
        logger.exception("세션 처리 중 오류")
        try:
            await ws.send_json({"status": "error", "message": str(e)})
        except Exception:
            pass