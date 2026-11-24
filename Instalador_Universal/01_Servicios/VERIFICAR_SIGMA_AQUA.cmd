@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Interno\Verificar.ps1"
set "RC=%ERRORLEVEL%"
pause
exit /b %RC%
