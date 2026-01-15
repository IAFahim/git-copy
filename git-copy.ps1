<#
.SYNOPSIS
    GIT-COPY | v17.2 | Professional Edition
    Bundles code files into a single Markdown snippet and copies to clipboard.
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments = @(),

    [Alias("h")]
    [switch]$Help
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- CONFIG ---
$MAX_SIZE = 1MB
$FENCE = '```' 

$PRESETS = @{
    "web"     = @("html","htm","css","scss","sass","less","js","jsx","ts","tsx","json","svg","vue","svelte")
    "backend" = @("py","rb","php","pl","go","rs","java","cs","cpp","h","c","hpp","swift","kt","ex","exs","sh")
    "dotnet"  = @("cs","razor","csproj","json","http","xaml")
    "unity"   = @("cs","shader","cginc","hlsl","glsl","asmdef","asmref","uss","uxml","json","yaml")
    "java"    = @("java","kt","kts","scala")
    "cpp"     = @("c","h","cpp","cc","cxx","hpp","hxx","rs","go","swift")
    "script"  = @("py","rb","php","pl","pm","lua","sh","bash","zsh","ps1")
    "data"    = @("sql","xml","json","yaml","yml","toml","ini","md","csv","graphql")
    "config"  = @("env","conf","ini","Dockerfile","Makefile","Gemfile","package.json","cargo.toml","go.mod")
    "build"   = @("Dockerfile","Makefile","Gemfile","package.json")
    "docs"    = @("md","txt","rst","adoc")
}

$LANG_MAP = @{
    "js" = "javascript"; "ts" = "typescript"; "py" = "python";
    "cs" = "csharp"; "sh" = "bash"; "md" = "markdown";
    "h" = "c"; "hpp" = "cpp"; "razor" = "html"; "vue" = "html";
    "shader" = "glsl"; "cginc" = "glsl"; "hlsl" = "glsl"; 
    "uss" = "css"; "uxml" = "xml"; "ps1" = "powershell"
}

# --- REGEX HELPERS ---
function Convert-GlobToRegex {
    param([string]$Pattern)
    # Robust char-by-char conversion to avoid regex-replace confusion
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append("^.*") # Anchor start, allow leading path
    
    $chars = $Pattern.ToCharArray()
    foreach ($c in $chars) {
        if ($c -eq '*') { [void]$sb.Append(".*") }
        elseif ($c -eq '?') { [void]$sb.Append(".") }
        else { [void]$sb.Append([regex]::Escape($c.ToString())) }
    }
    
    [void]$sb.Append(".*$") # Anchor end, allow trailing path/content
    return $sb.ToString()
}

# --- MAIN ---
# Force array to prevent StrictMode crash on empty input
$ArgsList = @($Arguments)

if ($Help -or ($ArgsList -contains "--help") -or ($ArgsList -contains "-h")) {
    Write-Host "GIT-COPY | v17.2" -ForegroundColor Cyan
    exit 0
}

Write-Host "Processing..." -ForegroundColor Cyan

# 1. PARSE ARGUMENTS
$TargetExtensions = [System.Collections.Generic.List[string]]::new()
$ExcludePaths     = [System.Collections.Generic.List[string]]::new()
$ExcludePatterns  = [System.Collections.Generic.List[string]]::new()

$SkipNext = $false
for ($i = 0; $i -lt $ArgsList.Count; $i++) {
    if ($SkipNext) { $SkipNext = $false; continue }
    $arg = $ArgsList[$i]
    
    # explicit --exclude flag
    if ($arg -match "^--exclude$|^-exclude$") {
        if ($i + 1 -lt $ArgsList.Count) {
            $ExcludePaths.Add($ArgsList[$i+1].TrimStart("-"))
            $SkipNext = $true
        }
        continue
    }

    # Pattern exclusion: --*.Tests
    if ($arg -match "^--(?!exclude)(.+)") {
        $pat = $Matches[1]
        $ExcludePatterns.Add((Convert-GlobToRegex $pat))
        continue
    }

    # Extension exclusion: -.md
    if ($arg -match "^-\.(.+)") {
        $ext = $Matches[1]
        $ExcludePatterns.Add((Convert-GlobToRegex "*.$ext"))
        continue
    }

    # Path exclusion: -node_modules
    if ($arg -match "^-(.+)") {
        $ExcludePaths.Add($Matches[1])
        continue
    }

    # Presets/Extensions
    $val = $arg.ToLower().TrimStart(".")
    if ($PRESETS.ContainsKey($val)) {
        $PRESETS[$val] | ForEach-Object { $TargetExtensions.Add($_) }
    } else {
        $TargetExtensions.Add($val)
    }
}

# Normalize Exclude Paths
$NormalizedExcludes = [System.Collections.Generic.List[string]]::new()
foreach ($path in $ExcludePaths) {
    $clean = $path -replace '\\', '/'
    $clean = $clean -replace '^\./', ''
    $NormalizedExcludes.Add($clean)
}

# 2. DISCOVERY
$RootPath = (Get-Location).Path
$RawFiles = @()

if (Test-Path ".git") {
    $GitOut = git ls-files --cached --others --exclude-standard 2>$null
    if ($GitOut) { $RawFiles = $GitOut }
    else { $RawFiles = Get-ChildItem -Recurse -File | Select-Object -ExpandProperty FullName }
} else {
    $RawFiles = Get-ChildItem -Recurse -File | Select-Object -ExpandProperty FullName
}

# 3. PROCESSING
$OutputBuilder = [System.Text.StringBuilder]::new()
$StructureList = [System.Collections.Generic.List[string]]::new()
$TotalBytes = 0
$FileCount = 0
$IsFilterActive = $TargetExtensions.Count -gt 0

# Compile ignore regexes
$RegexOpts = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
$IgnoreRe = [regex]::new("(package-lock\.json|yarn\.lock|Cargo\.lock|\.DS_Store|Thumbs\.db|\.git/|\.png$|\.jpg$|\.jpeg$|\.gif$|\.ico$|\.woff2?$|\.pdf$|\.exe$|\.bin$|\.pyc$|\.dll$|\.pdb$|\.min\.js$|\.min\.css$|\.meta$)", $RegexOpts)
$SecRe = [regex]::new("(id_rsa|id_dsa|\.pem|\.key|\.p12|\.env|secrets|credentials)", $RegexOpts)

foreach ($FileEntry in $RawFiles) {
    if ([string]::IsNullOrWhiteSpace($FileEntry)) { continue }

    if ($FileEntry -match "^[A-Za-z]:") {
        $RelPath = $FileEntry.Substring($RootPath.Length).Trim('\', '/')
    } else {
        $RelPath = $FileEntry.Trim()
    }
    $RelPath = $RelPath -replace '\\', '/'

    # FILTERS
    if ($IgnoreRe.IsMatch($RelPath)) { continue }
    if ($SecRe.IsMatch($RelPath)) { continue }

    # Path Exclusions
    $IsExcluded = $false
    foreach ($ex in $NormalizedExcludes) {
        if ($RelPath -eq $ex -or $RelPath.StartsWith("$ex/") -or $RelPath -like "*/$ex/*") {
            $IsExcluded = $true; break
        }
    }
    if ($IsExcluded) { continue }

    # Pattern Exclusions
    foreach ($pat in $ExcludePatterns) {
        if ($RelPath -match $pat) { 
            $IsExcluded = $true
            break 
        }
    }
    if ($IsExcluded) { continue }

    # Extension Filter
    $Ext = [System.IO.Path]::GetExtension($RelPath).TrimStart('.')
    if ($IsFilterActive -and -not $TargetExtensions.Contains($Ext)) { continue }

    # Content
    $FullPath = Join-Path $RootPath $RelPath
    $FileInfo = Get-Item $FullPath -ErrorAction SilentlyContinue
    if (-not $FileInfo -or $FileInfo.Length -gt $MAX_SIZE -or $FileInfo.Length -eq 0) { continue }

    try {
        $Lang = if ($LANG_MAP.ContainsKey($Ext.ToLower())) { $LANG_MAP[$Ext.ToLower()] } else { $Ext }
        $Content = [System.IO.File]::ReadAllText($FullPath, [System.Text.Encoding]::UTF8)

        [void]$OutputBuilder.AppendLine("## File: $RelPath")
        [void]$OutputBuilder.AppendLine("$FENCE$Lang")
        [void]$OutputBuilder.AppendLine($Content)
        [void]$OutputBuilder.AppendLine($FENCE)
        [void]$OutputBuilder.AppendLine("")

        $StructureList.Add($RelPath)
        $TotalBytes += $FileInfo.Length
        $FileCount++
    } catch {}
}

# 4. OUTPUT
[void]$OutputBuilder.AppendLine("")
[void]$OutputBuilder.AppendLine("_Project Structure:_")
[void]$OutputBuilder.AppendLine("${FENCE}text")
$StructureList.Sort()
foreach ($Path in $StructureList) { [void]$OutputBuilder.AppendLine($Path) }
[void]$OutputBuilder.AppendLine($FENCE)

$FinalOutput = $OutputBuilder.ToString()
Set-Clipboard -Value $FinalOutput

$Tokens = [math]::Truncate($TotalBytes / 4)
if ($TotalBytes -lt 1KB) { $SizeStr = "{0} B" -f $TotalBytes }
elseif ($TotalBytes -lt 1MB) { $SizeStr = "{0:N2} KB" -f ($TotalBytes / 1KB) }
else { $SizeStr = "{0:N2} MB" -f ($TotalBytes / 1MB) }

Write-Host "[OK]" -NoNewline -ForegroundColor Green
Write-Host " Copied: " -NoNewline -ForegroundColor Green
Write-Host "$FileCount" -NoNewline -ForegroundColor White
Write-Host " files | Size: " -NoNewline -ForegroundColor Green
Write-Host "$SizeStr" -NoNewline -ForegroundColor White
Write-Host " | Tokens: " -NoNewline -ForegroundColor Green
Write-Host "~$Tokens" -ForegroundColor White