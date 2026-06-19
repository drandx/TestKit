<#
.SYNOPSIS
  Install TestKit (Copilot CLI agents + .testkit scaffold) into a project.

.DESCRIPTION
  Two modes, auto-detected:
    - LOCAL : run from a TestKit clone -> copies files from this checkout.
    - REMOTE: run via `irm <raw>/install.ps1 | iex` -> downloads files from GitHub.

.PARAMETER Target
  Project root to install into. Defaults to the current directory.

.PARAMETER Ref
  Git ref (branch/tag) to install from in remote mode. Defaults to 'main'.

.PARAMETER Force
  Overwrite existing TestKit files instead of skipping them.

.EXAMPLE
  ./install.ps1 -Target C:\src\my-project

.EXAMPLE
  irm https://raw.githubusercontent.com/drandx/testkit/main/install.ps1 | iex
#>
[CmdletBinding()]
param(
    [string] $Target = (Get-Location).Path,
    [string] $Ref = 'main',
    [switch] $Force
)

$ErrorActionPreference = 'Stop'
$repo = 'drandx/testkit'
$rawBase = "https://raw.githubusercontent.com/$repo/$Ref"

# Locate the source: this script's own directory in LOCAL mode.
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { $null }
$localManifest = if ($scriptDir) { Join-Path $scriptDir '.testkit/manifest.txt' } else { $null }
$mode = if ($localManifest -and (Test-Path $localManifest)) { 'LOCAL' } else { 'REMOTE' }

Write-Host "TestKit installer ($mode mode) -> $Target" -ForegroundColor Cyan

# Load the manifest (the single source of truth for what gets installed).
$manifestText = if ($mode -eq 'LOCAL') {
    Get-Content $localManifest -Raw
}
else {
    (Invoke-WebRequest -Uri "$rawBase/.testkit/manifest.txt" -UseBasicParsing).Content
}
$files = $manifestText -split "`n" |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and -not $_.StartsWith('#') }

$installed = 0; $skipped = 0
foreach ($rel in $files) {
    $dest = Join-Path $Target $rel
    $destDir = Split-Path $dest -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

    if ((Test-Path $dest) -and -not $Force) {
        Write-Host "  skip   $rel (exists; use -Force to overwrite)" -ForegroundColor DarkYellow
        $skipped++
        continue
    }

    if ($mode -eq 'LOCAL') {
        Copy-Item (Join-Path $scriptDir $rel) $dest -Force
    }
    else {
        Invoke-WebRequest -Uri "$rawBase/$rel" -OutFile $dest -UseBasicParsing
    }
    Write-Host "  add    $rel" -ForegroundColor Green
    $installed++
}

Write-Host ""
Write-Host "Done. $installed installed, $skipped skipped." -ForegroundColor Cyan
Write-Host "Next: open this project in GitHub Copilot CLI and run:" -ForegroundColor Cyan
Write-Host "  /testkit.scenarios <spec-dir>" -ForegroundColor White
