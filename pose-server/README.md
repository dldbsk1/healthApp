# 실시간 자세 분석 서버 (pose-server)

Streamlit 프로토타입에서 UI를 걷어내고, 실시간 추론 로직만 FastAPI 웹소켓 서버로 옮긴 것입니다.

## 1. 준비

```bash
cd pose-server
# 기존에 만들어두신 analyzer.py 를 이 폴더에 복사해 넣으세요.
cp /path/to/your/analyzer.py .

pip install -r requirements.txt
```

## 2. 실행

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

`http://localhost:8000/health` 로 접속해서 `{"status": "ok"}` 가 뜨면 정상 기동된 것입니다.

## 3. 동작 흐름

```
Swift 앱                        pose-server (FastAPI)
  │  ws://.../ws/exercise-live 연결                │
  │ ───────────────────────────────────────────▶  │
  │  카메라 프레임 (JPEG bytes) 계속 전송            │
  │ ───────────────────────────────────────────▶  │
  │                                                │  YOLO Pose 추출 → LSTM 운동 분류
  │                                                │  → pose_rules.py 로 자세 채점
  │  JSON 응답 (프레임마다 1개)                       │
  │ ◀───────────────────────────────────────────  │
  │  운동 종료 → 연결 종료                            │
  │ ───────────────────────────────────────────▶  │
```

## 4. Swift → 서버로 보내는 것

카메라에서 받은 프레임을 JPEG로 압축해서 **binary**로 그대로 전송합니다.

```swift
if let jpegData = ciImage.jpegData(compressionQuality: 0.6) {
    webSocketTask.send(.data(jpegData)) { error in ... }
}
```

배터리/네트워크 부담을 줄이려면 모든 프레임을 보내지 말고 **초당 5~10프레임 정도로 다운샘플링**해서 보내는 걸 추천합니다.

## 5. 서버 → Swift로 오는 JSON

상태(status)에 따라 3가지 형태 중 하나가 옵니다.

**사람이 안 보일 때**
```json
{ "status": "no_person" }
```

**운동 종류를 아직 판별 중일 때 (첫 30프레임 모으는 중)**
```json
{ "status": "collecting", "buffered": 12 }
```

**분석 중 (매 프레임)**
```json
{
  "status": "analyzing",
  "exercise": "런지",
  "confidence": 92.3,
  "phase": "down",
  "phase_label": "운동 중",
  "score": 82,
  "results": [
    { "label": "앞무릎 각도", "ok": true,  "desc": "앞무릎 각도가 적절해요. (91.2°)", "weight": 3 },
    { "label": "상체 일직선", "ok": false, "desc": "상체가 앞으로 기울어졌어요. 허리를 세워주세요. (148.0°)", "weight": 2 }
  ]
}
```

`results` 배열이 곧 프론트 스펙(운동탭 `ExerciseLiveView`)의 자세 가이드 체크리스트 항목입니다. `ok` 값으로 ✅/❌를 그대로 그리고, `desc`를 그 옆 피드백 텍스트로 쓰면 됩니다.

## 6. 운동이 끝나면 → Spring Boot에 저장

pose-server는 로그를 DB에 저장하지 않습니다 (실시간 추론만 담당). 운동을 마치면 Swift가 지금까지 받은 `score` 들의 평균, 총 운동 시간 등을 계산해서 Spring Boot 백엔드로 보냅니다.

```
POST http://<spring-boot-host>:8080/api/exercises/logs
Authorization: Bearer <JWT>
Content-Type: application/json

{
  "exerciseName": "런지",
  "durationMin": 8,
  "sets": 3,
  "reps": 12,
  "caloriesBurned": 45,
  "score": 82.5,
  "feedback": "앞무릎 각도는 좋았지만 상체가 앞으로 기울어지는 경향이 있었어요",
  "exercisedAt": "2026-07-27T18:30:00"
}
```

(이 API는 지난번 전달드린 `chwijung-backend` 프로젝트의 `ExerciseLogController`에 이미 구현되어 있습니다.)

## 7. 배포 시 참고

- 이 서버는 GPU가 있으면 `torch.cuda.is_available()` 로 자동으로 GPU를 씁니다. 배포 환경(EC2 GPU 인스턴스 등)에 맞게 `load_models()` 안의 device 선택 로직을 확인하세요.
- 웹소켓은 로드밸런서를 거칠 때 sticky session 설정이 필요할 수 있습니다. 인스턴스 1대로 먼저 테스트해보시고, 트래픽이 늘면 그때 스케일 아웃 방식을 고민하시면 됩니다.
- Spring Boot와 pose-server는 완전히 분리된 서버이므로, 배포 시 포트만 다르게 해서 같은 서버에 함께 띄워도 되고 별도 서버로 분리해도 됩니다.
