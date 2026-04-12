$ErrorActionPreference = 'Stop'

Set-Location "$PSScriptRoot\..\app"

Write-Host 'Building application...'
mvn clean package

Write-Host ''
Write-Host 'Starting application on http://localhost:8080'
java -jar target/cicd-app-1.0.jar
