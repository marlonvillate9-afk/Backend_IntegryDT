param(
  [switch]$IncludeSeed
)

$ErrorActionPreference = 'Stop'

$mysql = if ($env:MYSQL_BIN) { $env:MYSQL_BIN } else { 'C:\Program Files\MySQL\MySQL Server 26.7\bin\mysql.exe' }
$hostName = if ($env:INTEGRY_DB_HOST) { $env:INTEGRY_DB_HOST } else { '127.0.0.1' }
$port = if ($env:INTEGRY_DB_PORT) { $env:INTEGRY_DB_PORT } else { '3306' }
$user = $env:INTEGRY_DB_USER
$password = $env:INTEGRY_DB_PASSWORD

if (-not (Test-Path $mysql)) { throw "mysql.exe no encontrado: $mysql" }
if (-not $user) { throw 'Defina INTEGRY_DB_USER.' }
if (-not $password) { throw 'Defina INTEGRY_DB_PASSWORD.' }

$defaultsFile = Join-Path $env:TEMP ("integry-mysql-{0}.cnf" -f [guid]::NewGuid())
@"
[client]
host=$hostName
port=$port
user=$user
password=$password
protocol=tcp
"@ | Set-Content -Path $defaultsFile -Encoding ASCII

try {
  $migrationDir = Join-Path $PSScriptRoot '..\migrations'
  $files = Get-ChildItem $migrationDir -Filter '*.sql' | Sort-Object Name

  $bootstrap = $files | Where-Object { $_.BaseName -match '^000_' } | Select-Object -First 1
  if ($bootstrap) {
    Write-Host "Aplicando bootstrap $($bootstrap.Name)..."
    Get-Content -Raw $bootstrap.FullName | & $mysql "--defaults-extra-file=$defaultsFile" --default-character-set=utf8mb4
    if ($LASTEXITCODE -ne 0) { throw "Fallo aplicando $($bootstrap.Name)" }
  }

  foreach ($file in $files | Where-Object { $_ -ne $bootstrap }) {
    if ($file.BaseName -notmatch '^(\d+)_') { throw "Migración sin prefijo de versión: $($file.Name)" }
    $version = $Matches[1]
    $applied = (& $mysql "--defaults-extra-file=$defaultsFile" -N -B -e "SELECT COUNT(*) FROM integry_dt.schema_migrations WHERE version='$version';").Trim()
    if ($LASTEXITCODE -ne 0) { throw "No se pudo consultar schema_migrations para $version" }
    if ($applied -eq '1') {
      Write-Host "Omitiendo $($file.Name): ya aplicada."
      continue
    }

    Write-Host "Aplicando $($file.Name)..."
    Get-Content -Raw $file.FullName | & $mysql "--defaults-extra-file=$defaultsFile" --default-character-set=utf8mb4
    if ($LASTEXITCODE -ne 0) { throw "Fallo aplicando $($file.Name)" }
  }

  if ($IncludeSeed) {
    $seed = Join-Path $PSScriptRoot '..\seeds\001_development_seed.sql'
    Write-Host 'Aplicando seed de desarrollo...'
    Get-Content -Raw $seed | & $mysql "--defaults-extra-file=$defaultsFile" --default-character-set=utf8mb4
    if ($LASTEXITCODE -ne 0) { throw 'Fallo aplicando seed de desarrollo.' }
  }

  Write-Host 'Migraciones finalizadas correctamente.'
}
finally {
  if (Test-Path $defaultsFile) { Remove-Item $defaultsFile -Force }
}
