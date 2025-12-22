<#
.SYNOPSIS
    Cross-platform test suite for git-copy (Windows)
.DESCRIPTION
    Tests basic functionality, file filtering, and folder exclusion
#>

$ErrorActionPreference = "Stop"
$TestDir = "$env:TEMP\git-copy-test-$([guid]::NewGuid().ToString('N').Substring(0,8))"
$ScriptPath = Join-Path $PSScriptRoot "git-copy.ps1"

Write-Host "`n=== GIT-COPY TEST SUITE (Windows) ===" -ForegroundColor Cyan
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

    # Test 1: Basic functionality
    Write-Host "[TEST 1] Basic copy all files..." -NoNewline
    & $ScriptPath | Out-Null
    $result = Get-Clipboard
    if ($result -match "test.js" -and $result -match "test.py" -and $result -match "README.md") {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        throw "Basic test failed"
    }

    # Test 2: Filter by extension
    Write-Host "[TEST 2] Filter by extension (js)..." -NoNewline
    & $ScriptPath "js" | Out-Null
    $result = Get-Clipboard
    if ($result -match "test.js" -and $result -notmatch "test.py") {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        throw "Extension filter test failed"
    }

    # Test 3: Filter by preset
    Write-Host "[TEST 3] Filter by preset (web)..." -NoNewline
    & $ScriptPath "web" | Out-Null
    $result = Get-Clipboard
    if ($result -match "test.js" -and $result -match "Button.jsx") {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        throw "Preset filter test failed"
    }

    # Test 4: Exclude folder (node_modules)
    Write-Host "[TEST 4] Exclude folder (node_modules)..." -NoNewline
    & $ScriptPath | Out-Null
    $result = Get-Clipboard
    if ($result -notmatch "node_modules") {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        throw "Exclude test failed - node_modules should be excluded by default"
    }

    # Test 5: Exclude custom folder using -path syntax
    Write-Host "[TEST 5] Exclude custom folder (-temp)..." -NoNewline
    & $ScriptPath "-temp" | Out-Null
    $result = Get-Clipboard
    if ($result -notmatch "temp.txt") {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        throw "Custom exclude test failed"
    }

    # Test 6: Exclude nested folder
    Write-Host "[TEST 6] Exclude nested folder (-src/components)..." -NoNewline
    & $ScriptPath "-src/components" | Out-Null
    $result = Get-Clipboard
    if ($result -match "Main.java" -and $result -notmatch "Button.jsx") {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        throw "Nested exclude test failed"
    }

    # Test 7: Multiple excludes
    Write-Host "[TEST 7] Multiple excludes (-temp -src)..." -NoNewline
    & $ScriptPath "-temp" "-src" | Out-Null
    $result = Get-Clipboard
    if ($result -notmatch "temp.txt" -and $result -notmatch "Main.java" -and $result -notmatch "Button.jsx") {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        throw "Multiple exclude test failed"
    }

    # Test 8: Filter and exclude combined
    Write-Host "[TEST 8] Filter (js) + Exclude (-src)..." -NoNewline
    & $ScriptPath "js" "-src" | Out-Null
    $result = Get-Clipboard
    if ($result -match "test.js" -and $result -notmatch "Button.jsx") {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        throw "Combined filter and exclude test failed"
    }

    Write-Host "`n=== ALL TESTS PASSED ===" -ForegroundColor Green

} finally {
    Pop-Location
    Remove-Item -Recurse -Force $TestDir -ErrorAction SilentlyContinue
}
