@echo off
set "BACKEND_DIR=%~dp0backend"
cd /d "%BACKEND_DIR%"

echo ==============================================
echo   STARTING POCKETMIND DESKTOP BRIDGE
echo ==============================================

if not exist venv (
    echo [INFO] Creating Python Virtual Environment...
    python -m venv venv
)

echo [INFO] activating venv...
call venv\Scripts\activate

echo [INFO] installing dependencies...
pip install -r requirements.txt --quiet

echo [INFO] Launching Server...
python server.py

pause
