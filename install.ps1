<#
.SYNOPSIS
    GIT-COPY Installer v16.2 - Windows Edition

.DESCRIPTION
    Installs git-copy as a PowerShell script with batch wrapper to bypass
    ExecutionPolicy restrictions. Adds to user PATH automatically.

.PARAMETER Help
    Show help information

.PARAMETER Version
    Show version information

.PARAMETER DryRun
    Show what would be installed without installing

.EXAMPLE
    .\install.ps1
    Installs git-copy to default location

.EXAMPLE
    .\install.ps1 -DryRun
    Shows installation path without installing

.NOTES
    Version: 16.2
    Author: Md. Ishtiaq Ahamed Fahim
#>

[CmdletBinding()]
param(
    [Alias("h")]
    [switch]$Help,

    [Alias("v")]
    [switch]$Version,

    [switch]$DryRun
)

# ==============================================================================
# CONFIGURATION
# ==============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

[Version]$ScriptVersion = "16.2"
$ToolName = "git-copy"
$InstallDir = "$env:LOCALAPPDATA\Programs\$ToolName"
$SourceUrl = "https://raw.githubusercontent.com/iafahim/git-copy/main/git-copy.ps1"

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
# MAIN INSTALLATION
# ==============================================================================

try {
    Write-Info "Installing GIT-COPY v$ScriptVersion (Windows Edition)"

    # ==============================================================================
    # CREATE DIRECTORY
    # ==============================================================================

    if (-not (Test-Path $InstallDir)) {
        if ($DryRun) {
            Write-Info "Would create directory: $InstallDir"
        } else {
            New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
        }
    }

    # ==============================================================================
    # CREATE BATCH WRAPPER
    # ==============================================================================
    # This .cmd file allows running the tool without changing system-wide ExecutionPolicy

    $BatchContent = @"
@ECHO OFF
SETLOCAL
SET "dp0=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%dp0%git-copy.ps1" %*
"@

    if ($DryRun) {
        Write-Info "Would create: $InstallDir\$ToolName.cmd"
    } else {
        $BatchContent | Set-Content -Path "$InstallDir\$ToolName.cmd" -Encoding ASCII
    }

    # ==============================================================================
    # DOWNLOAD LOGIC SCRIPT
    # ==============================================================================

    Write-Info "Downloading script..."
    if ($DryRun) {
        Write-Info "Would download from: $SourceUrl"
        Write-Info "Would save to: $InstallDir\$ToolName.ps1"
    } else {
        Invoke-WebRequest -Uri $SourceUrl -OutFile "$InstallDir\$ToolName.ps1"
    }

    # ==============================================================================
    # UPDATE PATH
    # ==============================================================================

    $CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($CurrentPath -notlike "*$InstallDir*") {
        Write-Info "Adding to PATH..."
        if (-not $DryRun) {
            [Environment]::SetEnvironmentVariable("Path", "$CurrentPath;$InstallDir", "User")
            $Env:Path += ";$InstallDir"
        }
        Write-Success "Added to PATH"
    } else {
        Write-Success "Already in PATH"
    }

    # ==============================================================================
    # COMPLETE
    # ==============================================================================

    Write-Host ""
    Write-Success "Installation complete!"
    Write-Host "You can now open a NEW terminal window and type:" -ForegroundColor White
    Write-Host "   git copy" -ForegroundColor Yellow
}
catch {
    Write-Error "Installation failed: $_"
    exit 1
}
finally {
    # Cleanup if needed
}