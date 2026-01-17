<#
.SYNOPSIS
    GIT-COPY Test Suite v16.2 - Windows Edition

.DESCRIPTION
    Comprehensive test suite for git-copy functionality on Windows.
    Tests file filtering, exclusion, and clipboard operations.

.PARAMETER Verbose
    Enable verbose output

.PARAMETER Debug
    Enable debug output

.EXAMPLE
    .\test.ps1
    Run all tests

.EXAMPLE
    .\test.ps1 -Verbose
    Run tests with verbose output

.NOTES
    Version: 16.2
    Requires: Git, PowerShell 5.1+
#>

[CmdletBinding()]
param()

# ==============================================================================
# CONFIGURATION
# ==============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

[Version]$TestVersion = "16.2"
$TempBase = [System.IO.Path]::GetTempPath()
$TestDirName = "git-copy-test-$([guid]::NewGuid().ToString('N').Substring(0,8))"
$TestDir = Join-Path $TempBase $TestDirName
$ScriptPath = Join-Path $PSScriptRoot "git-copy.ps1"

# Test tracking
$TestResults = @{
    Passed = 0
    Failed = 0
    Total = 0
}

# ==============================================================================
# LOGGING FUNCTIONS
# ==============================================================================

function Write-TestInfo {
    [CmdletBinding()]
    param([string]$Message)
    Write-Host "[INFO] " -NoNewline -ForegroundColor Cyan
    Write-Host $Message
}

function Write-TestSuccess {
    [CmdletBinding()]
    param([string]$Message)
    Write-Host "[PASS] " -NoNewline -ForegroundColor Green
    Write-Host $Message
}

function Write-TestFailure {
    [CmdletBinding()]
    param([string]$Message)
    Write-Host "[FAIL] " -NoNewline -ForegroundColor Red
    Write-Host $Message
}

function Invoke-TestCase {
    [CmdletBinding()]
    param(
        [string]$Name,
        [scriptblock]$TestBlock
    )

    $TestResults.Total++
    Write-Host "[TEST $($TestResults.Total)] $Name..." -NoNewline

    try {
        & $TestBlock
        Write-Host " PASS" -ForegroundColor Green
        $TestResults.Passed++
    }
    catch {
        Write-Host " FAIL" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        $TestResults.Failed++
    }
}

# ==============================================================================
# TEST SETUP
# ==============================================================================

Write-Host "`n=== GIT-COPY TEST SUITE v$TestVersion (Windows) ===" -ForegroundColor Cyan
Write-Host "Test directory: $TestDir`n" -ForegroundColor Gray

# ==============================================================================
# TEST ENVIRONMENT
# ==============================================================================
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

    # Test 1: Basic functionality
    if (Test-Path $ClipboardFile) { Remove-Item $ClipboardFile }
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
    if (Test-Path $ClipboardFile) { Remove-Item $ClipboardFile }
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
    if (Test-Path $ClipboardFile) { Remove-Item $ClipboardFile }
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
    if (Test-Path $ClipboardFile) { Remove-Item $ClipboardFile }
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
    if (Test-Path $ClipboardFile) { Remove-Item $ClipboardFile }
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
    if (Test-Path $ClipboardFile) { Remove-Item $ClipboardFile }
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
    if (Test-Path $ClipboardFile) { Remove-Item $ClipboardFile }
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
    if (Test-Path $ClipboardFile) { Remove-Item $ClipboardFile }
    Write-Host "[TEST 8] Filter (js) + Exclude (-src)..." -NoNewline
    & $ScriptPath "js" "-src" | Out-Null
    $result = Get-Clipboard
    if ($result -match "test.js" -and $result -notmatch "Button.jsx") {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        throw "Combined filter and exclude test failed"
    }

    # ==============================================================================
    # TEST RESULTS
    # ==============================================================================

    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor White
    Write-Host "=== ALL TESTS PASSED ===" -ForegroundColor Green
    Write-Host "============================================================================" -ForegroundColor White
    Write-Host "Total Tests: $($TestResults.Total)"
    Write-Host "Passed: " -NoNewline
    Write-Host "$($TestResults.Passed)" -ForegroundColor Green
    Write-Host "Failed: " -NoNewline
    Write-Host "$($TestResults.Failed)" -ForegroundColor Red
    Write-Host ""

} finally {
    Pop-Location
    Remove-Item -Recurse -Force $TestDir -ErrorAction SilentlyContinue
}
