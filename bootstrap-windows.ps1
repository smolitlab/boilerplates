$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Step "[1/2] Git line endings konfigurieren"
git config --global core.autocrlf false
git config --global core.eol lf
git config --global core.safecrlf warn

Write-Step "[2/2] VS Code User Settings mergen"
$sourceSettings = Join-Path $repoRoot "dotfiles/vscode/settings.json"
$targetDir = Join-Path $env:APPDATA "Code/User"
$targetSettings = Join-Path $targetDir "settings.json"

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

if (Test-Path $targetSettings) {
    $current = Get-Content $targetSettings -Raw | ConvertFrom-Json
} else {
    $current = [pscustomobject]@{}
}

$desired = Get-Content $sourceSettings -Raw | ConvertFrom-Json
foreach ($property in $desired.PSObject.Properties) {
    $current | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value -Force
}

$current | ConvertTo-Json -Depth 20 | Set-Content -Path $targetSettings -Encoding utf8

Write-Host "Windows Bootstrap abgeschlossen." -ForegroundColor Green
