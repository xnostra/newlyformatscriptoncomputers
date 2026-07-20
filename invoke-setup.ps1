<#
.SYNOPSIS
    One-liner launcher for Windows Setup Script
    Downloads and executes the setup script from GitHub with a single command.

.DESCRIPTION
    This script can be run with:
    irm https://raw.githubusercontent.com/xnostra/newlyformatscriptoncomputers/main/invoke-setup.ps1 | iex

.NOTES
    Version: 1.0
    Author: Setup Team
    LastModified: 2026-07-20

.LINK
    https://github.com/xnostra/newlyformatscriptoncomputers
#>

$gitHubRawUrl = "https://raw.githubusercontent.com/xnostra/newlyformatscriptoncomputers/main/setup.ps1"

Write-Host "Windows Setup & Optimization" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# STEP 1: Run Chris Titus WinUtil Standard Preset
Write-Host "Step 1: Running Chris Titus WinUtil Standard Preset..." -ForegroundColor Yellow
Write-Host "(This will apply system debloating and optimizations)" -ForegroundColor Gray
Write-Host ""

$winutilSuccess = $false
try {
    Write-Host "Downloading WinUtil script..." -ForegroundColor Cyan
    $winutilScript = Invoke-RestMethod -Uri "https://christitus.com/win" -UseBasicParsing -ErrorAction Stop

    if ($winutilScript) {
        Write-Host "Executing WinUtil Standard preset (this may take a few minutes)..." -ForegroundColor Cyan
        & ([ScriptBlock]::Create($winutilScript)) -Preset Standard
        $winutilSuccess = $true
        Write-Host ""
        Write-Host "✓ Chris Titus WinUtil completed successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ WinUtil script download failed (empty response)" -ForegroundColor Red
    }
} catch {
    Write-Host ""
    Write-Host "✗ WinUtil failed to complete: $_" -ForegroundColor Red
    Write-Host ""
}

if (-not $winutilSuccess) {
    Write-Host "Setup stopped - WinUtil must complete successfully before proceeding." -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to close this window"
    exit 1
}

Write-Host ""
Write-Host "Step 2: Downloading and running custom setup script..." -ForegroundColor Yellow

try {
    $setupScript = Invoke-RestMethod -Uri $gitHubRawUrl -ErrorAction Stop
    Write-Host "Script downloaded successfully." -ForegroundColor Green
    Write-Host "Executing setup..." -ForegroundColor Cyan
    Write-Host ""

    # Execute the downloaded script
    Invoke-Expression $setupScript
}
catch {
    Write-Host ""
    Write-Host "ERROR: Failed to download or execute setup script" -ForegroundColor Red
    Write-Host "URL: $gitHubRawUrl" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to close this window"
    exit 1
}
