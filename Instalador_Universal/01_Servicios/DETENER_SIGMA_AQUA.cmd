@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Interno\Instalar.ps1" -Mode Stop
set "RC=%ERRORLEVEL%"
pause
exit /b %RC%
