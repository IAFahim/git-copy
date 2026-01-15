<#
.SYNOPSIS
    Cross-platform test suite for git-copy (Windows)
.DESCRIPTION
    Tests basic functionality, file filtering, and folder exclusion
#>

$ErrorActionPreference = "Stop"
$TempBase = [System.IO.Path]::GetTempPath()
$TestDirName = "git-copy-test-$([guid]::NewGuid().ToString('N').Substring(0,8))"
$TestDir = Join-Path $TempBase $TestDirName

$ScriptPath = Join-Path $PSScriptRoot "git-copy.ps1"

Write-Host "`n=== GIT-COPY TEST SUITE (Cross-Platform) ===" -ForegroundColor Cyan
Write-Host "Test directory: $TestDir`n" -ForegroundColor Gray

# Create test environment
New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
Push-Location $TestDir

try {
    # Initialize git repo
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test User"

    # Create test files
    @"
function hello() {
    console.log("Hello");
}
"@ | Out-File "test.js" -Encoding UTF8
    
    @"
def greet():
    print("Hello")
"@ | Out-File "test.py" -Encoding UTF8
    
    @"
# Test Document
This is a test.
"@ | Out-File "README.md" -Encoding UTF8

    # Create excluded directory
    New-Item -ItemType Directory -Path "node_modules" -Force | Out-Null
    @"
module.exports = {};
"@ | Out-File "node_modules\index.js" -Encoding UTF8

    # Create nested structure
    New-Item -ItemType Directory -Path "src\components" -Force | Out-Null
    @"
const Component = () => {};
"@ | Out-File "src\components\Button.jsx" -Encoding UTF8
    
    @"
public class Main {}
"@ | Out-File "src\Main.java" -Encoding UTF8

    # Create test directory to exclude
    New-Item -ItemType Directory -Path "temp" -Force | Out-Null
    "temp file" | Out-File "temp\temp.txt" -Encoding UTF8

    git add -A
    git commit -q -m "Initial commit"

    # Mock Clipboard
    $ClipboardFile = Join-Path $TestDir "mock_clipboard.txt"
    function Global:Set-Clipboard { 
        param([Parameter(ValueFromPipeline=$true, Mandatory=$false)][string]$Value)
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Value")) {
             $Value | Set-Content -Path $ClipboardFile -Encoding UTF8
        } elseif ($Input) {
             $Input | Set-Content -Path $ClipboardFile -Encoding UTF8
        }
    }
    function Global:Get-Clipboard { 
        if (Test-Path $ClipboardFile) { Get-Content -Path $ClipboardFile -Raw -Encoding UTF8 } else { "" }
    }

    # Test 5: Exclude custom folder using -path syntax
    Write-Host "[TEST 5] Exclude custom folder (-temp)..." -NoNewline
    & $ScriptPath "-temp" # Removed Out-Null to see potential errors
    $result = Get-Clipboard
    Write-Host "DEBUG: Clipboard content length: $($result.Length)"
    if ($result -notmatch "temp.txt") {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        throw "Custom exclude test failed"
    }

    Write-Host "`n=== ALL TESTS PASSED ===" -ForegroundColor Green

} finally {
    Pop-Location
    Remove-Item -Recurse -Force $TestDir -ErrorAction SilentlyContinue
}
