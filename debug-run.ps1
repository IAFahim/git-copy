# Debug script to trace the exact issue
Write-Host "=== Debugging git-copy.ps1 ===`n"

$TestDir = Join-Path $env:TEMP "git-copy-debug-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Force -Path $TestDir | Out-Null
Push-Location $TestDir

try {
    Write-Host "Setting up test git repo..."

    git init -q
    git config user.email "test@test.com"
    git config user.name "Test User"

    # Create a test file
    "console.log('test');" | Out-File "test.js" -Encoding UTF8

    git add "test.js"
    git commit -q -m "test"

    Write-Host "Git repo created at: $TestDir`n"

    Write-Host "=== Testing git ls-files directly ==="
    $GitOut = git ls-files --cached --others --exclude-standard 2>$null
    Write-Host "Type: $($GitOut.GetType().FullName)"
    Write-Host "Value: $GitOut"
    Write-Host "Is Null: $($null -eq $GitOut)"

    Write-Host "`n=== Testing the split operation ==="
    $RawFiles = @($GitOut -split "`n")
    Write-Host "RawFiles Type: $($RawFiles.GetType().FullName)"
    Write-Host "RawFiles Count: $($RawFiles.Count)"

    Write-Host "`n=== Now let's trace into git-copy.ps1 ==="

    # Mock Set-Clipboard
    $ClipboardFile = Join-Path $TestDir "clipboard.txt"
    function Global:Set-Clipboard {
        param([string]$Value)
        $Value | Set-Content -Path $ClipboardFile -Encoding UTF8
    }

    # Run the actual script with verbose output
    Write-Host "`nRunning git-copy.ps1..."
    & "D:\IAFahim\Github\git-copy\git-copy.ps1"

    Write-Host "`n=== Script completed successfully! ==="

} finally {
    Pop-Location
    Remove-Item -Recurse -Force $TestDir -ErrorAction SilentlyContinue
}
