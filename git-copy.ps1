<#
.SYNOPSIS
    GIT-COPY | v17.3 | Professional Edition (Fixes Pattern Matching)
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
# Force UTF-8 to prevent encoding issues
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

# --- HELPERS ---
function Convert-GlobToRegex {
    param([string]$Pattern)
    # 1. Escape everything to treat dots, brackets, etc as literals
    $safe = [regex]::Escape($Pattern)
    # 2. Convert escaped wildcards back to regex wildcards
    #    \*  (literal *) becomes .* (match anything)
    #    \?  (literal ?) becomes .  (match one char)
    $regex = $safe -replace "\\\*", ".*" -replace "\\\?", "."
    # 3. Anchor start/end loosely to match "contains path"
    return "^.*$regex.*$"
}

# --- MAIN ---
$ArgsList = @($Arguments)

if ($Help -or ($ArgsList -contains "--help") -or ($ArgsList -contains "-h")) {
    Write-Host "GIT-COPY | v17.3" -ForegroundColor Cyan
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
    
    # 1. Explicit Exclude Flag: --exclude / -exclude
    if ($arg -eq "--exclude" -or $arg -eq "-exclude") {
        if ($i + 1 -lt $ArgsList.Count) {
            $ExcludePaths.Add($ArgsList[$i+1].TrimStart("-"))
            $SkipNext = $true
        }
        continue
    }

    # 2. Pattern Exclusion: --*.Tests (Starts with --)
    if ($arg.StartsWith("--")) {
        $pat = $arg.Substring(2) # Strip --
        if (-not [string]::IsNullOrWhiteSpace($pat)) {
            $ExcludePatterns.Add((Convert-GlobToRegex $pat))
        }
        continue
    }

    # 3. Extension Exclusion: -.md (Starts with -.)
    if ($arg.StartsWith("-.")) {
        $ext = $arg.Substring(2) # Strip -.
        if (-not [string]::IsNullOrWhiteSpace($ext)) {
            $ExcludePatterns.Add((Convert-GlobToRegex "*.$ext"))
        }
        continue
    }

    # 4. Path Exclusion: -node_modules (Starts with -)
    if ($arg.StartsWith("-")) {
        $path = $arg.Substring(1) # Strip -
        if (-not [string]::IsNullOrWhiteSpace($path)) {
            $ExcludePaths.Add($path)
        }
        continue
    }

    # 5. Presets/Extensions (No prefix)
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
    # Unify separators to forward slash
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

    # Normalize Path to relative Unix-style path
    if ($FileEntry -match "^[A-Za-z]:") {
        # It's an absolute Windows path (from Get-ChildItem)
        $RelPath = $FileEntry.Substring($RootPath.Length).Trim('\', '/')
    } else {
        # It's already relative (from git)
        $RelPath = $FileEntry.Trim()
    }
    # Force forward slashes for ALL regex/comparison logic
    $RelPath = $RelPath -replace '\\', '/'

    # --- FILTERS ---

    # 1. Regex Bans
    if ($IgnoreRe.IsMatch($RelPath)) { continue }
    if ($SecRe.IsMatch($RelPath)) { continue }

    # 2. Path Exclusions (Prefix Match)
    $IsExcluded = $false
    foreach ($ex in $NormalizedExcludes) {
        if ($RelPath -eq $ex -or $RelPath.StartsWith("$ex/") -or $RelPath -like "*/$ex/*") {
            $IsExcluded = $true; break
        }
    }
    if ($IsExcluded) { continue }

    # 3. Pattern Exclusions (Regex Match)
    foreach ($pat in $ExcludePatterns) {
        if ($RelPath -match $pat) { 
            $IsExcluded = $true
            break 
        }
    }
    if ($IsExcluded) { continue }

    # 4. Extension Filter
    $Ext = [System.IO.Path]::GetExtension($RelPath).TrimStart('.')
    if ($IsFilterActive -and -not $TargetExtensions.Contains($Ext)) { continue }

    # --- CONTENT ---
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