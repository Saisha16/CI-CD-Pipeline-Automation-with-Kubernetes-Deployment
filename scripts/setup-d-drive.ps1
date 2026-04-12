$ErrorActionPreference = 'Stop'

$base = 'D:\DevOpsData'
$dirs = @(
    $base,
    "$base\temp",
    "$base\maven",
    "$base\maven\repository",
    "$base\helm",
    "$base\helm\cache",
    "$base\helm\config",
    "$base\helm\data",
    "$base\kube",
    "$base\minikube",
    'D:\Installers',
    'D:\Apps'
)

foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -Path $d -ItemType Directory | Out-Null
    }
}

# Persist user-level environment variables to keep tool data on D:
[System.Environment]::SetEnvironmentVariable('TEMP', "$base\temp", 'User')
[System.Environment]::SetEnvironmentVariable('TMP', "$base\temp", 'User')
[System.Environment]::SetEnvironmentVariable('MAVEN_USER_HOME', "$base\maven", 'User')
[System.Environment]::SetEnvironmentVariable('HELM_CACHE_HOME', "$base\helm\cache", 'User')
[System.Environment]::SetEnvironmentVariable('HELM_CONFIG_HOME', "$base\helm\config", 'User')
[System.Environment]::SetEnvironmentVariable('HELM_DATA_HOME', "$base\helm\data", 'User')
[System.Environment]::SetEnvironmentVariable('KUBECONFIG', "$base\kube\config", 'User')
[System.Environment]::SetEnvironmentVariable('MINIKUBE_HOME', "$base\minikube", 'User')

# Seed kube config if one already exists in the default location.
$oldKube = Join-Path $env:USERPROFILE '.kube\config'
$newKube = "$base\kube\config"
if ((Test-Path $oldKube) -and (-not (Test-Path $newKube))) {
    Copy-Item $oldKube $newKube -Force
}

Write-Host 'D drive environment configured.'
Write-Host 'Open a NEW PowerShell session for changes to take effect.'
Write-Host "Data root: $base"
