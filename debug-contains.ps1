# Test the Contains method
$TargetExtensions = [System.Collections.Generic.List[string]]::new()
$TargetExtensions.Add("js")

Write-Host "TargetExtensions: $($TargetExtensions -join ', ')"

# Test Contains
Write-Host "`nTesting Contains method:"
Write-Host "  'js' in list: $($TargetExtensions.Contains('js'))"
Write-Host "  'JS' in list: $($TargetExtensions.Contains('JS'))"
Write-Host "  'py' in list: $($TargetExtensions.Contains('py'))"
Write-Host "  'md' in list: $($TargetExtensions.Contains('md'))"

# Test with actual extensions
$testFiles = @("test.js", "test.py", "README.md", "folder/file.js")

Write-Host "`nTesting file extensions:"
foreach ($file in $testFiles) {
    $Ext = [System.IO.Path]::GetExtension($file).TrimStart('.')
    $FileName = [System.IO.Path]::GetFileName($file)
    Write-Host "  $file"
    Write-Host "    Extension: '$Ext'"
    Write-Host "    FileName: '$FileName'"
    $Matched = $TargetExtensions.Contains($Ext) -or $TargetExtensions.Contains($FileName.ToLower())
    Write-Host "    Matched: $Matched"
}
