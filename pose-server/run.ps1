# pose-server 실행 (8000번 포트, silvercare 백엔드는 8001번)
Set-Location $PSScriptRoot
& C:\Users\DS\Desktop\cv\.venv\Scripts\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8000
