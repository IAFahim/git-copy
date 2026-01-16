
$ErrorActionPreference = "Stop"
$ScriptPath = Join-Path $PSScriptRoot "git-copy.ps1"
$TestDirName = "git-copy-fuzzy-test"
$TestDir = Join-Path $PSScriptRoot $TestDirName

# Cleanup
if (Test-Path $TestDir) { Remove-Item -Recurse -Force $TestDir -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $TestDir | Out-Null

Push-Location $TestDir

try {
    Write-Host "Setting up fuzzy test..." -ForegroundColor Cyan
    
    # Setup Files
    "content" | Set-Content "MyTests.txt"
    "content" | Set-Content "Tests.txt"
    New-Item -ItemType Directory -Force -Path "Tests" | Out-Null
    "content" | Set-Content "Tests/file.txt"

    # Mock Clipboard
    function Global:Set-Clipboard {
        param([Parameter(ValueFromPipeline=$true)]$Value)
        $Value | Set-Content "..\clipboard_output.md" -Encoding UTF8
    }

    # --- TEST: Exclude --Tests ---
    Write-Host "[TEST] Exclude --Tests..."
    & $ScriptPath "--Tests" | Out-Null
    
    $Output = Get-Content "..\clipboard_output.md" -Raw
    
    if ($Output -match "Tests.txt") { Write-Host "Tests.txt present (Expected? Depends on Strictness)" -ForegroundColor Yellow }
    else { Write-Host "Tests.txt EXCLUDED" -ForegroundColor Red }

    if ($Output -match "MyTests.txt") { Write-Host "MyTests.txt present" -ForegroundColor Green }
    else { Write-Host "MyTests.txt EXCLUDED (Aggressive Fuzzy Match)" -ForegroundColor Red }

    if ($Output -match "Tests/file.txt") { Write-Host "Tests/file.txt present" -ForegroundColor Red }
    else { Write-Host "Tests/file.txt EXCLUDED (Correct)" -ForegroundColor Green }

} finally {
    Pop-Location
}
