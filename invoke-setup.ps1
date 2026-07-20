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

# STEP 1: Run Chris Titus WinUtil Standard Preset (MUST complete first)
Write-Host "Step 1: Chris Titus WinUtil Standard Preset" -ForegroundColor Yellow
Write-Host "(System debloating and optimization)" -ForegroundColor Gray
Write-Host ""

try {
    Write-Host "Downloading WinUtil from https://christitus.com/win..." -ForegroundColor Cyan
    $winutilScript = Invoke-RestMethod -Uri "https://christitus.com/win" -UseBasicParsing -ErrorAction Stop

    if ([string]::IsNullOrEmpty($winutilScript)) {
        throw "WinUtil script is empty"
    }

    Write-Host "✓ Download successful, executing preset..." -ForegroundColor Green
    Write-Host ""

    # Run WinUtil with Standard preset
    & ([ScriptBlock]::Create($winutilScript)) -Preset Standard

    Write-Host ""
    Write-Host "✓ Chris Titus WinUtil completed successfully" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "✗ WinUtil failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to close (setup cannot continue without WinUtil)"
    exit 1
}

Write-Host "Step 2: Downloading custom setup script..." -ForegroundColor Yellow

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
