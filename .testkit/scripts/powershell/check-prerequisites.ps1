<#
.SYNOPSIS
  Resolve the TestKit feature directory and assert that the artifacts a given
  stage depends on actually exist. Each agent calls this FIRST, instead of
  trusting itself to locate inputs.

.DESCRIPTION
  Mirrors speckit's check-prerequisites pattern. Emits a single JSON object so an
  agent can parse FEATURE_DIR and the resolved artifact paths deterministically.

.PARAMETER FeatureDir
  The feature/spec directory (e.g. specs/002-executive-deletion-exemption).
  If omitted, falls back to .testkit/feature.json { "feature_directory": ... }.

.PARAMETER Require
  Which artifacts must exist before the calling stage may proceed. One or more of:
  Scenarios, Memory, Tools, Scripts, Results.

.OUTPUTS
  JSON: { ok, featureDir, paths{...}, missing[...] }
  Exit code 0 when all required artifacts exist, 1 otherwise.
#>
[CmdletBinding()]
param(
    [string] $FeatureDir,
    [ValidateSet('Scenarios', 'Memory', 'Tools', 'Scripts', 'Results')]
    [string[]] $Require = @()
)

$ErrorActionPreference = 'Stop'

if (-not $FeatureDir) {
    if (Test-Path '.testkit/feature.json') {
        $FeatureDir = (Get-Content '.testkit/feature.json' -Raw | ConvertFrom-Json).feature_directory
    }
}
if (-not $FeatureDir -or -not (Test-Path $FeatureDir)) {
    @{ ok = $false; featureDir = $FeatureDir; missing = @('feature-directory') } |
        ConvertTo-Json -Compress
    exit 1
}

$paths = [ordered]@{
    Scenarios = Join-Path $FeatureDir 'test_cases.csv'
    Memory    = Join-Path $FeatureDir 'test-memory.md'
    Tools     = Join-Path $FeatureDir 'tools-report.md'
    Scripts   = Join-Path $FeatureDir 'scripts'
    Results   = Join-Path $FeatureDir 'test-results.md'
}

$missing = @()
foreach ($r in $Require) {
    if (-not (Test-Path $paths[$r])) { $missing += $r }
}

@{
    ok         = ($missing.Count -eq 0)
    featureDir = $FeatureDir
    paths      = $paths
    missing    = $missing
} | ConvertTo-Json -Depth 4 -Compress

if ($missing.Count -gt 0) { exit 1 } else { exit 0 }
