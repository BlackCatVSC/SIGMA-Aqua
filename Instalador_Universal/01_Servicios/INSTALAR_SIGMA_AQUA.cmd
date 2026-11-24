@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Interno\Instalar.ps1" -Mode Install
set "RC=%ERRORLEVEL%"
pause
exit /b %RC%
