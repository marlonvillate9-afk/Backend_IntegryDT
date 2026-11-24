$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$envFile=Join-Path $repo '.env'
if(Test-Path $envFile){
  Get-Content $envFile | ForEach-Object {
    if($_ -match '^([^#][^=]*)=(.*)$'){
      [Environment]::SetEnvironmentVariable($matches[1],$matches[2],'Process')
    }
  }
}
$env:JAVA_HOME='C:\Users\user\Tools\Java\jdk-21'
$env:MAVEN_HOME='C:\Users\user\Tools\Maven\apache-maven-3.9.16'
$env:Path="$env:JAVA_HOME\bin;$env:MAVEN_HOME\bin;$env:Path"
$jar=Join-Path $repo 'target\backend-java-0.6.0-SNAPSHOT.jar'
if(-not (Test-Path $jar)){
  & (Join-Path $PSScriptRoot 'Build.ps1')
  if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}
}
& "$env:JAVA_HOME\bin\java.exe" -jar $jar
exit $LASTEXITCODE
