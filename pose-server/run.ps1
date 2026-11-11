# pose-server 실행 (8000번 포트, silvercare 백엔드는 8001번)
#   접속 토큰을 쓰려면 실행 전에:  $env:POSE_SERVER_TOKEN = "원하는-토큰"   (앱은 ?token=원하는-토큰 으로 접속)
#   동시 접속 상한(기본 8):        $env:POSE_MAX_SESSIONS = "8"
Set-Location $PSScriptRoot
& C:\Users\DS\Desktop\cv\.venv\Scripts\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8000 --ws-max-size 4194304
