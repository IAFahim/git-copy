
$ErrorActionPreference = "Stop"
$ScriptPath = Join-Path $PSScriptRoot "git-copy.ps1"
$TestDirName = "git-copy-feature-test"
$TestDir = Join-Path $PSScriptRoot $TestDirName

# Cleanup previous run
if (Test-Path $TestDir) { Remove-Item -Recurse -Force $TestDir -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $TestDir | Out-Null

Push-Location $TestDir

try {
    Write-Host "Setting up test environment..." -ForegroundColor Cyan
    
    # 1. Setup Files
    # Main files
    New-Item -ItemType Directory -Force -Path "TestProject" | Out-Null
    Set-Location "TestProject"
    
    "public class PlayerController : MonoBehaviour {}" | Set-Content "Player.cs"
    "guid: 12345" | Set-Content "Player.cs.meta"
    "SECRET_KEY=123" | Set-Content ".env"
    "node_modules stuff" | Set-Content "package-lock.json"

    # Pattern exclusion test fixtures
    New-Item -ItemType Directory -Force -Path "MyApp.Tests" | Out-Null
    "public class TestClass {}" | Set-Content "MyApp.Tests/UnitTest.cs"
    "public class UtilsTest {}" | Set-Content "Utils.Tests.cs"
    "# Test File" | Set-Content "README.md"
    New-Item -ItemType Directory -Force -Path "docs" | Out-Null
    "# Docs" | Set-Content "docs/guide.md"
    "test content" | Set-Content "test_file.cs"
    
    # Mock Clipboard
    function Global:Set-Clipboard {
        param([Parameter(ValueFromPipeline=$true)]$Value)
        $Value | Set-Content "..\clipboard_output.md" -Encoding UTF8
    }

    # --- TEST 1: Basic & Defaults ---
    Write-Host "`n[TEST 1] Basic & Defaults..." -NoNewline
    if (Test-Path "..\clipboard_output.md") { Remove-Item "..\clipboard_output.md" }
    
    & $ScriptPath | Out-Null
    
    $Output = Get-Content "..\clipboard_output.md" -Raw
    
    if ($Output -notmatch "Player.cs") { throw "Player.cs missing" }
    if ($Output -match "Player.cs.meta") { throw ".meta NOT ignored" }
    if ($Output -match "SECRET_KEY") { throw ".env NOT ignored" }
    Write-Host " PASS" -ForegroundColor Green

    # --- TEST 2: Pattern --*.Tests ---
    Write-Host "[TEST 2] Pattern --*.Tests..." -NoNewline
    if (Test-Path "..\clipboard_output.md") { Remove-Item "..\clipboard_output.md" }
    
    & $ScriptPath "--*.Tests*" | Out-Null
    
    $Output = Get-Content "..\clipboard_output.md" -Raw
    
    if ($Output -match "MyApp.Tests") { throw "MyApp.Tests NOT excluded" }
    if ($Output -match "Utils.Tests.cs") { throw "Utils.Tests.cs NOT excluded" }
    if ($Output -notmatch "Player.cs") { throw "Player.cs incorrectly excluded" }
    Write-Host " PASS" -ForegroundColor Green

    # --- TEST 3: Extension -.md ---
    Write-Host "[TEST 3] Extension -.md..." -NoNewline
    if (Test-Path "..\clipboard_output.md") { Remove-Item "..\clipboard_output.md" }
    
    & $ScriptPath "-.md" | Out-Null
    
    $Output = Get-Content "..\clipboard_output.md" -Raw
    
    if ($Output -match "README.md") { throw "README.md NOT excluded" }
    if ($Output -match "guide.md") { throw "guide.md NOT excluded" }
    if ($Output -notmatch "Player.cs") { throw "Player.cs incorrectly excluded" }
    Write-Host " PASS" -ForegroundColor Green

    # --- TEST 4: Multiple Patterns ---
    Write-Host "[TEST 4] Multiple Patterns (--*.Tests -.md)..." -NoNewline
    if (Test-Path "..\clipboard_output.md") { Remove-Item "..\clipboard_output.md" }
    
    & $ScriptPath "--*.Tests*" "-.md" | Out-Null
    
    $Output = Get-Content "..\clipboard_output.md" -Raw
    
    if ($Output -match "MyApp.Tests") { throw "MyApp.Tests NOT excluded" }
    if ($Output -match "README.md") { throw "README.md NOT excluded" }
    if ($Output -notmatch "Player.cs") { throw "Player.cs incorrectly excluded" }
    Write-Host " PASS" -ForegroundColor Green
    
    Write-Host "`nALL FEATURE TESTS PASSED" -ForegroundColor Green

} catch {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
    # Remove-Item -Recurse -Force $TestDir -ErrorAction SilentlyContinue
}
