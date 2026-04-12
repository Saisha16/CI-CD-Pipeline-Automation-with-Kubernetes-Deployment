param(
    [string]$ImageRepository = 'ghcr.io/your-org/cicd-app',
    [string]$ImageTag = 'latest',
    [string]$KubeNamespace = 'devops',
    [string]$KubeContext = ''
)

$ErrorActionPreference = 'Stop'

function Resolve-KubectlPath {
    $cmd = Get-Command kubectl -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $fallback = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter kubectl.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    if ($fallback) {
        return $fallback
    }

    throw 'kubectl was not found in PATH or winget package directory.'
}

$root = Resolve-Path "$PSScriptRoot\.."
$k8s = Join-Path $root 'k8s'
$rendered = Join-Path $root '.rendered-k8s'
$kubectl = Resolve-KubectlPath

function Invoke-Kubectl {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$CommandArgs
    )

    $allArgs = @()
    $allArgs += $script:kubectlContextArgs
    $allArgs += $CommandArgs

    & $script:kubectl @allArgs
}

$required = @(
    'namespace.yaml',
    'blue-deployment.yaml',
    'service.yaml',
    'green-deployment.yaml',
    'hpa.yaml',
    'elasticsearch.yaml',
    'logstash.yaml',
    'kibana.yaml'
)

foreach ($f in $required) {
    $p = Join-Path $k8s $f
    if (-not (Test-Path $p)) {
        throw "Missing manifest: $p"
    }
    if ((Get-Item $p).Length -eq 0) {
        throw "Manifest is empty: $p"
    }
}

$context = $KubeContext
if (-not $context) {
    $context = & $kubectl config current-context 2>$null
    if (-not $context) {
        throw 'kubectl has no current context. Start Minikube or configure your cluster first.'
    }
}

$kubectlContextArgs = @()
if ($context) {
    $kubectlContextArgs = @('--context', $context)
}

$activeColor = ''
try {
    $activeColor = (Invoke-Kubectl -n $KubeNamespace get svc app-service -o 'jsonpath={.spec.selector.version}' 2>$null).Trim()
} catch {
    $activeColor = ''
}

if (-not $activeColor) {
    $activeColor = 'blue'
}

$targetColor = if ($activeColor -eq 'blue') { 'green' } else { 'blue' }

if (Test-Path $rendered) {
    Remove-Item $rendered -Recurse -Force
}
New-Item -ItemType Directory -Path $rendered | Out-Null

foreach ($name in @('namespace.yaml', 'blue-deployment.yaml', 'service.yaml', 'green-deployment.yaml', 'hpa.yaml', 'elasticsearch.yaml', 'logstash.yaml', 'kibana.yaml')) {
    $sourcePath = Join-Path $k8s $name
    if (-not (Test-Path $sourcePath)) {
        $sourcePath = Join-Path $root "logging\$name"
    }

    $content = Get-Content $sourcePath -Raw
    $content = $content.Replace('__KUBE_NAMESPACE__', $KubeNamespace)
    $content = $content.Replace('__IMAGE_REPOSITORY__', $ImageRepository)
    $content = $content.Replace('__IMAGE_TAG__', $ImageTag)
    $content = $content.Replace('__TARGET_COLOR__', $targetColor)
    Set-Content -Path (Join-Path $rendered $name) -Value $content -NoNewline
}

try {
    Invoke-Kubectl apply -f (Join-Path $rendered 'namespace.yaml')
    Invoke-Kubectl apply -f (Join-Path $rendered 'elasticsearch.yaml')
    Invoke-Kubectl apply -f (Join-Path $rendered 'logstash.yaml')
    Invoke-Kubectl apply -f (Join-Path $rendered 'kibana.yaml')
    Invoke-Kubectl apply -f (Join-Path $rendered 'service.yaml')
    Invoke-Kubectl apply -f (Join-Path $rendered 'hpa.yaml')

    $targetDeployment = Join-Path $rendered "$targetColor-deployment.yaml"

    Invoke-Kubectl apply -f $targetDeployment
    Invoke-Kubectl -n $KubeNamespace rollout status "deployment/app-$targetColor"

    Invoke-Kubectl -n $KubeNamespace patch service app-service '-p' ('{"spec":{"selector":{"version":"' + $targetColor + '"}}}')
    Invoke-Kubectl -n $KubeNamespace patch hpa app-hpa '-p' ('{"spec":{"scaleTargetRef":{"name":"app-' + $targetColor + '"}}}')

    Write-Host ''
    Write-Host 'Deploy complete. Current resources:'
    Invoke-Kubectl get all -n $KubeNamespace
} catch {
    if ($activeColor -and $targetColor -and $activeColor -ne $targetColor) {
        try {
            Invoke-Kubectl -n $KubeNamespace patch service app-service '-p' ('{"spec":{"selector":{"version":"' + $activeColor + '"}}}')
            Invoke-Kubectl -n $KubeNamespace patch hpa app-hpa '-p' ('{"spec":{"scaleTargetRef":{"name":"app-' + $activeColor + '"}}}')
        } catch {
        }
    }

    throw
}
