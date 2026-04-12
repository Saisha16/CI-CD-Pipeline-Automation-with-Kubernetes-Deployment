$ErrorActionPreference = 'SilentlyContinue'

function Resolve-ToolPath {
    param([string]$Name)

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $knownPaths = @{
        docker = 'C:\Program Files\Docker\Docker\resources\bin\docker.exe'
    }
    if ($knownPaths.ContainsKey($Name) -and (Test-Path $knownPaths[$Name])) {
        return $knownPaths[$Name]
    }

    $wingetRoots = @(
        "$env:LOCALAPPDATA\Microsoft\WinGet\Packages",
        'C:\Program Files\Kubernetes\Minikube'
    )

    foreach ($root in $wingetRoots) {
        if (Test-Path $root) {
            $found = Get-ChildItem $root -Recurse -Filter "$Name.exe" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
            if ($found) {
                return $found
            }
        }
    }

    return ''
}

$tools = @('java','mvn','docker','kubectl','helm','minikube')
$results = foreach ($tool in $tools) {
    $path = Resolve-ToolPath -Name $tool
    [PSCustomObject]@{
        Tool = $tool
        Installed = [bool]$path
        Path = $path
    }
}

$results | Format-Table -AutoSize

Write-Host ''
Write-Host 'Kubernetes context:'
$kubectlPath = Resolve-ToolPath -Name 'kubectl'
$context = ''
if ($kubectlPath) {
    $context = & $kubectlPath config current-context 2>$null
}
if ($context) {
    Write-Host "Current context: $context"
} else {
    Write-Host 'No current kubectl context is set.'
}

Write-Host ''
$freeGB = [math]::Round((Get-PSDrive -Name C).Free / 1GB, 2)
Write-Host "C: free space (GB): $freeGB"
if ($freeGB -lt 10) {
    Write-Host 'Recommendation: Keep at least 10 GB free before installing Docker Desktop.'
}
