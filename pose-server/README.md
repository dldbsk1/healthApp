# pose-server

카메라 프레임을 실시간으로 받아 **운동 자세를 채점하고 반복 횟수를 세는** WebSocket 서버입니다.
iOS 앱이 JPEG 프레임을 보내면, 서버가 YOLO Pose로 관절 17개를 뽑고 규칙 기반으로 자세를 평가해 프레임마다 JSON으로 돌려줍니다.

- **지원 운동**: 레그레이즈 · 런지 · 플랭크 · 푸쉬업(무릎 푸쉬업)
- **실시간 피드백**: 항목별 통과/미달, 교정 문구, 점수(0~100), 반복 횟수 / 플랭크 유지 시간
- **세션 요약**: 운동을 마치면 항목별 점수와 피드백을 정리해서 반환
- **재접속 이어하기**: 네트워크가 잠깐 끊겨도 같은 `session_id`로 다시 붙으면 횟수·점수·시간이 이어짐
- **스택**: FastAPI · uvicorn · Ultralytics YOLO(pose) · OpenCV · PyTorch(CUDA 있으면 GPU 사용)

```
iOS 앱                                   pose-server
  │  ws://host:8000/ws/exercise-live?exercise=푸쉬업
  │ ─────────────────────────────────────────▶ │
  │  JPEG 프레임 (binary)                       │  디코딩 → YOLO Pose (추론 전용 스레드)
  │ ─────────────────────────────────────────▶ │  → 관절 정규화 → pose_rules 로 채점·횟수 집계
  │  분석 결과 JSON (프레임 1장당 응답 1개)        │
  │ ◀───────────────────────────────────────── │
  │        ... 반복 ...                         │
  │  "finish" (text)                            │
  │ ─────────────────────────────────────────▶ │
  │  세션 요약 JSON → 연결 종료                   │
  │ ◀───────────────────────────────────────── │
  │
  └─ 요약을 Spring Boot 백엔드(/api/exercises/logs)에 저장 (pose-server는 DB를 갖지 않음)
```

---

## 목차

1. [실행 방법](#1-실행-방법)
2. [WebSocket API](#2-websocket-api)
3. [채점 로직](#3-채점-로직)
4. [파일 구조](#4-파일-구조)
5. [테스트](#5-테스트)
6. [배포 참고](#6-배포-참고)

---

## 1. 실행 방법

### 요구 사항

- Python 3.10+
- (권장) CUDA 지원 GPU — 없으면 CPU로 동작하지만 프레임당 지연이 커집니다.

### 설치

```bash
pip install -r requirements.txt
pip install onnxruntime pandas   # analyzer.py / lstm.py 가 import 함
```

### 모델 가중치

`weights/` 는 용량 때문에 저장소에 포함하지 않습니다. 아래 파일을 `weights/` 폴더에 넣어주세요.

| 파일 | 용도 |
|---|---|
| `weights/yolo_ph2_best.pt` | 관절 추출용 YOLO Pose (파인튜닝 모델) |
| `weights/exercise_lstm_velo.pth` | 운동 분류 LSTM — 현재 실시간 서버에서는 쓰지 않지만 `load_models()` 가 로드함 |

### 서버 실행

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --ws-max-size 4194304
```

Windows에서는 [run.ps1](run.ps1) 을 써도 됩니다 (venv 경로는 환경에 맞게 수정).

정상 기동 확인: `GET http://localhost:8000/health` → `{"status": "ok"}`

### 환경 변수

| 이름 | 기본값 | 설명 |
|---|---|---|
| `POSE_SERVER_TOKEN` | (없음) | 설정하면 접속 시 `?token=` 값이 일치해야 연결됨. 없으면 인증 없이 접속 가능 |
| `POSE_MAX_SESSIONS` | `8` | 동시에 분석 중인 연결 수 상한. 넘으면 접속을 거절 (GPU 1개를 나눠 쓰기 때문) |

---

## 2. WebSocket API

### 연결

```
ws://<host>:8000/ws/exercise-live?exercise=<운동명>[&session_id=<id>][&token=<토큰>]
```

| 파라미터 | 필수 | 설명 |
|---|---|---|
| `exercise` | O | `레그레이즈` / `런지` / `플랭크` / `푸쉬업` (URL 인코딩) |
| `session_id` | X | 영문·숫자·`-`·`_` 64자 이내. 생략하면 서버가 만들어서 응답마다 알려줌 |
| `token` | 서버 설정 시 | `POSE_SERVER_TOKEN` 과 같은 값 |

### 클라이언트 → 서버

| 메시지 | 형식 | 설명 |
|---|---|---|
| 카메라 프레임 | **binary** (JPEG) | 긴 변 720px 안팎, 품질 0.6 정도 권장. 최대 2MB |
| 운동 종료 | **text** `"finish"` | 세션 요약을 받고 연결이 종료됨 |

**프레임 하나 당 응답 한 개** 응답을 받은 뒤 다음 프레임을 보내는 방식(lockstep)
초당 5~10프레임 정도면 횟수 판정에 충분합니다. 
판정은 프레임 수가 아니라 **서버 수신 시각** 기준이라 전송 속도가 달라도 결과가 같습니다.

### 서버 → 클라이언트

모든 응답은 JSON이며 `status` 로 구분합니다.

#### `analyzing` — 사람이 잡혀서 분석한 프레임

```json
{
  "status": "analyzing",
  "session_id": "3f2a...",
  "exercise": "푸쉬업",
  "phase": "down",
  "phase_label": "운동 중",
  "score": 75,
  "results": [
    { "label": "허리 정렬", "ok": true, "desc": "어깨~무릎이 일직선으로 잘 유지되고 있어요. (171.2°)", "weight": 3 },
    { "label": "팔꿈치 굽힘 깊이", "ok": false, "per_rep": true, "carry": true,
      "desc": "더 깊게 내려가세요. 팔꿈치를 100° 근처까지 굽혀주세요. (최소: 118°)", "weight": 3 }
  ],
  "keypoints": [[0.51, 0.32], [0.0, 0.0], "... 17개"],
  "rep_count": 4,
  "hold_seconds": null,
  "good_hold_seconds": null,
  "rep_event": false,
  "move": "down"
}
```

| 필드 | 설명 |
|---|---|
| `phase` | `none`(자세를 아직 안 잡음) / `up`(대기 자세) / `down`(운동 중) |
| `phase_label` | `phase` 의 한국어 표시 문구 |
| `score` | 이번 프레임 항목들의 가중 통과율(0~100). 안내(`hint`) 항목은 점수에서 제외 |
| `results` | 자세 체크리스트. 아래 표 참고 |
| `keypoints` | COCO 17관절 좌표, 이미지 크기로 나눈 0~1 값. 안 잡힌 관절은 `[0, 0]` |
| `rep_count` | 누적 반복 횟수 (플랭크는 `null`) |
| `hold_seconds` / `good_hold_seconds` | 플랭크만: 버틴 시간 / 그중 정상 자세로 버틴 시간(초) |
| `rep_event` | 이 프레임에서 반복이 1회 완료됨 → 효과음·진동 트리거용 |
| `move` | 레그레이즈·푸쉬업만: 지금 `up`(올리는 중) / `down`(내리는 중) / `null` |

`results` 항목 필드:

| 필드 | 설명 |
|---|---|
| `label`, `ok`, `desc` | 항목 이름, 통과 여부, 사용자에게 보여줄 문구 |
| `weight` | 점수 가중치 (0이면 점수에 반영 안 됨) |
| `per_rep` | 반복이 끝날 때 한 번 채점되는 항목 (예: 굽힘 깊이) |
| `carry` | 직전 반복의 결과를 화면 유지용으로 다시 보낸 것. 통계에는 중복 집계되지 않음 |
| `hint` | 정식 채점 전 실시간 안내 (점수 제외) |

#### `no_person` — 사람이 안 잡혔거나 디코딩에 실패한 프레임

```json
{ "status": "no_person", "session_id": "3f2a..." }
```

#### `error`

```json
{ "status": "error", "message": "서버가 혼잡합니다. 잠시 후 다시 시도해주세요." }
```

- **접속 단계 거절** (토큰 불일치, 잘못된 운동명/`session_id`, 동시 접속 초과): 이 메시지 후 close code `1008` 로 연결 종료
- **프레임이 2MB 초과**: 연결은 유지되므로 다음 프레임을 보내면 됨

#### `session_summary` — `"finish"` 에 대한 응답

```json
{
  "status": "session_summary",
  "session_id": "3f2a...",
  "exercise": "푸쉬업",
  "avgScore": 78,
  "durationMin": 3,
  "durationSec": 162.4,
  "repCount": 12,
  "holdSeconds": null,
  "goodHoldSeconds": null,
  "itemScores": [ { "label": "팔꿈치 굽힘 깊이", "score": 58, "weight": 3 } ],
  "feedbacks": [ { "title": "⚠️ 팔꿈치 굽힘 깊이", "text": "조금만 더 다듬으면 될 것 같아요. 더 깊게 내려가세요." } ]
}
```

- `durationMin` 은 반올림한 정수이며 최소 1입니다 (백엔드 스펙이 1 이상의 정수). 정확한 값은 `durationSec`.
- 연결이 끊겨 있던 시간은 운동 시간에서 빠집니다.

### 재접속 (세션 이어하기)

연결이 `"finish"` 없이 끊기면 서버는 세션을 **5분간 보관**
그 안에 같은 `exercise` 와 `session_id` 로 다시 연결하면 횟수·점수·시간이 그대로 이어집니다.

1. 첫 응답의 `session_id` 를 저장 (또는 앱이 UUID를 만들어 처음부터 `&session_id=` 로 전달)
2. 끊기면 같은 URL에 `&session_id=<저장한 값>` 을 붙여 재연결
3. 이전 연결이 서버에 아직 살아있으면 서버가 그 연결을 닫고(code `1012`) 새 연결로 넘깁니다

---

## 3. 채점 로직

모든 판정은 [pose_rules.py](pose_rules.py) 의 `ExerciseEvaluator` (연결당 1개) 가 담당합니다.

### 처리 순서 (프레임마다)

1. **관절 추출** — YOLO Pose 결과 중 가장 큰 사람 1명을 고르고, 신뢰도 낮은 관절은 `(0,0)` 으로 마스킹 후 0~1로 정규화
2. **준비 자세 판정** — 몸통 기울기로 운동 시작 자세인지 확인 (누운/엎드린 운동은 수직에서 50° 이상, 런지는 35° 이내).
   0.4초 연속으로 맞아야 시작, 0.7초 연속으로 벗어나야 해제. 준비 전에는 채점도 횟수 집계도 하지 않음
3. **측면 선택** — 옆모습에서는 카메라 쪽 팔다리가 더 정확하므로, 신뢰도가 높은 쪽을 골라 그쪽 관절로 측정
4. **구간/반복 판정** — 운동별 핵심 각도를 0.3초 중앙값으로 평활화한 뒤 구간(올라감/내려감) 전환과 반복을 판정
5. **항목 채점** — 매 프레임 항목 + 반복이 끝날 때 한 번 채점하는 항목을 합쳐 가중 점수 계산

판정 시간은 전부 **초 단위**입니다. 앱의 전송 fps가 바뀌어도 기준이 달라지지 않습니다.

### 운동별 기준

| 운동 | 횟수 판정 | 매 프레임 항목 | 반복당 항목 |
|---|---|---|---|
| 푸쉬업 | 팔꿈치 각도가 30° 이상 내려갔다가 그 60% 이상 되돌아오면 1회 (절대 각도 무관 → 카메라 각도에 강함) | 허리 정렬 | 팔꿈치 굽힘 깊이 (≤100°), 펴짐 정도 (≥150°) |
| 레그레이즈 | 몸통-다리 각도가 130° 미만 구간에 들어갔다 나오면 1회 | 무릎 펴짐, 목~골반 일직선 | 들어올린 높이 (≤120°), 내린 높이 (≥140°) |
| 런지 | 뒷무릎 각도가 120° 미만 구간에 들어갔다 나오면 1회 | 앞무릎 각도, 뒷무릎 각도, 상체 일직선 | — |
| 플랭크 | 반복 없음 → 버틴 시간 | 목~골반 일직선, 엉덩이 높이, 다리 일직선, 팔 각도 | — |

- 각도 기준값은 [pose_rules.py](pose_rules.py) 상단 상수로 모여 있습니다.
- 항목 가중치는 `RULE_WEIGHTS` 에 있습니다.
- 플랭크의 `good_hold_seconds` 는 가중치 2 이상 항목이 최근 0.4초 중 60% 이상 통과한 구간만 누적한 값입니다.

---

## 4. 파일 구조

| 파일 | 역할 |
|---|---|
| [main.py](main.py) | FastAPI 앱, WebSocket 엔드포인트, 세션 보관/재접속, 인증·접속 수 제한 |
| [pose_rules.py](pose_rules.py) | 자세 규칙, 구간·반복 판정, 점수 계산 (`ExerciseEvaluator`) |
| [session_state.py](session_state.py) | 세션 단위 집계: 플랭크 유지 시간, 운동 시간, 요약 생성 (`ExerciseSession`) |
| [analyzer.py](analyzer.py) | 모델 로드, 관절 선택·정규화 유틸, 녹화 영상 일괄 분석(`analyze_video`) |
| [lstm.py](lstm.py), [features.py](features.py) | 운동 분류 LSTM 모델 정의·학습 코드 (실시간 서버는 사용자가 운동을 선택하므로 분류 미사용) |
| [config.py](config.py) | 경로·하이퍼파라미터 설정 |
| [schemas.py](schemas.py) | 응답 형식 Pydantic 모델 (참고용) |
| [web_test.py](web_test.py) | 영상/웹캠으로 서버를 테스트하는 클라이언트 |
| [run.ps1](run.ps1) | Windows 실행 스크립트 |

---

## 5. 테스트

서버를 띄운 상태에서 영상 파일이나 웹캠으로 실제 앱처럼 프레임을 보내볼 수 있습니다.
영상은 실제 재생 속도에 맞춰 전송되고, 끝나면 세션 요약을 출력합니다.

```bash
python web_test.py --video pushup.mp4 --exercise 푸쉬업
python web_test.py --webcam --exercise 플랭크
python web_test.py --video sample.mp4 --exercise 레그레이즈 --token <토큰>   # 토큰을 설정한 경우
```