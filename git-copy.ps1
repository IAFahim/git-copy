<#
.SYNOPSIS
    GIT-COPY | v16.2 | Professional Edition

.DESCRIPTION
    Bundles code files into a single Markdown snippet and copies to clipboard.
    Supports filtering by extension/preset and exclusion of folders.
    Uses native PowerShell wildcards for robust filtering.

.PARAMETER Arguments
    File extensions, presets, or exclusion patterns

.PARAMETER Help
    Show help information

.EXAMPLE
    git copy
    Copy all tracked files

.EXAMPLE
    git copy js ts -tests
    Copy JS/TS files, exclude tests folder

.EXAMPLE
    git copy web --exclude node_modules
    Copy web files, exclude node_modules

.NOTES
    Version: 16.2
    Presets: web, backend, dotnet, unity, java, cpp, script, data, config, docs
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments = @(),

    [Alias("h")]
    [switch]$Help
)

# ==============================================================================
# CONFIGURATION
# ==============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
# Force UTF-8 Output
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

[Version]$ScriptVersion = "16.2"
$MAX_SIZE = 1MB
$FENCE = '```'

# ==============================================================================
# LOGGING FUNCTIONS
# ==============================================================================

function Write-Info {
    [CmdletBinding()]
    param([string]$Message)
    Write-Host "ℹ " -NoNewline -ForegroundColor Cyan
    Write-Host $Message
}

function Write-Success {
    [CmdletBinding()]
    param([string]$Message)
    Write-Host "✔ " -NoNewline -ForegroundColor Green
    Write-Host $Message
}

function Write-Warn {
    [CmdletBinding()]
    param([string]$Message)
    Write-Host "⚠ " -NoNewline -ForegroundColor Yellow
    Write-Host $Message
}

function Write-Error {
    [CmdletBinding()]
    param([string]$Message)
    Write-Host "✘ " -NoNewline -ForegroundColor Red
    Write-Host $Message
}

# ==============================================================================
# PRESETS & LANGUAGE MAPS
# ============================================================================== 

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
    "uss" = "css"; "uxml" = "xml"; "ps1" = "powershell";
    "dockerfile" = "dockerfile"; "makefile" = "makefile";
    "gemfile" = "ruby"; "rakefile" = "ruby"
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

$ArgsList = @($Arguments)

if ($Help -or ($ArgsList -contains "--help") -or ($ArgsList -contains "-h")) {
    Write-Host "GIT-COPY | v$ScriptVersion" -ForegroundColor Cyan
    exit 0
}

Write-Host "Processing..." -ForegroundColor Cyan

# ==============================================================================
# ARGUMENT PARSING
# ==============================================================================
$TargetExtensions = [System.Collections.Generic.List[string]]::new()
$ExcludePatterns  = [System.Collections.Generic.List[string]]::new()

$SkipNext = $false
for ($i = 0; $i -lt $ArgsList.Count; $i++) {
    if ($SkipNext) { $SkipNext = $false; continue }
    $arg = $ArgsList[$i]
    
    # CASE 1: Explicit --exclude (Standard)
    if ($arg -eq "--exclude" -or $arg -eq "-exclude") {
        if ($i + 1 -lt $ArgsList.Count) {
            $path = $ArgsList[$i+1].TrimStart("-")
            $path = $path -replace '\\', '/'
            $ExcludePatterns.Add($path)
            $SkipNext = $true
        }
        continue
    }

    # CASE 2: Pattern Exclusion (--*.Tests)
    # This covers --Folder, --*.cs, --node_modules, etc.
    if ($arg.StartsWith("--")) {
        $pat = $arg.Substring(2) # Strip leading --
        if (-not [string]::IsNullOrWhiteSpace($pat)) {
            $ExcludePatterns.Add($pat)
            Write-Host "  > Exclude Pattern: '$pat'" -ForegroundColor DarkGray
        }
        continue
    }

    # CASE 3: Extension Exclusion (-.md)
    if ($arg.StartsWith("-.")) {
        $ext = $arg.Substring(2) # Strip leading -.
        if (-not [string]::IsNullOrWhiteSpace($ext)) {
            $ExcludePatterns.Add("*.$ext")
            Write-Host "  > Exclude Ext: '$ext'" -ForegroundColor DarkGray
        }
        continue
    }

    # CASE 4: Old Style Path Exclusion (-node_modules)
    if ($arg.StartsWith("-")) {
        $path = $arg.Substring(1) # Strip leading -
        if (-not [string]::IsNullOrWhiteSpace($path)) {
            $path = $path -replace '\\', '/'
            $ExcludePatterns.Add($path)
            Write-Host "  > Exclude Path: '$path'" -ForegroundColor DarkGray
        }
        continue
    }

    # CASE 5: Presets/Extensions
    $val = $arg.ToLower().TrimStart(".")
    if ($PRESETS.ContainsKey($val)) {
        $PRESETS[$val] | ForEach-Object { $TargetExtensions.Add($_) }
    } else {
        $TargetExtensions.Add($val)
    }
}

# ==============================================================================
# FILE DISCOVERY
# ==============================================================================

$RootPath = (Get-Location).Path.TrimEnd('\', '/')
$RawFiles = @()

if (Test-Path ".git") {
    $GitOut = git ls-files --cached --others --exclude-standard 2>$null
    if ($null -ne $GitOut) { $RawFiles = @($GitOut) }
    else { $RawFiles = Get-ChildItem -Recurse -File | Select-Object -ExpandProperty FullName }
} else {
    $RawFiles = Get-ChildItem -Recurse -File | Select-Object -ExpandProperty FullName
}

# ==============================================================================
# FILE PROCESSING
# ==============================================================================

$OutputBuilder = [System.Text.StringBuilder]::new()
$StructureList = [System.Collections.Generic.List[string]]::new()
$TotalBytes = 0
$FileCount = 0
$IsFilterActive = $TargetExtensions.Count -gt 0

# Security / Garbage Regex (Keep this for safety/noise)
$RegexOpts = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
$IgnoreRe = [regex]::new("(node_modules/|bin/|obj/|package-lock\.json|yarn\.lock|Cargo\.lock|\.DS_Store|Thumbs\.db|\.git/|\.png$|\.jpg$|\.jpeg$|\.gif$|\.ico$|\.woff2?$|\.pdf$|\.exe$|\.bin$|\.pyc$|\.dll$|\.pdb$|\.min\.js$|\.min\.css$|\.meta$)", $RegexOpts)
$SecRe = [regex]::new("(id_rsa|id_dsa|\.pem|\.key|\.p12|\.env|secrets|credentials)", $RegexOpts)

foreach ($FileEntry in $RawFiles) {
    if ([string]::IsNullOrWhiteSpace($FileEntry)) { continue }

    # Path Normalization
    # Check if file entry starts with RootPath (for both Windows and Unix paths)
    if ($FileEntry.StartsWith($RootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        $RelPath = $FileEntry.Substring($RootPath.Length).Trim('\', '/')
    } else {
        $RelPath = $FileEntry.Trim()
    }
    $RelPath = $RelPath -replace '\\', '/'

    # --- FILTERS ---
    
    # 1. Base Ignorables
    if ($IgnoreRe.IsMatch($RelPath)) { continue }
    if ($SecRe.IsMatch($RelPath)) { continue }

    # 2. User Exclusions
    $IsExcluded = $false
    $PathSegments = $RelPath -split '/'
    
    # DEBUG LOGGING (Conditional)
    if ($ExcludePatterns.Count -gt 0 -and ($RelPath -match "Test" -or $RelPath -match "node_modules")) {
         Write-Host "DEBUG: Checking '$RelPath' (Segments: $($PathSegments -join ','))" -ForegroundColor Gray
    }

    foreach ($pat in $ExcludePatterns) {
        # 1. Full Path Check
        if ($RelPath -like $pat -or $RelPath -like "$pat/*") {
            $IsExcluded = $true
            Write-Host "  > EXCLUDED by FullPath match: '$pat'" -ForegroundColor Yellow
            break
        }

        # 2. Segment Check
        foreach ($seg in $PathSegments) {
            # STRICT MATCH
            if ($seg -like $pat) {
                $IsExcluded = $true
                Write-Host "  > EXCLUDED by Segment Strict match: '$seg' -like '$pat'" -ForegroundColor Yellow
                break
            }
            # FUZZY/CONTAINMENT MATCH
            if ($seg -like "*$pat*") {
                 $IsExcluded = $true
                 Write-Host "  > EXCLUDED by Segment Fuzzy match: '$seg' -like '*$pat*'" -ForegroundColor Yellow
                 break
            }
        }
        if ($IsExcluded) { break }
    }
    if ($IsExcluded) { continue }

    # 3. Extension Filter
    $Ext = [System.IO.Path]::GetExtension($RelPath).TrimStart('.')
    $FileName = [System.IO.Path]::GetFileName($RelPath)

    if ($IsFilterActive) {
        # Check either extension OR filename (for files like Dockerfile, Makefile)
        $Matched = $TargetExtensions.Contains($Ext) -or $TargetExtensions.Contains($FileName.ToLower())
        if (-not $Matched) { continue }
    }

    # --- CONTENT ---
    $FullPath = Join-Path $RootPath $RelPath
    $FileInfo = Get-Item $FullPath -ErrorAction SilentlyContinue
    if (-not $FileInfo -or $FileInfo.Length -gt $MAX_SIZE -or $FileInfo.Length -eq 0) { continue }

    try {
        # Determine language: check extension first, then filename for files without extensions
        $LangKey = if ($Ext) { $Ext.ToLower() } else { $FileName.ToLower() }
        $Lang = if ($LANG_MAP.ContainsKey($LangKey)) { $LANG_MAP[$LangKey] } else { $LangKey }
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

# ==============================================================================
# OUTPUT
# ==============================================================================

[void]$OutputBuilder.AppendLine("")
[void]$OutputBuilder.AppendLine("_Project Structure:_")
[void]$OutputBuilder.AppendLine("${FENCE}text")
$StructureList.Sort()
foreach ($Path in $StructureList) { [void]$OutputBuilder.AppendLine($Path) }
[void]$OutputBuilder.AppendLine($FENCE)

$FinalOutput = $OutputBuilder.ToString()

# Cross-platform clipboard support
function Set-ClipboardCrossPlatform {
    param([string]$Value)

    $IsLinuxOS = $PSVersionTable.Platform -eq 'Unix'
    $IsWindowsOS = $PSVersionTable.Platform -eq 'Win32NT' -or $null -eq $PSVersionTable.Platform

    # Check if there's a mocked Set-Clipboard (for testing)
    $MockedClipboard = Get-Command Set-Clipboard -Scope Global -ErrorAction SilentlyContinue

    if ($IsWindowsOS -or $MockedClipboard) {
        Set-Clipboard -Value $Value
    }
    elseif ($IsLinuxOS) {
        # Try Wayland clipboard first, then X11
        $WaylandCopy = Get-Command wl-copy -ErrorAction SilentlyContinue
        $XClip = Get-Command xclip -ErrorAction SilentlyContinue

        $CopySuccess = $false
        if ($WaylandCopy) {
            try {
                $Value | wl-copy
                $CopySuccess = $true
            } catch {
                # Fall through to xclip
            }
        }

        if (-not $CopySuccess -and $XClip) {
            try {
                $Value | xclip -selection clipboard 2>$null
                $CopySuccess = $true
            } catch {
                Write-Error "Failed to set clipboard with xclip: $_"
                exit 1
            }
        }

        if (-not $CopySuccess) {
            Write-Error "No clipboard tool found. Please install xclip or wl-copy."
            exit 1
        }
    }
}

try {
    Set-ClipboardCrossPlatform -Value $FinalOutput
} catch {
    Write-Error "Failed to set clipboard: $_"
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