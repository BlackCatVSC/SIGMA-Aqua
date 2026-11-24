@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Interno\Herramientas.ps1" -Mode Tests
set "RC=%ERRORLEVEL%"
pause
exit /b %RC%
