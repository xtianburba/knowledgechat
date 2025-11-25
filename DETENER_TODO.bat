@echo off
title OSAC Knowledge Bot - Detener Servidores
color 0C
echo ========================================
echo OSAC Knowledge Bot - Detener Servidores
echo ========================================
echo.
echo Deteniendo procesos...

REM Detener procesos de Node (Frontend)
echo Deteniendo Frontend (Node)...
taskkill /F /IM node.exe 2>nul
if %errorlevel% equ 0 (
    echo ✓ Frontend detenido
) else (
    echo ℹ No se encontraron procesos de Node
)

REM Detener procesos de Python/Uvicorn (Backend)
echo Deteniendo Backend (Python/Uvicorn)...
for /f "tokens=2" %%a in ('netstat -ano ^| findstr ":8000.*LISTENING"') do (
    taskkill /F /PID %%a 2>nul
    if !errorlevel! equ 0 (
        echo ✓ Backend detenido (PID: %%a)
    )
)

REM También intentar matar procesos python que podrían estar relacionados
taskkill /F /FI "WINDOWTITLE eq OSAC Backend*" 2>nul
taskkill /F /FI "WINDOWTITLE eq OSAC Frontend*" 2>nul

timeout /t 2 /nobreak >nul

echo.
echo ========================================
echo Procesos detenidos
echo ========================================
echo.
pause

