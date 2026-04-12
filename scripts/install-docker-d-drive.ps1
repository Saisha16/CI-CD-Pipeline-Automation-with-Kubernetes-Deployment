$ErrorActionPreference = 'Stop'

$installerDir = 'D:\Installers'
$installer = Join-Path $installerDir 'Docker Desktop_4.67.0_Machine_X64_exe_en-US.exe'

if (-not (Test-Path $installerDir)) {
    New-Item -Path $installerDir -ItemType Directory | Out-Null
}

if (-not (Test-Path $installer)) {
    winget download --id Docker.DockerDesktop -e --accept-source-agreements --download-directory $installerDir
}

if (-not (Test-Path $installer)) {
    throw 'Docker installer was not found after download.'
}

Write-Host 'Launching Docker installer with admin prompt...'
Start-Process -FilePath $installer -ArgumentList 'install','--accept-license','--installation-dir=D:\Apps\DockerDesktop' -Verb RunAs
Write-Host 'If prompted by UAC, click Yes to continue installation.'
Write-Host 'After install, start Docker Desktop once and set Disk image location to D drive in Docker settings.'
