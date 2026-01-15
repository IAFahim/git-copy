<#
.SYNOPSIS
    GIT-COPY | v16.2 | Cross-Platform Edition (Windows Port)
    Bundles code files into a single Markdown snippet and copies to clipboard.
#>

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ArgsList,

    [switch]$Help
)

$ErrorActionPreference = "Stop"
# Force UTF8 to prevent console crashes on special chars
$OutputEncoding = [System.Text.Encoding]::UTF8

# Initialize variables that were previously parameters
$ExcludePaths = @()
$ExcludePatterns = @()

if ($Help -or $ArgsList -contains "--help" -or $ArgsList -contains "-h") {
    Write-Host @"

GIT-COPY | v16.2 | Cross-Platform Edition

USAGE:
    git copy [OPTIONS] [FILTERS] [EXCLUDES]

OPTIONS:
    --help, -h          Show this help message

FILTERS:
    <extension>         Copy only files with specified extensions (e.g., js py)
    <preset>            Use predefined filter preset

PRESETS:
    web                 html, css, js, ts, jsx, tsx, json, svg, vue, svelte
    backend             py, rb, php, go, rs, java, cs, cpp, swift, kt
    dotnet              cs, razor, csproj, json, http, xaml
    unity               cs, shader, glsl, asmdef, uss, uxml, json, yaml
    java                java, kt, scala
    cpp                 c, h, cpp, hpp, rs, go, swift
    script              py, rb, php, lua, sh, ps1
    data                sql, xml, json, yaml, toml, md, csv
    config              env, conf, ini, Dockerfile, Makefile
    docs                md, txt, rst, adoc

EXCLUDES:
    -<path>             Exclude folder or path (e.g., -node_modules -tests)
                        Note: Use quotes for paths with spaces (e.g., -"my folder")
    --exclude <path>    Alternative exclude syntax

PATTERN EXCLUDES:
    --<pattern>         Exclude folders/files matching wildcard pattern
                        Examples: --*.Tests --test* --*.tmp
                        Matches: MyApp.Tests/, test.cs, test_backup/, file.tmp
    -.extension         Exclude files by extension (e.g., -.md -.log)
                        Note: Use quotes for patterns with spaces (e.g., --"test *")

EXAMPLES:
    git copy                              Copy all tracked files
    git copy js                           Copy only .js files
    git copy web                          Copy all web-related files
    git copy -node_modules                Exclude node_modules folder
    git copy js -tests                    Copy .js files, exclude tests folder
    git copy web -dist -build             Copy web files, exclude build folders
    git copy --exclude src/legacy         Exclude specific path
    git copy --*.Tests                    Exclude all .Tests folders/files
    git copy -.md                         Exclude all markdown files
    git copy --test* -*.tmp               Exclude test* folders and *.tmp files

"@ -ForegroundColor Cyan
    exit 0
}

# --- CONFIG ---
$MaxSize = 1MB
# FIX: Define fence as variable to stop parser errors with backticks
$Fence = '```'

# --- PRESETS ---
$Presets = @{
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

# --- IGNORE LIST ---
$IgnoreRegex = "(?i)(package-lock\.json|yarn\.lock|Cargo\.lock|\.DS_Store|Thumbs\.db|\.git\\|\.png$|\.jpg$|\.jpeg$|\.gif$|\.ico$|\.woff2?$|\.pdf$|\.exe$|\.bin$|\.pyc$|\.dll$|\.pdb$|\.min\.js$|\.min\.css$|\.meta$)"
$SecurityRegex = "(?i)(id_rsa|id_dsa|\.pem|\.key|\.p12|\.env|secrets|credentials)"

# --- LANGUAGE MAP ---
$LangMap = @{
    "js" = "javascript"; "ts" = "typescript"; "py" = "python";
    "cs" = "csharp"; "sh" = "bash"; "md" = "markdown";
    "h" = "c"; "hpp" = "cpp"; "razor" = "html"; "vue" = "html";
    "shader" = "glsl"; "cginc" = "glsl"; "hlsl" = "glsl"; "uss" = "css"; "uxml" = "xml";
    "ps1" = "powershell"
}

Write-Host "Processing..." -ForegroundColor Cyan

# --- 1. DISCOVERY ---
$RootPath = Get-Location
$AllFiles = @()

if (Test-Path ".git") {
    try {
        $GitOutput = git ls-files --cached --others --exclude-standard 2>$null
        $AllFiles = $GitOutput | ForEach-Object { $_.Trim() }
    } catch {
        $AllFiles = Get-ChildItem -Recurse -File | ForEach-Object { $_.FullName.Substring($RootPath.Path.Length + 1) }
    }
} else {
    $AllFiles = Get-ChildItem -Recurse -File | ForEach-Object { $_.FullName.Substring($RootPath.Path.Length + 1) }
}

# --- 2. FILTER ARGUMENTS ---
$FilterExtensions = @()
$FilterActive = $false
$ExcludeActive = $ExcludePaths.Count -gt 0
$PatternActive = $false

if ($ArgsList.Count -gt 0) {
    for ($i = 0; $i -lt $ArgsList.Count; $i++) {
        $arg = $ArgsList[$i]

        # Check for --exclude flag (consume next arg)
        if ($arg -eq "--exclude" -or $arg -eq "-exclude") {
            if ($i + 1 -lt $ArgsList.Count) {
                $ExcludePaths += $ArgsList[++$i]
                $ExcludeActive = $true
            }
            continue
        }

        # Check if it's a pattern (starts with --)
        if ($arg -match "^--") {
            # Match Bash behavior: remove leading --
            $pattern = $arg -replace "^--", ""
            if ($pattern.Trim() -ne "") {
                $ExcludePatterns += $pattern
                $PatternActive = $true
            }
            continue
        }

        # Check if it's an extension exclusion (starts with -. )
        if ($arg -match "^-\.") {
            # Match Bash behavior: remove leading -.
            $ext = $arg -replace "^-\.", ""
            $ExcludePatterns += "*.$ext"
            $PatternActive = $true
            continue
        }

        # Check if it's an exclude path (starts with - but not -.)
        if ($arg -match "^-") {
            $path = $arg -replace "^-", ""
            $ExcludePaths += $path
            $ExcludeActive = $true
            continue
        }

        $arg = $arg.ToLower()
        if ($Presets.ContainsKey($arg)) {
            $FilterExtensions += $Presets[$arg]
            $FilterActive = $true
        } else {
            $FilterExtensions += $arg -replace "^\.", ""
            $FilterActive = $true
        }
    }
}

# Normalize exclude paths
$NormalizedExcludes = @()
foreach ($path in $ExcludePaths) {
    $normalized = $path -replace '\\', '/'
    $normalized = $normalized.TrimStart('./')
    $NormalizedExcludes += $normalized
}

# --- 3. PROCESSING ENGINE ---
$ResultBuilder = [System.Text.StringBuilder]::new()
$ProcessedFiles = @()
$TotalBytes = 0
$Count = 0

foreach ($RelPath in $AllFiles) {
    # Normalize slashes to forward slash for consistency
    $RelPath = $RelPath -replace '\\', '/'
    $FullPath = Join-Path $RootPath $RelPath
    $FileInfo = Get-Item $FullPath -ErrorAction SilentlyContinue

    if (-not $FileInfo) { continue }

    if ($RelPath -match $IgnoreRegex) { continue }
    if ($RelPath -match $SecurityRegex) { continue }
    
    # Check exclude paths
    if ($ExcludeActive) {
        $shouldExclude = $false
        foreach ($excludePath in $NormalizedExcludes) {
            # Normalize exclude path too
            $excludePath = $excludePath -replace '\\', '/'
            if ($RelPath -like "$excludePath*" -or $RelPath -like "*/$excludePath/*" -or $RelPath -eq $excludePath) {
                $shouldExclude = $true
                break
            }
        }
        if ($shouldExclude) { continue }
    }

    # Check pattern excludes (wildcard matching on folder/file names)
    if ($PatternActive) {
        $shouldExclude = $false
        foreach ($pattern in $ExcludePatterns) {
            # Convert wildcard pattern to regex
            # 1. Escape special regex characters (dots, brackets, etc.)
            $safe = [regex]::Escape($pattern)
            # 2. Convert escaped wildcards back to regex wildcards
            #    \* -> .* (match any sequence)
            #    \? -> .  (match any single char)
            $regexPattern = $safe -replace "\\\*", ".*" -replace "\\\?", "."

            # Get all path segments (folders and file)
            $pathSegments = $RelPath -split '/'
            $matched = $false

            foreach ($segment in $pathSegments) {
                if ($segment -match $regexPattern) {
                    $matched = $true
                    break
                }
            }

            if ($matched) {
                $shouldExclude = $true
                break
            }
        }
        if ($shouldExclude) { continue }
    }
    
    $Ext = $FileInfo.Extension -replace "^\.", ""
    if ($FilterActive) {
        if ($FilterExtensions -notcontains $Ext) { continue }
    }

    if ($FileInfo.Length -gt $MaxSize -or $FileInfo.Length -eq 0) { continue }

    $Lang = $Ext
    if ($LangMap.ContainsKey($Lang.ToLower())) { $Lang = $LangMap[$Lang.ToLower()] }

    # --- READ CONTENT ---
    try {
        $Content = Get-Content -LiteralPath $FullPath -Raw -ErrorAction Stop
        
        # Build Output
        [void]$ResultBuilder.AppendLine("## File: $RelPath")
        
        # FIX: Use variable for code fence to avoid parser confusion
        [void]$ResultBuilder.AppendLine("$Fence$Lang")
        [void]$ResultBuilder.AppendLine($Content)
        [void]$ResultBuilder.AppendLine($Fence)
        [void]$ResultBuilder.AppendLine("")

        $ProcessedFiles += $RelPath
        $TotalBytes += $FileInfo.Length
        $Count++
    }
    catch { continue }
}

# --- 4. FOOTER ---
[void]$ResultBuilder.AppendLine("")
[void]$ResultBuilder.AppendLine("_Project Structure:_")
[void]$ResultBuilder.AppendLine("${Fence}text")
$ProcessedFiles | Sort-Object | ForEach-Object {
    [void]$ResultBuilder.AppendLine($_)
}
[void]$ResultBuilder.AppendLine($Fence)

# --- 5. STATS & CLIPBOARD ---
$FinalString = $ResultBuilder.ToString()
Set-Clipboard -Value $FinalString

# Tokens calc
$Tokens = [math]::Truncate($TotalBytes / 4)

# Human Readable Size
# FIX: Use Single Quotes here to prevent 'Unexpected token' errors
$HumanSize = ""
if ($TotalBytes -lt 1KB) { $HumanSize = '{0} B' -f $TotalBytes }
elseif ($TotalBytes -lt 1MB) { $HumanSize = '{0:N2} KB' -f ($TotalBytes / 1KB) }
else { $HumanSize = '{0:N2} MB' -f ($TotalBytes / 1MB) }

# Visual Output
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "[OK]" -NoNewline -ForegroundColor Green
Write-Host " Copied: " -NoNewline -ForegroundColor Green
Write-Host "$Count" -NoNewline -ForegroundColor White
Write-Host " files | Size: " -NoNewline -ForegroundColor Green
Write-Host "$HumanSize" -NoNewline -ForegroundColor White
Write-Host " | Tokens: " -NoNewline -ForegroundColor Green
Write-Host "~$Tokens" -ForegroundColor White