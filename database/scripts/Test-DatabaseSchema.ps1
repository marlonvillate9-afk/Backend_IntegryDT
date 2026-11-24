$ErrorActionPreference = 'Stop'

$mysql = if ($env:MYSQL_BIN) { $env:MYSQL_BIN } else { 'C:\Program Files\MySQL\MySQL Server 26.7\bin\mysql.exe' }
$hostName = if ($env:INTEGRY_DB_HOST) { $env:INTEGRY_DB_HOST } else { '127.0.0.1' }
$port = if ($env:INTEGRY_DB_PORT) { $env:INTEGRY_DB_PORT } else { '3306' }
$user = $env:INTEGRY_DB_USER
$password = $env:INTEGRY_DB_PASSWORD

if (-not $user -or -not $password) { throw 'Defina INTEGRY_DB_USER e INTEGRY_DB_PASSWORD.' }

$defaultsFile = Join-Path $env:TEMP ("integry-mysql-test-{0}.cnf" -f [guid]::NewGuid())
@"
[client]
host=$hostName
port=$port
user=$user
password=$password
protocol=tcp
"@ | Set-Content -Path $defaultsFile -Encoding ASCII

try {
  $query = @"
SELECT COUNT(*) AS table_count
FROM information_schema.tables
WHERE table_schema='integry_dt';

SELECT version, description, applied_at
FROM integry_dt.schema_migrations
ORDER BY version;

SELECT c.slug, u.email, cm.status
FROM integry_dt.companies c
JOIN integry_dt.company_memberships cm ON cm.company_id=c.id
JOIN integry_dt.users u ON u.id=cm.user_id;
"@
  $query | & $mysql "--defaults-extra-file=$defaultsFile" --table
  if ($LASTEXITCODE -ne 0) { throw 'Validación del esquema falló.' }
}
finally {
  if (Test-Path $defaultsFile) { Remove-Item $defaultsFile -Force }
}
