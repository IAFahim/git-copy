New-Item -ItemType Directory -Force -Path 'test-repo' | Out-Null
Set-Location 'test-repo'
git init -q
git config user.email 'test@test.com'
git config user.name 'Test'

# Create multiple files
'test1' | Out-File 'test1.txt'
'test2' | Out-File 'test2.txt'
'test3' | Out-File 'test3.txt'

git add .
git commit -q -m 'test'

Write-Host "=== Multiple files test ==="
$GitOut = git ls-files --cached --others --exclude-standard
Write-Host "Type: $($GitOut.GetType().Name)"
Write-Host "Value: $GitOut"
Write-Host "Contains newlines: $($GitOut.Contains("`n"))"

Write-Host "`n=== Split by newline ==="
$split = $GitOut -split "`n"
Write-Host "Split count: $($split.Count)"
Write-Host "Split values:"
$split | ForEach-Object { Write-Host "  - [$_]" }

Write-Host "`n=== Check for empty strings ==="
$split = $GitOut -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
Write-Host "After filtering empty: $($split.Count)"

Set-Location ..
Remove-Item -Recurse -Force 'test-repo'
