# -*- coding: utf-8 -*-
"""
pose-server 웹소켓(/ws/exercise-live) 동작 확인용 테스트 스크립트.

사용법:
  영상 파일로 테스트: python test_ws.py --video 테스트영상.mp4
  웹캠으로 테스트:     python test_ws.py --webcam
"""

import argparse
import asyncio
import json

import cv2
import websockets

SERVER_URL_TEMPLATE = "ws://localhost:8000/ws/exercise-live?exercise={exercise}"


async def run(source, exercise):
    server_url = SERVER_URL_TEMPLATE.format(exercise=exercise)
    cap = cv2.VideoCapture(source)
    if not cap.isOpened():
        print(f"영상/웹캠을 열 수 없습니다: {source}")
        return

    is_video_file = isinstance(source, str)
    video_fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    keep_every_n = 3
    # 3프레임마다 1개를 보내니까, 보낸 프레임 사이의 "영상 속 실제 시간 간격"은 이만큼이어야 함
    target_interval = keep_every_n / video_fps if is_video_file else 0.0

    print(f"연결 시도: {server_url}")
    if is_video_file:
        print(f"영상 fps: {video_fps:.1f} → 프레임 간 목표 전송 간격: {target_interval*1000:.0f}ms (실제 재생 속도에 맞춤)")

    async with websockets.connect(server_url) as ws:
        print("연결 성공. 프레임 전송 시작 (Ctrl+C로 종료 → 종료 시 세션 요약도 함께 확인)")
        frame_idx = 0
        last_sent_at = None
        try:
            while True:
                ok, frame = cap.read()
                if not ok:
                    print("영상이 끝났습니다.")
                    break

                frame_idx += 1
                if frame_idx % keep_every_n != 0:
                    continue

                # 영상 파일이면 실제 재생 속도에 맞춰 페이싱 (처리 시간만큼은 빼고 나머지만 대기)
                if is_video_file and last_sent_at is not None:
                    elapsed = asyncio.get_event_loop().time() - last_sent_at
                    wait = target_interval - elapsed
                    if wait > 0:
                        await asyncio.sleep(wait)

                _, jpg = cv2.imencode(".jpg", frame)
                await ws.send(jpg.tobytes())
                last_sent_at = asyncio.get_event_loop().time()

                response = await ws.recv()
                data = json.loads(response)
                print(data)

                if not is_video_file:
                    await asyncio.sleep(0.03)   # 웹캠은 기존처럼 고정 간격
        except KeyboardInterrupt:
            print("종료 요청됨.")
        finally:
            cap.release()

        # ── 세션 요약 요청 ──
        # 영상이 끝났든, Ctrl+C로 끊었든 여기서 "finish"를 보내서
        # repCount/holdSeconds/avgScore 등 최종 집계 결과를 확인한다.
        try:
            print("\n세션 요약 요청 중...")
            await ws.send("finish")
            summary_raw = await ws.recv()
            summary = json.loads(summary_raw)
            print("\n===== 세션 요약 =====")
            print(json.dumps(summary, ensure_ascii=False, indent=2))
        except Exception as e:
            print(f"세션 요약을 받지 못했습니다: {e}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--video", type=str, help="테스트할 mp4 파일 경로")
    group.add_argument("--webcam", action="store_true", help="웹캠(0번 장치)으로 테스트")
    parser.add_argument("--exercise", type=str, required=True,
                         choices=["레그레이즈", "런지", "플랭크", "푸쉬업"],
                         help="테스트할 운동 이름 (예: 런지)")
    args = parser.parse_args()

    source = args.video if args.video else 0
    asyncio.run(run(source, args.exercise))