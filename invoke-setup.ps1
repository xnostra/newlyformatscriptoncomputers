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

# Keep output clean - suppress verbose module/cmdlet noise
$VerbosePreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

Write-Host "Windows Setup & Optimization" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Ensure we're running as Administrator (tweaks below write to HKLM)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    $selfCmd = "irm $($MyInvocation.MyCommand.Definition) | iex"
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-Command","irm https://raw.githubusercontent.com/xnostra/newlyformatscriptoncomputers/main/invoke-setup.ps1 | iex"
    exit 0
}

# STEP 1: Apply WinUtil "Standard" preset tweaks natively
# WinUtil's own -Preset/-Config runner crashes with a null-reference error on
# some Windows builds during "Applying tweaks". These are the exact same 12
# tweaks the Standard preset applies (from WinUtil's tweaks.json), implemented
# directly here so they always work.
Write-Host "Step 1: Applying Standard optimization tweaks..." -ForegroundColor Yellow
Write-Host "(Privacy, telemetry, and cleanup - equivalent to WinUtil Standard)" -ForegroundColor Gray
Write-Host ""

function Set-Reg {
    param([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord')
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
    } catch { }
}

function Set-Svc {
    param([string]$Name, [string]$StartupType)
    try { Set-Service -Name $Name -StartupType $StartupType -ErrorAction SilentlyContinue } catch { }
}

# 1. Activity Feed
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" 0

# 2. Consumer Features
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1

# 3. WPBT
Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" "DisableWpbtExecution" 1

# 4. Location
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" "Value" "Deny" "String"
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" "SensorPermissionState" 0
Set-Reg "HKLM:\SYSTEM\Maps" "AutoUpdateEnabled" 0
Set-Svc "lfsvc" "Disabled"

# 5. Services to Manual/Disabled
Set-Svc "CscService" "Disabled"
Set-Svc "DiagTrack" "Disabled"
Set-Svc "MapsBroker" "Manual"
Set-Svc "StorSvc" "Manual"
Set-Svc "SharedAccess" "Disabled"

# 6. Telemetry
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 0
Set-Reg "HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" "HasAccepted" 0
Set-Reg "HKCU:\Software\Microsoft\Input\TIPC" "Enabled" 0
Set-Reg "HKCU:\Software\Microsoft\InputPersonalization" "RestrictImplicitInkCollection" 1
Set-Reg "HKCU:\Software\Microsoft\InputPersonalization" "RestrictImplicitTextCollection" 1
Set-Reg "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" "HarvestContacts" 0
Set-Reg "HKCU:\Software\Microsoft\Personalization\Settings" "AcceptedPrivacyPolicy" 0
Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" 0
Set-Reg "HKCU:\Software\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" 0

# 7. Delivery Optimization
Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" 0

# 8. End Task on Taskbar
Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" "TaskbarEndTask" 1

Write-Host "  Privacy & telemetry tweaks applied" -ForegroundColor Green

# 9. Disable Explorer Auto-Discovery (flush view database)
try {
    Remove-Item -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU" -Recurse -Force -ErrorAction SilentlyContinue
} catch { }

# 10. Delete Temp Files
try {
    Remove-Item -Path "$Env:Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$Env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Temp files cleared" -ForegroundColor Green
} catch { }

# 11. Create Restore Point
try {
    Enable-ComputerRestore -Drive $Env:SystemDrive -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "Setup Restore Point" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue
    Write-Host "  System Restore Point created" -ForegroundColor Green
} catch { }

# 12. Disk Cleanup (component cleanup - runs in background)
try {
    Start-Process -FilePath "Dism.exe" -ArgumentList "/online","/Cleanup-Image","/StartComponentCleanup","/ResetBase" -WindowStyle Hidden -ErrorAction SilentlyContinue
    Write-Host "  Disk cleanup started" -ForegroundColor Green
} catch { }

Write-Host ""
Write-Host "✓ Standard tweaks applied successfully" -ForegroundColor Green
Write-Host ""

# DEBLOAT: Remove default bloatware apps (WinUtil AppxDefault list)
# Efficiency: Quick Assist, Sound Recorder & Sticky Notes are intentionally NOT
# removed here (the setup script keeps/installs them). Calculator is kept too.
Write-Host "Removing default bloatware apps..." -ForegroundColor Yellow

$appxToRemove = @(
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.GetHelp",
    "Microsoft.MicrosoftOfficeHub",
    "Clipchamp.Clipchamp",
    "Microsoft.WindowsAlarms",
    "Microsoft.Todos",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.PowerAutomateDesktop",
    "Microsoft.Windows.DevHome",
    "Microsoft.BingWeather",
    "Microsoft.StartExperiencesApp",
    "Microsoft.BingNews",
    "Microsoft.Copilot",
    "Microsoft.BingSearch"
)

foreach ($pkg in $appxToRemove) {
    try {
        Get-AppxPackage -AllUsers -Name $pkg -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue -Verbose:$false 4>$null
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue -Verbose:$false | Where-Object { $_.DisplayName -eq $pkg } | ForEach-Object {
            Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue -Verbose:$false 4>$null | Out-Null
        }
    } catch { }
}

Write-Host "✓ Bloatware removal complete" -ForegroundColor Green
Write-Host ""

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
