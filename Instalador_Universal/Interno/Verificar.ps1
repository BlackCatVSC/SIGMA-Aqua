param([switch]$Persistencia)
$ErrorActionPreference='Stop'
$state=Join-Path $env:LOCALAPPDATA 'SIGMA-Aqua-v2'
$report=Join-Path ([Environment]::GetFolderPath('Desktop')) ('SIGMA-Aqua-Verificacion-'+(Get-Date -Format yyyyMMdd-HHmmss)+'.txt')
$script:ok=0; $script:bad=0; $script:pending=0
function Check($name,$pass){if($pass){$script:ok++; Write-Host "[OK] $name" -ForegroundColor Green}else{$script:bad++; Write-Host "[ERROR] $name" -ForegroundColor Red}}
function Pending($name){$script:pending++; Write-Host "[PENDIENTE] $name" -ForegroundColor Yellow}
function RunDocker { $r=& docker @args; if($LASTEXITCODE -ne 0){throw 'Docker command failed'}; $r }
Start-Transcript -Path $report | Out-Null
try {
 Write-Host '=== SIGMA-AQUA: VERIFICACION V4 SIN MODIFICAR DATOS ==='
 $engine=RunDocker info --format '{{.OSType}}'; Check 'Docker Linux' ($engine -eq 'linux')
 foreach($n in 'mongo','oracle'){ $status=RunDocker inspect --format '{{.State.Status}}' "sigma_aqua_v2-$n-1"; Check "Contenedor $n activo" ($status -eq 'running') }
 $js=@'
const c=db.getSiblingDB('sigma_aqua').reportes_jaula;
const ids=['REP-J12-20261118','REP-J01-20261118','REP-J02-20261118','REP-J03-20261118','REP-J05-20261118','REP-J07-20261118','REP-J08-20261118'];
const j=c.findOne({codigo_reporte:ids[0]}); const k=c.findOne({codigo_reporte:ids[2]});
print(JSON.stringify({ping:db.adminCommand({ping:1}).ok===1,collection:db.getSiblingDB('sigma_aqua').getCollectionNames().includes('reportes_jaula'),count:c.countDocuments({})===7,ids:c.countDocuments({codigo_reporte:{$in:ids}})===7,unique:c.getIndexes().some(i=>i.unique&&i.key.codigo_reporte===1),updated:!!j&&j.estado==='REVISADO'&&j.alerta_activa===false&&!('nota_temporal' in j),fish:!!k&&k.peces_vivos===8665&&k.ajuste_demo_aplicado===true,tag:!!k&&k.etiquetas.includes('inspeccion_sernapesca'),deleted:c.countDocuments({codigo_reporte:{$in:['TEST-J99-20261101','TEST-J98-20261101']}})===0}));
'@
 $m=RunDocker exec sigma_aqua_v2-mongo-1 mongosh --quiet --eval $js | Select-Object -Last 1 | ConvertFrom-Json
 foreach($prop in $m.PSObject.Properties){Check "MongoDB: $($prop.Name)" ($prop.Value -eq $true)}
 $sql=@'
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 200 TRIMSPOOL ON
ALTER SESSION SET CONTAINER=FREEPDB1;
SELECT 'TABLES='||COUNT(*) FROM DBA_TABLES WHERE OWNER='SIGMA_AQUA_TEST';
SELECT 'VALID='||COUNT(*) FROM DBA_OBJECTS WHERE OWNER='SIGMA_AQUA_TEST' AND OBJECT_TYPE IN ('PACKAGE','PACKAGE BODY','VIEW','TRIGGER') AND STATUS='VALID';
SELECT 'ERRORS='||COUNT(*) FROM DBA_ERRORS WHERE OWNER='SIGMA_AQUA_TEST';
SELECT 'CONSTRAINTS='||COUNT(*) FROM DBA_CONSTRAINTS WHERE OWNER='SIGMA_AQUA_TEST' AND STATUS='ENABLED' AND VALIDATED='VALIDATED';
SELECT 'TRIGGERS='||COUNT(*) FROM DBA_TRIGGERS WHERE OWNER='SIGMA_AQUA_TEST' AND STATUS='ENABLED';
SELECT 'CENTERS='||COUNT(*) FROM SIGMA_AQUA_TEST.CENTRO_CULTIVO;
SELECT 'SAMPLES='||COUNT(*) FROM SIGMA_AQUA_TEST.MUESTREO;
SELECT 'TANKS='||COUNT(*) FROM SIGMA_AQUA_TEST.TANQUE;
SELECT 'STAGING='||COUNT(*) FROM SIGMA_AQUA_TEST.MEDICIONES_STAGING;
SELECT 'HISTORY='||COUNT(*) FROM SIGMA_AQUA_TEST.HISTORIAL_MEDICIONES;
SELECT 'ALERTS='||COUNT(*) FROM SIGMA_AQUA_TEST.ALERTA;
SELECT 'ACTIONS='||COUNT(*) FROM SIGMA_AQUA_TEST.ACCION_CORRECTIVA;
EXIT SUCCESS
'@
 $r=$sql | & docker exec -i sigma_aqua_v2-oracle-1 sqlplus -L -s / as sysdba
 if($LASTEXITCODE -ne 0){throw 'Oracle verification failed'}
 $r | Out-Host
 $expected=@{TABLES=40;VALID=7;ERRORS=0;CONSTRAINTS=235;TRIGGERS=2;CENTERS=4;SAMPLES=4;TANKS=3;STAGING=5;HISTORY=0;ALERTS=0;ACTIONS=0}
 foreach($key in ($expected.Keys | Sort-Object)){Check "Oracle: $key = $($expected[$key])" ([bool]($r -match "^\s*$key=$($expected[$key])\s*$"))}
 try {
 $found=$false
 foreach($root in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')) {
  foreach($entry in @(Get-ChildItem -LiteralPath $root -ErrorAction SilentlyContinue)) {
   try { $name=$entry.GetValue('DisplayName'); if($name -is [string] -and $name -like '*MongoDB Compass*'){$found=$true} } catch {}
  }
 }
 foreach($path in @("$env:LOCALAPPDATA\MongoDBCompass\MongoDBCompass.exe","$env:ProgramFiles\MongoDB Compass\MongoDBCompass.exe","$env:LOCALAPPDATA\Programs\MongoDB Compass\MongoDBCompass.exe")){if(Test-Path -LiteralPath $path){$found=$true}}
 if($found){Check 'MongoDB Compass instalado' $true}else{Pending 'Compass no detectado; verificar menu Inicio'}
 } catch {Pending ('Compass: '+$_.Exception.Message)}
 try {
 $log=Get-ChildItem -LiteralPath $state -Filter 'log-*.txt' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Where-Object {Select-String -LiteralPath $_.FullName -SimpleMatch 'Installing 01_Estructura_Tablas/DataModeler.sql' -Quiet} | Select-Object -First 1
 if($log){
  $t=[string](Get-Content -LiteralPath $log.FullName -Raw)
  Write-Host "Registro original: $($log.Name)"
  $monitor=[regex]::Match($t,'(?s)TEST PKG_MONITOREO_AGUA.*?FIN DEL TEST').Value
  $trigger=[regex]::Match($t,'(?s)\[OK\] Tres mediciones registradas.*?6/6 PRUEBAS SUPERADAS').Value
  Check 'Oracle: 10 pruebas originales de monitoreo registradas' ([regex]::Matches($monitor,'(?m)^\s*\[OK\]').Count -eq 10)
  Check 'Oracle: 6 pruebas originales de triggers registradas' ([regex]::Matches($trigger,'(?m)^\s*\[OK\]').Count -eq 6)
  Check 'Finalizacion del instalador registrada' ($t.Contains('Database scripts and tests completed.'))
  if($t.Contains('MONGODB_ORIGINAL_TESTS=4/4')){Check 'MongoDB: 4 pruebas originales registradas' $true}else{Pending 'MongoDB: registro historico no confirmado'}
 }else{Pending 'Registro original de instalacion no localizado'}
 } catch {Pending ('Registro original: '+$_.Exception.Message)}
 try {
 $jsFinal=@'
const c=db.getSiblingDB('sigma_aqua').reportes_jaula;
const ids=['REP-J12-20261118','REP-J01-20261118','REP-J02-20261118','REP-J03-20261118','REP-J05-20261118','REP-J07-20261118','REP-J08-20261118'];
print(JSON.stringify({reportes:c.countDocuments({codigo_reporte:{$in:ids}})===7&&c.countDocuments({})===7&&c.getIndexes().some(i=>i.unique&&i.key.codigo_reporte===1),oxigeno:c.countDocuments({codigo_reporte:ids[2],lecturas:{$elemMatch:{parametro:'oxigeno',valor:{$lt:6}}}})===1,etiquetas:c.countDocuments({codigo_reporte:ids[2],etiquetas:{$all:['oxigeno_bajo','revision_urgente']}})===1,eliminacion:c.countDocuments({codigo_reporte:{$in:['TEST-J99-20261101','TEST-J98-20261101']}})===0}));
'@
 $final=RunDocker exec sigma_aqua_v2-mongo-1 mongosh --quiet --eval $jsFinal | Select-Object -Last 1 | ConvertFrom-Json
 foreach($prop in $final.PSObject.Properties){Check "MongoDB: comprobacion final $($prop.Name)" ($prop.Value -eq $true)}
 } catch {Check 'MongoDB: comprobaciones finales' $false; Write-Host $_.Exception.Message}
 if($Persistencia -and $script:bad -eq 0){
  Write-Host 'Reinicio autorizado: se interrumpiran temporalmente ambos motores.'
  $beforeMongo=RunDocker exec sigma_aqua_v2-mongo-1 mongosh --quiet --eval "print(JSON.stringify(db.getSiblingDB('sigma_aqua').reportes_jaula.find().sort({codigo_reporte:1}).toArray()))"
  RunDocker restart -t 180 sigma_aqua_v2-mongo-1 sigma_aqua_v2-oracle-1 | Out-Host
  $until=(Get-Date).AddMinutes(10)
  do { $health=RunDocker inspect --format '{{.State.Health.Status}}' sigma_aqua_v2-oracle-1; if($health -eq 'healthy'){break}; Start-Sleep 5 } while((Get-Date) -lt $until)
  if($health -ne 'healthy'){throw 'Oracle no disponible tras reinicio'}
  $afterMongo=RunDocker exec sigma_aqua_v2-mongo-1 mongosh --quiet --eval "print(JSON.stringify(db.getSiblingDB('sigma_aqua').reportes_jaula.find().sort({codigo_reporte:1}).toArray()))"
  Check 'Persistencia MongoDB: documentos identicos' (($beforeMongo -join "`n") -ceq ($afterMongo -join "`n"))
  $afterSql=$sql | & docker exec -i sigma_aqua_v2-oracle-1 sqlplus -L -s / as sysdba
  $sqlExit=$LASTEXITCODE
  Check 'Persistencia Oracle: conteos y objetos conservados' ($sqlExit -eq 0 -and (($r -join "`n") -ceq ($afterSql -join "`n")))
 }else{Pending 'Persistencia: usar VERIFICAR_PERSISTENCIA.cmd para reiniciar servicios'}

} catch {Check 'Ejecucion completa del verificador' $false; Write-Host $_.Exception.Message}
finally {Write-Host "RESULTADO: $script:ok OK | $script:bad errores | $script:pending pendientes"; Write-Host "Informe: $report"; Stop-Transcript | Out-Null}

if($script:bad -gt 0){exit 1}else{exit 0}
