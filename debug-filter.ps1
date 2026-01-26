# Debug the filter logic
Write-Host "=== Testing extension filter ===`n"

$TestDir = Join-Path $env:TEMP "git-copy-filter-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Force -Path $TestDir | Out-Null
Push-Location $TestDir

try {
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"

    # Create test files
    "function test() { }" | Out-File "test.js" -Encoding UTF8
    "def test(): pass" | Out-File "test.py" -Encoding UTF8
    "# Test" | Out-File "README.md" -Encoding UTF8

    git add .
    git commit -q -m "test"

    Write-Host "Files created: test.js, test.py, README.md"

    # Mock clipboard
    $ClipboardFile = Join-Path $TestDir "clipboard.txt"
    function Global:Set-Clipboard {
        param([string]$Value)
        $Value | Set-Content -Path $ClipboardFile -Encoding UTF8
    }

    Write-Host "`nRunning: git-copy.ps1 js"
    & "D:\IAFahim\Github\git-copy\git-copy.ps1" "js"

    if (Test-Path $ClipboardFile) {
        $content = Get-Content $ClipboardFile -Raw
        Write-Host "`n=== Clipboard content ==="
        Write-Host $content

        Write-Host "`n=== Checking files ==="
        if ($content -match "test.js") { Write-Host "[OK] test.js found" }
        else { Write-Host "[FAIL] test.js NOT found" }

        if ($content -match "test.py") { Write-Host "[FAIL] test.py found (should be excluded)" }
        else { Write-Host "[OK] test.py excluded" }

        if ($content -match "README.md") { Write-Host "[FAIL] README.md found (should be excluded)" }
        else { Write-Host "[OK] README.md excluded" }
    }

} finally {
    Pop-Location
    Remove-Item -Recurse -Force $TestDir -ErrorAction SilentlyContinue
}
