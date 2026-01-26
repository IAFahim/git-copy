# Test what values TargetExtensions gets
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments = @()
)

Write-Host "Arguments received: $Arguments"
Write-Host "Arguments count: $($Arguments.Count)"

$ArgsList = @($Arguments | Where-Object { $null -ne $_ })
Write-Host "ArgsList count: $($ArgsList.Count)"

$PRESETS = @{
    "web"     = @("html","htm","css","scss","sass","less","js","jsx","ts","tsx","json","svg","vue","svelte")
}

$TargetExtensions = [System.Collections.Generic.List[string]]::new()

Write-Host "`nProcessing arguments..."
foreach ($arg in $ArgsList) {
    Write-Host "  Processing: '$arg'"
    $val = $arg.ToLower().TrimStart(".")
    Write-Host "    Normalized: '$val'"
    if ($PRESETS.ContainsKey($val)) {
        Write-Host "    Is preset!"
        $PRESETS[$val] | ForEach-Object {
            Write-Host "      Adding: $_"
            $TargetExtensions.Add($_)
        }
    } else {
        Write-Host "    Is extension"
        Write-Host "      Adding: $val"
        $TargetExtensions.Add($val)
    }
}

Write-Host "`nFinal TargetExtensions count: $($TargetExtensions.Count)"
Write-Host "TargetExtensions: $($TargetExtensions -join ', ')"
Write-Host "IsFilterActive: $($TargetExtensions.Count -gt 0)"
