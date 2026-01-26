New-Item -ItemType Directory -Force -Path 'test-repo' | Out-Null
Set-Location 'test-repo'
git init -q
git config user.email 'test@test.com'
git config user.name 'Test'
'test' | Out-File 'test.txt'
git add 'test.txt'
git commit -q -m 'test'

Write-Host "=== Test 1: Direct output ==="
$GitOut = git ls-files --cached --others --exclude-standard
Write-Host "Type: $($GitOut.GetType().Name)"
Write-Host "Is Array: $($GitOut -is [array])"
Write-Host "Value: $GitOut"

Write-Host "`n=== Test 2: Array expression ==="
$GitOut2 = @(git ls-files --cached --others --exclude-standard)
Write-Host "Type: $($GitOut2.GetType().Name)"
Write-Host "Count: $($GitOut2.Count)"
Write-Host "Value: $GitOut2"

Write-Host "`n=== Test 3: Using @() and checking null ==="
$GitOut3 = git ls-files --cached --others --exclude-standard 2>$null
if ($null -ne $GitOut3) {
    Write-Host "GitOut3 is not null"
    $RawFiles = @($GitOut3 -split "`n")
    Write-Host "After split - Count: $($RawFiles.Count)"
    Write-Host "Values: $RawFiles"
}

Set-Location ..
Remove-Item -Recurse -Force 'test-repo'
