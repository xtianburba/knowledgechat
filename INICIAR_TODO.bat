@echo off
title OSAC Knowledge Bot - Iniciar Todo
color 0A
echo ========================================
echo OSAC Knowledge Bot - Iniciador
echo ========================================
echo.
echo IMPORTANTE: Este script abrira DOS ventanas
echo 1. Backend (puerto 8000)
echo 2. Frontend (puerto 3000)
echo.
echo NO CIERRES estas ventanas mientras uses el sistema
echo.
pause

echo.
echo Iniciando Backend...
start "OSAC Backend - NO CERRAR" cmd /k "cd /d %~dp0backend && call venv\Scripts\activate && uvicorn main:app --reload --host 0.0.0.0 --port 8000"

timeout /t 5 /nobreak >nul

echo.
echo Iniciando Frontend...
start "OSAC Frontend - NO CERRAR" cmd /k "cd /d %~dp0frontend && npm start"

echo.
echo ========================================
echo Servidores iniciando...
echo ========================================
echo.
echo Backend: http://localhost:8000
echo Frontend: http://localhost:3000 (se abrira automaticamente)
echo.
echo Espera 10-15 segundos y luego abre: http://localhost:3000
echo.
pause


