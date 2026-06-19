# One script = one manual step. Mimic exactly what the user does by hand.
# No frameworks, no orchestration. Parameters in, observable result out.
# exit 0 on the oracle's PASS signal; non-zero otherwise. Always print the
# observed value so the Tester can log it.

[CmdletBinding()]
param(
    # Declare the concrete inputs this step needs (from test-memory.md `inputs`).
    [Parameter(Mandatory = $true)] [string] $Example
)

$ErrorActionPreference = 'Stop'

try {
    # --- do the single manual action here ---
    $observed = "<capture the value the oracle inspects>"

    Write-Output "OBSERVED: $observed"

    # --- evaluate against the oracle ---
    if ($observed -eq 'expected') {
        exit 0
    }
    else {
        Write-Error "Oracle not met. Expected 'expected', observed '$observed'."
        exit 1
    }
}
catch {
    Write-Error $_
    exit 2
}
