@echo off
setlocal
:menu
cls
echo SIGMA-AQUA - CENTRO DE CONTROL V4
echo.
echo 01. INSTALAR_SIGMA_AQUA
echo 02. INICIAR_SIGMA_AQUA
echo 03. DETENER_SIGMA_AQUA
echo 04. VERIFICAR_SIGMA_AQUA
echo 05. VERIFICAR_PERSISTENCIA
echo 06. Abrir MongoDB Compass
echo 07. ABRIR_MONGO_SHELL
echo 08. ABRIR_ORACLE
echo 09. ABRIR_SQL_DEVELOPER
echo 10. EJECUTAR_PRUEBAS
echo 11. GENERAR_EVIDENCIAS
echo 12. MODO_PRESENTACION
echo 13. RESPALDAR_DATOS
echo 14. RESTAURAR_DATOS
echo 15. DIAGNOSTICAR_ERRORES
echo 16. ACTUALIZAR_PROYECTO
echo 17. ABRIR_DOCUMENTACION
echo 00. Salir
set "OP="
set /p "OP=Opcion: "
if "%OP%"=="00" exit /b 0
if "%OP%"=="01" (call "%~dp001_Servicios\INSTALAR_SIGMA_AQUA.cmd" & goto menu)
if "%OP%"=="02" (call "%~dp001_Servicios\INICIAR_SIGMA_AQUA.cmd" & goto menu)
if "%OP%"=="03" (call "%~dp001_Servicios\DETENER_SIGMA_AQUA.cmd" & goto menu)
if "%OP%"=="04" (call "%~dp001_Servicios\VERIFICAR_SIGMA_AQUA.cmd" & goto menu)
if "%OP%"=="05" (call "%~dp001_Servicios\VERIFICAR_PERSISTENCIA.cmd" & goto menu)
if "%OP%"=="06" (call "%~dp002_MongoDB\ABRIR_MONGO_COMPASS.cmd" & goto menu)
if "%OP%"=="07" (call "%~dp002_MongoDB\ABRIR_MONGO_SHELL.cmd" & goto menu)
if "%OP%"=="08" (call "%~dp003_Oracle\ABRIR_ORACLE.cmd" & goto menu)
if "%OP%"=="09" (call "%~dp003_Oracle\ABRIR_SQL_DEVELOPER.cmd" & goto menu)
if "%OP%"=="10" (call "%~dp004_Pruebas\EJECUTAR_PRUEBAS.cmd" & goto menu)
if "%OP%"=="11" (call "%~dp005_Evidencias\GENERAR_EVIDENCIAS.cmd" & goto menu)
if "%OP%"=="12" (call "%~dp005_Evidencias\MODO_PRESENTACION.cmd" & goto menu)
if "%OP%"=="13" (call "%~dp006_Respaldos\RESPALDAR_DATOS.cmd" & goto menu)
if "%OP%"=="14" (call "%~dp006_Respaldos\RESTAURAR_DATOS.cmd" & goto menu)
if "%OP%"=="15" (call "%~dp007_Mantenimiento\DIAGNOSTICAR_ERRORES.cmd" & goto menu)
if "%OP%"=="16" (call "%~dp007_Mantenimiento\ACTUALIZAR_PROYECTO.cmd" & goto menu)
if "%OP%"=="17" (call "%~dp008_Documentacion\ABRIR_DOCUMENTACION.cmd" & goto menu)
goto menu
