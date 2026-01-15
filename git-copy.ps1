<#
.SYNOPSIS
    GIT-COPY | v17.1 | Professional Edition (Hotfix)
    Bundles code files into a single Markdown snippet and copies to clipboard.

.DESCRIPTION
    A high-performance, cross-platform tool to aggregate code context for LLMs.
    Respects .gitignore, handles binary exclusion, and secures secrets automatically.
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments = @(), # Initialize to empty array to prevent strict mode crash

    [Alias("h")]
    [switch]$Help
)

# -----------------------------------------------------------------------------
# CONFIGURATION & CONSTANTS
# -----------------------------------------------------------------------------
Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

# Force UTF-8 Output to prevent crashes with special characters/emojis
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$MAX_SIZE = 1MB
$FENCE = '```' 

# Preset Definitions
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

# Language Mapping
$LANG_MAP = @{
    "js" = "javascript"; "ts" = "typescript"; "py" = "python";
    "cs" = "csharp"; "sh" = "bash"; "md" = "markdown";
    "h" = "c"; "hpp" = "cpp"; "razor" = "html"; "vue" = "html";
    "shader" = "glsl"; "cginc" = "glsl"; "hlsl" = "glsl"; 
    "uss" = "css"; "uxml" = "xml"; "ps1" = "powershell"
}

# Regex Compilations
$RegexOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
$IgnoreRegex   = [regex]::new("(package-lock\.json|yarn\.lock|Cargo\.lock|\.DS_Store|Thumbs\.db|\.git/|\.png$|\.jpg$|\.jpeg$|\.gif$|\.ico$|\.woff2?$|\.pdf$|\.exe$|\.bin$|\.pyc$|\.dll$|\.pdb$|\.min\.js$|\.min\.css$|\.meta$)", $RegexOptions)
$SecurityRegex = [regex]::new("(id_rsa|id_dsa|\.pem|\.key|\.p12|\.env|secrets|credentials)", $RegexOptions)

# -----------------------------------------------------------------------------
# HELPER FUNCTIONS
# -----------------------------------------------------------------------------
function Show-Help {
    Write-Host @"
GIT-COPY | v17.1 | Professional Edition

USAGE:
    git copy [OPTIONS] [FILTERS] [EXCLUDES]

EXAMPLES:
    git copy                      # Copy all tracked files
    git copy js                   # Copy only .js files
    git copy web -node_modules    # Web files, excluding node_modules
    git copy --*.Tests            # Exclude files/folders matching *.Tests
    git copy -.md                 # Exclude .md extensions
"@ -ForegroundColor Cyan
    exit 0
}

function Convert-GlobToRegex {
    param([string]$Pattern)
    $safe = [regex]::Escape($Pattern)
    $safe = $safe -replace "\\\*", ".*" -replace "\\\?", "."
    return "^.*$safe.*$" 
}

# -----------------------------------------------------------------------------
# MAIN EXECUTION FLOW
# -----------------------------------------------------------------------------

# Force argument list to array to satisfy StrictMode in PS 5.1
$ArgsList = @($Arguments)

if ($Help -or ($ArgsList -contains "--help") -or ($ArgsList -contains "-h")) {
    Show-Help
}

Write-Host "Processing..." -ForegroundColor Cyan

# 1. PARSE ARGUMENTS
$TargetExtensions = [System.Collections.Generic.List[string]]::new()
$ExcludePaths     = [System.Collections.Generic.List[string]]::new()
$ExcludePatterns  = [System.Collections.Generic.List[string]]::new()

$IsFilterActive = $false
$SkipNext = $false

for ($i = 0; $i -lt $ArgsList.Count; $i++) {
    if ($SkipNext) { $SkipNext = $false; continue }
    
    $arg = $ArgsList[$i]
    
    switch -Regex ($arg) {
        # explicit --exclude flag
        "^--exclude$|^-exclude$" {
            if ($i + 1 -lt $ArgsList.Count) {
                $ExcludePaths.Add($ArgsList[$i+1].TrimStart("-"))
                $SkipNext = $true
            }
        }
        # Pattern exclusion: --*.Tests
        "^--(?!exclude)(.+)" {
            $Matches[1] | ForEach-Object { $ExcludePatterns.Add((Convert-GlobToRegex $_)) }
        }
        # Extension exclusion: -.md
        "^-\.(.+)" {
            $ExcludePatterns.Add((Convert-GlobToRegex "*.$($Matches[1])"))
        }
        # Path exclusion: -node_modules
        "^-(.+)" {
            $ExcludePaths.Add($Matches[1])
        }
        # Presets or Extensions
        default {
            $val = $arg.ToLower().TrimStart(".")
            if ($PRESETS.ContainsKey($val)) {
                $PRESETS[$val] | ForEach-Object { $TargetExtensions.Add($_) }
            } else {
                $TargetExtensions.Add($val)
            }
            $IsFilterActive = $true
        }
    }
}

# Normalize Exclude Paths
$NormalizedExcludes = [System.Collections.Generic.List[string]]::new()
foreach ($path in $ExcludePaths) {
    $clean = $path -replace '\\', '/'
    $clean = $clean -replace '^\./', ''
    $NormalizedExcludes.Add($clean)
}

# 2. FILE DISCOVERY
$RootPath = (Get-Location).Path
$RawFiles = @()

if (Test-Path ".git") {
    try {
        $GitOutput = git ls-files --cached --others --exclude-standard 2>$null
        $RawFiles = $GitOutput
    } catch {
        Write-Warning "Git command failed, falling back to file system scan."
        $RawFiles = Get-ChildItem -Recurse -File | Select-Object -ExpandProperty FullName
    }
} else {
    $RawFiles = Get-ChildItem -Recurse -File | Select-Object -ExpandProperty FullName
}

# 3. PROCESSING ENGINE
$OutputBuilder = [System.Text.StringBuilder]::new()
$StructureList = [System.Collections.Generic.List[string]]::new()
$TotalBytes = 0
$FileCount = 0

foreach ($FileEntry in $RawFiles) {
    if ([string]::IsNullOrWhiteSpace($FileEntry)) { continue }

    # Normalize Path to relative Unix-style path
    if ($FileEntry -match "^[A-Za-z]:") {
        # It's an absolute Windows path
        $RelPath = $FileEntry.Substring($RootPath.Length).Trim('\', '/')
    } else {
        # It's already relative
        $RelPath = $FileEntry.Trim()
    }
    
    $RelPath = $RelPath -replace '\\', '/'
    
    # --- FILTERS ---
    
    # 1. Regex Bans
    if ($IgnoreRegex.IsMatch($RelPath)) { continue }
    
    # 2. Security Bans
    if ($SecurityRegex.IsMatch($RelPath)) { continue }

    # 3. Path Exclusions
    $IsExcluded = $false
    foreach ($ex in $NormalizedExcludes) {
        if ($RelPath -eq $ex -or $RelPath.StartsWith("$ex/") -or $RelPath -like "*/$ex/*") {
            $IsExcluded = $true; break
        }
    }
    if ($IsExcluded) { continue }

    # 4. Pattern Exclusions
    foreach ($pat in $ExcludePatterns) {
        if ($RelPath -match $pat) { $IsExcluded = $true; break }
    }
    if ($IsExcluded) { continue }

    # 5. Extension/Preset Filter
    $Ext = [System.IO.Path]::GetExtension($RelPath).TrimStart('.')
    if ($IsFilterActive -and -not $TargetExtensions.Contains($Ext)) { continue }

    # --- CONTENT PROCESSING ---
    
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
    }
    catch {
        Write-Warning "Could not read file: $RelPath"
    }
}

# 4. GENERATE FOOTER & STATS
[void]$OutputBuilder.AppendLine("")
[void]$OutputBuilder.AppendLine("_Project Structure:_")
[void]$OutputBuilder.AppendLine("${FENCE}text")
$StructureList.Sort()
foreach ($Path in $StructureList) {
    [void]$OutputBuilder.AppendLine($Path)
}
[void]$OutputBuilder.AppendLine($FENCE)

$FinalOutput = $OutputBuilder.ToString()

# 5. CLIPBOARD & UI
try {
    Set-Clipboard -Value $FinalOutput
} catch {
    Write-Error "Failed to copy to clipboard."
    exit 1
}

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