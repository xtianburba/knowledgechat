@echo off
echo ========================================
echo Iniciando OSAC Knowledge Bot - Backend
echo ========================================
cd backend
call venv\Scripts\activate
echo.
echo Servidor iniciando en http://localhost:8000
echo Presiona Ctrl+C para detener el servidor
echo.
uvicorn main:app --reload --host 0.0.0.0 --port 8000
pause


