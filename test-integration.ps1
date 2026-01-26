# Setup test fixtures
New-Item -ItemType Directory -Force -Path "TestProject" | Out-Null
"public class PlayerController : MonoBehaviour {}" | Set-Content "TestProject\Player.cs"
"guid: 12345" | Set-Content "TestProject\Player.cs.meta"
"SECRET_KEY=123" | Set-Content "TestProject\.env"
"node_modules stuff" | Set-Content "TestProject\package-lock.json"

# Mock clipboard
function Set-Clipboard {
    param([Parameter(ValueFromPipeline=$true)]$Value)
    $Value | Set-Content "TestProject\clipboard_output.md"
}

# Run tool
$ScriptPath = Join-Path $PSScriptRoot "git-copy.ps1"
cd TestProject
& $ScriptPath unity

# Verify output
if (-not (Test-Path "clipboard_output.md")) {
    Write-Error "FAIL: No output created"
    exit 1
}

$Output = Get-Content "clipboard_output.md" -Raw

# Assertions
if ($Output -notmatch "Player.cs") {
    Write-Error "FAIL: Player.cs missing"
    exit 1
}

if ($Output -match "Player.cs.meta") {
    Write-Error "FAIL: .meta file not ignored"
    exit 1
}

if ($Output -match "SECRET_KEY") {
    Write-Error "FAIL: .env file not ignored"
    exit 1
}

Write-Host "[OK] Integration test passed" -ForegroundColor Green
