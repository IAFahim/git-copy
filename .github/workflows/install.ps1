<#
.SYNOPSIS
    GIT-COPY INSTALLER (Windows)
    Installs git-copy, creates a command wrapper to bypass ExecutionPolicy, 
    and adds it to the user PATH.
#>

$ErrorActionPreference = "Stop"
$ToolName = "git-copy"
$InstallDir = "$env:LOCALAPPDATA\Programs\$ToolName"
$SourceUrl = "https://raw.githubusercontent.com/iafahim/git-copy/main/git-copy.ps1" 
# NOTE: You need to rename your logic file to 'git-copy.ps1' in your repo for the line above to work.
# If you want to embed the script inside this installer instead of downloading it, let me know.

Write-Host ">> INSTALLING GIT-COPY (Windows Edition) <<" -ForegroundColor Magenta

# 1. Create Directory
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

# 2. Create the Batch Wrapper (The Secret Sauce)
# This .cmd file allows running the tool without changing system-wide ExecutionPolicy
$BatchContent = @"
@ECHO OFF
SETLOCAL
SET "dp0=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%dp0%git-copy.ps1" %*
"@
$BatchContent | Set-Content -Path "$InstallDir\$ToolName.cmd" -Encoding ASCII

# 3. Download the Logic Script
# (Assuming you host the logic script as git-copy.ps1 in your repo)
Write-Host "Downloading script..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $SourceUrl -OutFile "$InstallDir\$ToolName.ps1"

# 4. Update PATH
$CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($CurrentPath -notlike "*$InstallDir*") {
    Write-Host "Adding to PATH..." -ForegroundColor Cyan
    [Environment]::SetEnvironmentVariable("Path", "$CurrentPath;$InstallDir", "User")
    $Env:Path += ";$InstallDir"
    Write-Host "✔ Added to PATH." -ForegroundColor Green
} else {
    Write-Host "✔ Already in PATH." -ForegroundColor Green
}

Write-Host ""
Write-Host "SUCCESS!" -ForegroundColor Green
Write-Host "You can now open a NEW terminal window and type:" -ForegroundColor White
Write-Host "   git copy" -ForegroundColor Yellow