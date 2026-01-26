$ArgsList = @()
Write-Host "Before Where-Object"
Write-Host "  Type: $($ArgsList.GetType().Name)"
Write-Host "  Count: $($ArgsList.Count)"

$ArgsList = $ArgsList | Where-Object { $null -ne $_ }
Write-Host "`nAfter Where-Object"
Write-Host "  Is Null: $($null -eq $ArgsList)"
Write-Host "  Type: $(if ($null -ne $ArgsList) { $ArgsList.GetType().Name } else { 'N/A' })"
if ($null -ne $ArgsList) {
    Write-Host "  Count: $($ArgsList.Count)"
    Write-Host "  Is Array: $($ArgsList -is [array])"
}

# Test with null values
Write-Host "`n=== Test with null values ==="
$ArgsList2 = @($null, $null)
Write-Host "Before filter: Count = $($ArgsList2.Count)"
$ArgsList2 = $ArgsList2 | Where-Object { $null -ne $_ }
Write-Host "After filter: Type = $(if ($null -ne $ArgsList2) { $ArgsList2.GetType().Name } else { 'NULL' })"
Write-Host "After filter: Is Null = $($null -eq $ArgsList2)"
