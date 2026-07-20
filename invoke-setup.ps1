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

    # Build a config JSON matching the Standard preset
    $winutilConfig = @{
        WPFTweaks = @(
            "WPFTweaksActivity",
            "WPFTweaksConsumerFeatures",
            "WPFTweaksDisableExplorerAutoDiscovery",
            "WPFTweaksWPBT",
            "WPFTweaksLocation",
            "WPFTweaksServices",
            "WPFTweaksTelemetry",
            "WPFTweaksDeliveryOptimization",
            "WPFTweaksDiskCleanup",
            "WPFTweaksDeleteTempFiles",
            "WPFTweaksEndTaskOnTaskbar",
            "WPFTweaksRestorePoint"
        )
    }

    $configPath = Join-Path $env:TEMP "winutil-standard-config.json"
    $winutilConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $configPath -Encoding UTF8 -Force

    # Save WinUtil script to a temp file so it runs at true top-level scope
    # (running nested inside iex can null out WinUtil's runspace variables)
    $winutilPath = Join-Path $env:TEMP "winutil-runner.ps1"
    $winutilScript | Out-File -FilePath $winutilPath -Encoding UTF8 -Force

    Write-Host "✓ Download successful, launching WinUtil in a fresh process..." -ForegroundColor Green
    Write-Host ""

    # Run WinUtil in a separate elevated PowerShell process (not nested in iex)
    $proc = Start-Process powershell.exe -Verb RunAs -Wait -PassThru -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$winutilPath`"",
        "-Config", "`"$configPath`"",
        "-Run"
    )

    Write-Host ""
    if ($proc.ExitCode -eq 0) {
        Write-Host "✓ Chris Titus WinUtil completed successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠ WinUtil exited with code $($proc.ExitCode)" -ForegroundColor Yellow
    }
    Write-Host ""

    Remove-Item $configPath -Force -ErrorAction SilentlyContinue
    Remove-Item $winutilPath -Force -ErrorAction SilentlyContinue
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
