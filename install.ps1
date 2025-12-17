<#
.SYNOPSIS
    GIT-COPY | v16.1 | Unity Edition (Windows Port)
    Bundles code files into a single Markdown snippet and copies to clipboard.

.DESCRIPTION
    Scans the current directory (using git or filesystem), filters by extensions 
    or presets, ignores binaries/secrets, and puts the content in the clipboard.
#>

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ArgsList
)

$ErrorActionPreference = "Stop"
# Ensure we output UTF8 so special characters don't break downstream tools
$OutputEncoding = [System.Text.Encoding]::UTF8

# --- CONFIG ---
$MaxSize = 1MB

# --- PRESETS (Mapped from original Perl) ---
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

# --- IGNORE LIST (Regex) ---
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
    # Use Git
    try {
        $GitOutput = git ls-files --cached --others --exclude-standard 2>$null
        $AllFiles = $GitOutput | ForEach-Object { $_.Trim() }
    } catch {
        # Fallback
        $AllFiles = Get-ChildItem -Recurse -File | ForEach-Object { $_.FullName.Substring($RootPath.Path.Length + 1) }
    }
} else {
    # Native Recursive Search
    $AllFiles = Get-ChildItem -Recurse -File | ForEach-Object { $_.FullName.Substring($RootPath.Path.Length + 1) }
}

# --- 2. FILTER ARGUMENTS ---
$FilterExtensions = @()
$FilterActive = $false

if ($ArgsList.Count -gt 0) {
    $FilterActive = $true
    foreach ($arg in $ArgsList) {
        $arg = $arg.ToLower()
        if ($Presets.ContainsKey($arg)) {
            $FilterExtensions += $Presets[$arg]
        } else {
            $FilterExtensions += $arg -replace "^\.", ""
        }
    }
}

# --- 3. PROCESSING ENGINE ---
$ResultBuilder = [System.Text.StringBuilder]::new()
$ProcessedFiles = @()
$TotalBytes = 0
$Count = 0

foreach ($RelPath in $AllFiles) {
    # Fix slashes for Windows
    $RelPath = $RelPath -replace "/", "\"
    $FullPath = Join-Path $RootPath $RelPath
    $FileInfo = Get-Item $FullPath -ErrorAction SilentlyContinue

    if (-not $FileInfo) { continue }

    # Checks
    if ($RelPath -match $IgnoreRegex) { continue }
    if ($RelPath -match $SecurityRegex) { continue }
    
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
        
        # FIX: Use Single Quotes for ``` to avoid backtick escaping the closing quote
        [void]$ResultBuilder.AppendLine('```' + $Lang)
        [void]$ResultBuilder.AppendLine($Content)
        [void]$ResultBuilder.AppendLine('```') 
        [void]$ResultBuilder.AppendLine("")

        $ProcessedFiles += $RelPath
        $TotalBytes += $FileInfo.Length
        $Count++
    }
    catch {
        continue
    }
}

# --- 4. FOOTER ---
[void]$ResultBuilder.AppendLine("")
[void]$ResultBuilder.AppendLine("_Project Structure:_")
[void]$ResultBuilder.AppendLine("```text")
$ProcessedFiles | Sort-Object | ForEach-Object {
    [void]$ResultBuilder.AppendLine($_)
}
[void]$ResultBuilder.AppendLine("```")

# --- 5. STATS & CLIPBOARD ---
$FinalString = $ResultBuilder.ToString()
Set-Clipboard -Value $FinalString

$Tokens = [math]::Truncate($TotalBytes / 4)
$HumanSize = ""
if ($TotalBytes -lt 1KB) { $HumanSize = "{0} B" -f $TotalBytes }
elseif ($TotalBytes -lt 1MB) { $HumanSize = "{0:N2} KB" -f ($TotalBytes / 1KB) }
else { $HumanSize = "{0:N2} MB" -f ($TotalBytes / 1MB) }

# Visual Output
# Use [Console]::OutputEncoding to ensure symbols don't crash legacy consoles
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "[OK]" -NoNewline -ForegroundColor Green
Write-Host " Copied: " -NoNewline -ForegroundColor Green
Write-Host "$Count" -NoNewline -ForegroundColor White
Write-Host " files | Size: " -NoNewline -ForegroundColor Green
Write-Host "$HumanSize" -NoNewline -ForegroundColor White
Write-Host " | Tokens: " -NoNewline -ForegroundColor Green
Write-Host "~$Tokens" -ForegroundColor White