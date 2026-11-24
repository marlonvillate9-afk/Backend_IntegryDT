param(
  [Parameter(Mandatory=$true)][string]$GadgetCode,
  [Parameter(Mandatory=$true)][string]$Version,
  [Parameter(Mandatory=$true)][string]$Entrypoint,
  [Parameter(Mandatory=$true)][string]$PayloadDir
)
$ErrorActionPreference='Stop'
$repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$envFile = Join-Path $repo '.env'
Get-Content $envFile | ForEach-Object {
  if($_ -match '^([^#][^=]*)=(.*)$'){
    [Environment]::SetEnvironmentVariable($matches[1],$matches[2],'Process')
  }
}
if($env:INTEGRY_GADGET_STORAGE){ $storage=$env:INTEGRY_GADGET_STORAGE } else { $storage='C:\ProgramData\IntegryDT\GadgetStorage' }
if($env:INTEGRY_GADGET_PRIVATE_KEY){ $privateKey=$env:INTEGRY_GADGET_PRIVATE_KEY } else { $privateKey='C:\ProgramData\IntegryDT\Keys\gadget-private.pem' }
$keys = Split-Path $privateKey -Parent
$publisher = Join-Path $repo 'tools\GadgetPublisher\IntegryDT.GadgetPublisher.csproj'
$metadataPath = (& dotnet run --project $publisher -- $GadgetCode $Version $Entrypoint $PayloadDir $storage $keys | Select-Object -Last 1).Trim()
if(-not (Test-Path $metadataPath)){ throw "Publisher metadata not found: $metadataPath" }
$m = Get-Content $metadataPath -Raw | ConvertFrom-Json
$mysql = $env:MYSQL_BIN
$defaults = Join-Path $env:TEMP ('integry-publish-'+[guid]::NewGuid()+'.cnf')
@"
[client]
host=$($env:INTEGRY_DB_HOST)
port=$($env:INTEGRY_DB_PORT)
user=$($env:INTEGRY_DB_USER)
password=$($env:INTEGRY_DB_PASSWORD)
protocol=tcp
"@ | Set-Content $defaults -Encoding ASCII
try {
  $sigJson = (@{signatureBase64=$m.signatureBase64} | ConvertTo-Json -Compress).Replace("'","''")
  $manifest = ([string]$m.manifestJson).Replace("'","''")
  $storageKey = ([string]$m.storageKey).Replace("'","''")
  $entry = ([string]$m.entrypoint).Replace("'","''")
  $sql = @"
USE integry_dt;
UPDATE gadget_versions gv JOIN gadgets g ON g.id=gv.gadget_id
SET gv.storage_key='$storageKey', gv.package_size=$($m.packageSize), gv.sha256='$($m.sha256)',
    gv.signature_metadata=CAST('$sigJson' AS JSON), gv.entrypoint='$entry', gv.manifest_json=CAST('$manifest' AS JSON),
    gv.status='published', gv.published_at=COALESCE(gv.published_at,CURRENT_TIMESTAMP(6)), gv.revoked_at=NULL
WHERE g.code='$GadgetCode' AND gv.version='$Version' AND gv.platform='windows' AND gv.architecture='x64';
"@
  $sql | & $mysql "--defaults-extra-file=$defaults"
  if($LASTEXITCODE -ne 0){ throw 'Could not update gadget metadata in MySQL' }
  Write-Host "Published $GadgetCode $Version"
  Write-Host "Package: $(Join-Path $storageKey 'package.zip')"
  Write-Host "SHA256: $($m.sha256)"
} finally {
  Remove-Item $defaults -Force -ErrorAction SilentlyContinue
}
