$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$env:JAVA_HOME='C:\Users\user\Tools\Java\jdk-21'
$env:MAVEN_HOME='C:\Users\user\Tools\Maven\apache-maven-3.9.16'
$env:Path="$env:JAVA_HOME\bin;$env:MAVEN_HOME\bin;$env:Path"
& "$env:MAVEN_HOME\bin\mvn.cmd" -f (Join-Path $repo 'pom.xml') clean package
exit $LASTEXITCODE
