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

try {
    & ([ScriptBlock]::Create((Invoke-RestMethod -Uri "https://christitus.com/win" -UseBasicParsing))) -Preset Standard
    Write-Host ""
    Write-Host "✓ Chris Titus WinUtil completed" -ForegroundColor Green
} catch {
    Write-Host "⚠ WinUtil encountered an issue: $_" -ForegroundColor Yellow
    Write-Host "Continuing with remaining setup..." -ForegroundColor Yellow
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
    Write-Host "ERROR: Failed to download or execute setup script" -ForegroundColor Red
    Write-Host "URL: $gitHubRawUrl" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}
