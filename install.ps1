
# ==========================================
# Neovim Configuration Installer
# Windows 11 / PowerShell
# ==========================================

$ErrorActionPreference = "Stop"

# ------------------------------------------
# Paths
# ------------------------------------------

$SourceConfig = Join-Path $PSScriptRoot "nvim"

if (-not $env:LOCALAPPDATA) {
    Write-Error "LOCALAPPDATA is not defined."
    exit 1
}

$ConfigHome = $env:LOCALAPPDATA
$TargetConfig = Join-Path $ConfigHome "nvim"

# ------------------------------------------
# Helpers
# ------------------------------------------

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Failure {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# ------------------------------------------
# Validate source
# ------------------------------------------

if (-not (Test-Path -LiteralPath $SourceConfig -PathType Container)) {
    Write-Failure "Configuration directory not found: $SourceConfig"
    Write-Failure "Run this installer from a valid repository checkout."
    exit 1
}

Write-Info "Neovim configuration source found."

# ------------------------------------------
# Check Neovim
# ------------------------------------------

if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
    Write-Failure "Neovim is not installed or is not available in PATH."

    $Answer = Read-Host "Install Neovim using winget? [y/N]"

    if ($Answer -match '^(y|yes)$') {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Failure "winget is not available."
            exit 1
        }

        winget install --id Neovim.Neovim --exact

        if ($LASTEXITCODE -ne 0) {
            Write-Failure "Neovim installation failed."
            exit 1
        }

        Write-Info "If Neovim is still unavailable, restart PowerShell and rerun this installer."
        exit 0
    }

    Write-Failure "Neovim is required. Installation cancelled."
    exit 1
}

Write-Success "Neovim detected."

# ------------------------------------------
# Prepare installation
# ------------------------------------------

New-Item -ItemType Directory -Path $ConfigHome -Force | Out-Null

$BackupConfig = $null

if (Test-Path -LiteralPath $TargetConfig) {
    $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $BackupConfig = Join-Path $ConfigHome "nvim.backup-$Timestamp"

    while (Test-Path -LiteralPath $BackupConfig) {
        $BackupConfig = "$BackupConfig-$([guid]::NewGuid().ToString('N').Substring(0,8))"
    }

    Write-Info "Existing configuration detected."
    Write-Info "Backing it up to: $BackupConfig"

    Move-Item -LiteralPath $TargetConfig -Destination $BackupConfig
}

# ------------------------------------------
# Install configuration
# ------------------------------------------

try {
    Copy-Item -LiteralPath $SourceConfig `
        -Destination $TargetConfig `
        -Recurse -ErrorAction Stop

    Write-Success "Neovim configuration installed."
}
catch {
    Write-Failure "Configuration installation failed: $_"

    if ($BackupConfig -and (Test-Path -LiteralPath $BackupConfig)) {
        if (Test-Path -LiteralPath $TargetConfig) {
            Remove-Item -LiteralPath $TargetConfig -Recurse -Force
        }

        Move-Item -LiteralPath $BackupConfig -Destination $TargetConfig
        Write-Info "Previous configuration restored."
    }

    exit 1
}

# ------------------------------------------
# Finished
# ------------------------------------------

Write-Host ""
Write-Success "Installation complete!"
Write-Info "Configuration: $TargetConfig"

if ($BackupConfig) {
    Write-Info "Previous configuration backup: $BackupConfig"
}

Write-Info "Start Neovim with: nvim"

