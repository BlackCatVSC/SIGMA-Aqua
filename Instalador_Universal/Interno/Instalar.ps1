param([ValidateSet('Install','Start','Stop')][string]$Mode='Install')
$ErrorActionPreference='Continue'
Set-Location $PSScriptRoot
$env:COMPOSE_PROJECT_NAME='sigma_aqua_v2'
$state=Join-Path $env:LOCALAPPDATA 'SIGMA-Aqua-v2'
New-Item -ItemType Directory -Force $state | Out-Null
Start-Transcript -Path (Join-Path $state (('log-'+$Mode+'-')+(Get-Date -Format yyyyMMdd-HHmmss)+'.txt')) | Out-Null
function D { & docker @args; if($LASTEXITCODE -ne 0){throw "Docker failed: $($args[0])"} }
function C { D compose --env-file "$state\credentials.env" @args }
function Wait-For($name,[scriptblock]$probe,[int]$seconds){
 $until=(Get-Date).AddSeconds($seconds)
 do { if (& $probe){return}; Start-Sleep 5 } while((Get-Date) -lt $until)
 throw "Timeout: $name"
}
function Sql([string]$login,[string]$body){
 $inputSql="WHENEVER OSERROR EXIT FAILURE`nWHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK`nSET DEFINE OFF`nSET SERVEROUTPUT ON`n$body`nEXIT SUCCESS`n"
 $output=$inputSql | & docker compose --env-file "$state\credentials.env" exec -T oracle sqlplus -L -s $login
 $code=$LASTEXITCODE
 $output | Out-Host
 if($code -ne 0 -or ($output -match 'SP2-\d+|ORA-\d+:.*(invalid identifier|table or view does not exist)')){throw 'SQLPlus failed; inspect log'}
 return ($output -join "`n")
}
try {
 if(-not (Get-Command docker -ErrorAction SilentlyContinue)){
  if($Mode -ne 'Install'){throw 'Install Docker first'}
  if(-not (Get-Command winget -ErrorAction SilentlyContinue)){throw 'Install Docker Desktop from docker.com first (winget unavailable).'}
  & winget install --id Docker.DockerDesktop -e --accept-package-agreements --accept-source-agreements
  if($LASTEXITCODE -ne 0){throw 'Docker installation failed'}
  $env:Path += ';C:\Program Files\Docker\Docker\resources\bin'
 }
 $desktop=Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'
 & docker info --format '{{.OSType}}' 2>$null | Out-Null
 if($LASTEXITCODE -ne 0 -and (Test-Path $desktop)){Start-Process $desktop}
 Wait-For 'Docker Linux engine (accept Desktop terms or reboot if needed)' { $x=& docker info --format '{{.OSType}}' 2>$null; $LASTEXITCODE -eq 0 -and $x -eq 'linux' } 300
 $cred=Join-Path $state 'credentials.env'
 if(!(Test-Path $cred)){
  if($Mode -ne 'Install'){throw 'Run installer first'}
  $pw='Sa9_'+[guid]::NewGuid().ToString('N').Substring(0,20)
  $app='Sa9_'+[guid]::NewGuid().ToString('N').Substring(0,20)
  @("ORACLE_PWD=$pw","APP_PWD=$app") | Set-Content $cred -Encoding ASCII
 }
 $vars=ConvertFrom-StringData (Get-Content $cred -Raw)
 if($Mode -eq 'Stop'){C stop -t 180; C ps -a; Write-Host 'Services stopped; volumes retained'; return}
 C up -d --no-recreate
 Wait-For 'MongoDB' { & docker compose --env-file $cred exec -T mongo mongosh --quiet --eval 'quit(db.adminCommand({ping:1}).ok===1?0:1)' 2>$null | Out-Null; $LASTEXITCODE -eq 0 } 300
 Wait-For 'Oracle FREEPDB1' { $r="WHENEVER SQLERROR EXIT FAILURE`nSELECT 1 FROM dual;`nEXIT`n" | & docker compose --env-file $cred exec -T oracle sqlplus -L -s "system/$($vars.ORACLE_PWD)@//localhost:1521/FREEPDB1" 2>$null; $LASTEXITCODE -eq 0 -and ($r -match '^\s*1\s*$') } 1800
 if($Mode -eq 'Start'){Write-Host 'Services ready'; return}
 $sys="system/$($vars.ORACLE_PWD)@//localhost:1521/FREEPDB1"
 $app="SIGMA_AQUA_TEST/$($vars.APP_PWD)@//localhost:1521/FREEPDB1"
 $hour=[int](Sql $sys "SET HEADING OFF FEEDBACK OFF`nSELECT TO_CHAR(SYSTIMESTAMP AT TIME ZONE 'America/Santiago','HH24') FROM dual;").Trim()
 if($hour -in 4,5){throw 'Maintenance 04:00-05:59 Chile. Retry installation after 06:00.'}
 $exists=Sql $sys "SET HEADING OFF FEEDBACK OFF`nSELECT COUNT(*) FROM dba_users WHERE username='SIGMA_AQUA_TEST';"
 if($exists -match '(?m)^\s*0\s*$'){
  Sql $sys "CREATE USER SIGMA_AQUA_TEST IDENTIFIED BY `"$($vars.APP_PWD)`" DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;`nGRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE, CREATE PROCEDURE, CREATE TRIGGER, CREATE TYPE TO SIGMA_AQUA_TEST;" | Out-Null
 }
 $tables=Sql $app "SET HEADING OFF FEEDBACK OFF`nSELECT COUNT(*) FROM user_tables;"
 $root=Join-Path (Split-Path $PSScriptRoot -Parent) 'SIGMA-Aqua'
 if($tables -match '(?m)^\s*0\s*$'){
  foreach($f in @('01_Estructura_Tablas/DataModeler.sql','03_Poblado_y_Consultas/scripts_plsql_sigma_aqua.sql','01_Estructura_Tablas/DataModeler_monitoreo.sql','02_Triggers_y_Funciones/PKG_SIGMA_AQUA.sql','02_Triggers_y_Funciones/PKG_MONITOREO_AGUA.sql','02_Triggers_y_Funciones/triggers_monitoreo.sql')){
   Write-Host "Installing $f"
   Sql $app (Get-Content (Join-Path "$root\SQL" $f) -Raw -Encoding UTF8) | Out-Null
  }
 } elseif($tables -notmatch '(?m)^\s*40\s*$'){throw 'Partial Oracle schema detected. Data preserved; inspect log before repair.'}
 if($tables -match '(?m)^\s*40\s*$'){Write-Host 'Existing schema preserved. Use verifier; no seed or tests rerun.'; & (Join-Path $PSScriptRoot 'Verificar.ps1'); return}
 Sql $app "DECLARE n NUMBER; BEGIN SELECT COUNT(*) INTO n FROM user_objects WHERE status='INVALID'; IF n>0 THEN RAISE_APPLICATION_ERROR(-20099,'Invalid objects'); END IF; END;`n/" | Out-Null
 foreach($f in @('test.sql','test_monitoreo.sql','../02_Triggers_y_Funciones/Test_Trigger.sql')){
  $r=Sql $app (Get-Content (Join-Path "$root\SQL\03_Poblado_y_Consultas" $f) -Raw -Encoding UTF8)
  if($f -eq 'test_monitoreo.sql' -and ([regex]::Matches($r,'\[OK\]').Count -ne 10)){throw 'Monitoring tests incomplete'}
  if($f -like '*Test_Trigger*' -and ([regex]::Matches($r,'\[OK\]').Count -ne 6)){throw 'Trigger tests incomplete'}
 }
 foreach($f in @('Insert.js','InsertMany.js','Read.js','Pruebas.js','Update.js','Delete.js')){
  $src=Join-Path "$root\NoSQL" $f
  C cp $src "mongo:/tmp/$f"
  $mongoOutput = @(C exec -T mongo mongosh --quiet --file "/tmp/$f")
  $mongoOutput | Out-Host
  if($f -eq 'Pruebas.js'){
   if(@($mongoOutput -match '^\s*\[OK\]').Count -ne 4){throw 'MongoDB tests incomplete'}
   Write-Host 'MONGODB_ORIGINAL_TESTS=4/4'
  }
 }
 if(Get-Command winget -ErrorAction SilentlyContinue){
  & winget install --id MongoDB.Compass.Full -e --accept-package-agreements --accept-source-agreements
  if($LASTEXITCODE -ne 0){Write-Warning 'Compass installation not confirmed. Install from mongodb.com/try/download/compass if needed.'}
 }else{Write-Warning 'Compass: install manually from mongodb.com/try/download/compass'}
 Write-Host 'Database scripts and tests completed.' -ForegroundColor Green
 Write-Host 'Compass URI: mongodb://127.0.0.1:27018/sigma_aqua'
 Write-Host 'Oracle: localhost:1522/FREEPDB1, SIGMA_AQUA_TEST'
 Write-Host "Credentials: $cred (private; do not share)"
} catch {Write-Host $_ -ForegroundColor Red; exit 1} finally {Stop-Transcript | Out-Null}
& (Join-Path $PSScriptRoot 'Verificar.ps1')
exit $LASTEXITCODE
