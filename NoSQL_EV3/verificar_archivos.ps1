$ErrorActionPreference = "Stop"
$archivos = @(
  "01_creacion.js","02_datos_iniciales.js","03_crud.js",
  "04_pruebas.js","05_consultas_avanzadas.js",
  "06_validaciones_negocio.js","07_pruebas_ampliadas.js",
  "README.md","MODELO_NoSQL.svg","GUIA_EV3.md"
)
Write-Host "Verificando archivos NoSQL_EV3..."
$faltantes = @($archivos | Where-Object { -not (Test-Path (Join-Path $PSScriptRoot $_) -PathType Leaf) })
if ($faltantes.Count -gt 0) {
  Write-Host "FALTAN:" ($faltantes -join ", ") -ForegroundColor Red
  exit 1
}
Write-Host "OK: $($archivos.Count) archivos obligatorios presentes." -ForegroundColor Green
$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) {
  foreach ($a in $archivos | Where-Object { $_ -like "*.js" }) {
    & node --check (Join-Path $PSScriptRoot $a)
    if ($LASTEXITCODE -ne 0) { throw "Error de sintaxis: $a" }
  }
  Write-Host "OK: sintaxis JavaScript revisada con Node." -ForegroundColor Green
} else {
  Write-Host "Node no instalado: se omite revisión sintáctica opcional."
}
$mongo = Get-Command mongosh -ErrorAction SilentlyContinue
if ($mongo) {
  Write-Host "mongosh encontrado. Para comprobar MongoDB: mongosh --eval 'db.runCommand({ping:1})'"
} else {
  Write-Host "mongosh NO encontrado: instalar MongoDB Shell antes de ejecutar los scripts." -ForegroundColor Yellow
}
