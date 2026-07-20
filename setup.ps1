<#
.SYNOPSIS
    Comprehensive Windows Setup & Optimization Script
    Configures fresh Windows installations with system tweaks, debloating, and software installation.

.DESCRIPTION
    This script performs a complete Windows setup including:
    - System optimization (UAC, VSS, power settings)
    - Regional configuration (timezone, locale, paper size)
    - Application debloating and selective reinstallation
    - Microsoft 365 Apps installation
    - Third-party software installation (Chrome, WinRAR)
    - Delivery Optimization configuration
    - Automatic post-update fixup task scheduling
    - Optional Microsoft Entra ID enrollment

.PARAMETER SkipEntraPrompt
    If specified, skips the interactive Microsoft Entra ID prompt.

.PARAMETER LogPath
    Path to save execution logs. Defaults to C:\ProgramData\WinUtilSetup\setup.log

.EXAMPLE
    # Run interactively with all prompts
    .\setup.ps1

    # Run without Entra ID prompt
    .\setup.ps1 -SkipEntraPrompt

.NOTES
    Author: Setup Team
    Version: 2.0
    Requires: Windows 10/11, Administrator privileges
    LastModified: 2026-07-20

.LINK
    https://github.com/xnostra/newlyformatscriptoncomputers

#>

[CmdletBinding()]
param(
    [switch]$SkipEntraPrompt,
    [string]$LogPath = "C:\ProgramData\WinUtilSetup\setup.log"
)

# ============================================================
#  CONFIGURATION & CONSTANTS
# ============================================================

# Continue (not Stop): a single non-critical failure must never abort/crash the whole setup.
$ErrorActionPreference = "Continue"
$VerbosePreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

$setupConfig = @{
    InstallDir          = "C:\ProgramData\WinUtilSetup"
    ScriptName          = "setup.ps1"
    ScheduledTaskName   = "WinUtil Post-Update Fixup"
    Timezone            = "Arab Standard Time"  # UTC+03:00 (Qatar)
    DateFormat          = "dd-MM-yyyy"
    PaperSize           = 9                       # 9 = A4
    VSSMaxSize          = "5GB"
    DisplayTimeout_AC   = 60                      # minutes (plugged in)
    DisplayTimeout_DC   = 15                      # minutes (battery)
    StandbyTimeout_AC   = 0                       # 0 = never sleep (plugged in)
    StandbyTimeout_DC   = 30                      # minutes (battery)
}

# ============================================================
#  LOGGING FUNCTION
# ============================================================

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Console output with colors
    switch ($Level) {
        'Info'    { Write-Host $logEntry -ForegroundColor White }
        'Warning' { Write-Host $logEntry -ForegroundColor Yellow }
        'Error'   { Write-Host $logEntry -ForegroundColor Red }
        'Success' { Write-Host $logEntry -ForegroundColor Green }
    }

    # File logging
    Add-Content -Path $LogPath -Value $logEntry -ErrorAction SilentlyContinue
}

# ============================================================
#  ELEVATION CHECK
# ============================================================

function Test-AdminPrivileges {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        # $PSCommandPath is empty when this runs via the one-liner (Invoke-Expression).
        # In that case we can't relaunch by file path - just continue best-effort (the
        # launcher already elevates), and never call exit (that would close the window).
        if ($PSCommandPath) {
            "Admin rights are needed - requesting elevation..." | Write-Log -Level Warning
            $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -SkipEntraPrompt:$SkipEntraPrompt -LogPath `"$LogPath`""
            Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments
            return $false
        }
        "Not elevated and cannot auto-relaunch - continuing best-effort (run the one-liner from an admin window if steps fail)." | Write-Log -Level Warning
    }
    return $true
}

# ============================================================
#  EXECUTION POLICY
# ============================================================

function Set-LocalExecutionPolicy {
    "Setting execution policy to RemoteSigned..." | Write-Log
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}

# ============================================================
#  SYSTEM CONFIGURATION
# ============================================================

function Disable-UAC {
    "Disabling User Account Control (UAC)..." | Write-Log -Level Warning
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
                         -Name "EnableLUA" -Value 0 -Type DWord -ErrorAction Stop
        "UAC disabled. Restart required for changes to take effect." | Write-Log -Level Warning
    }
    catch {
        "Failed to disable UAC: $_" | Write-Log -Level Error
    }
}

function Configure-VolumeSnapshotService {
    "Configuring Volume Shadow Copy (VSS) storage limit..." | Write-Log
    try {
        & vssadmin resize shadowstorage /for=C: /on=C: /maxsize=$($setupConfig.VSSMaxSize) 2>&1 | Out-Null
        "VSS configured to $($setupConfig.VSSMaxSize) maximum." | Write-Log -Level Success
    }
    catch {
        "Failed to configure VSS: $_" | Write-Log -Level Error
    }
}

function Configure-RegionalSettings {
    "Configuring regional settings (timezone, date format, paper size)..." | Write-Log
    try {
        # Timezone
        & tzutil /s $setupConfig.Timezone

        # Date format and paper size (HKCU)
        $intlPath = "HKCU:\Control Panel\International"
        Set-ItemProperty -Path $intlPath -Name "sShortDate" -Value $setupConfig.DateFormat -ErrorAction Stop
        Set-ItemProperty -Path $intlPath -Name "iPaperSize" -Value $setupConfig.PaperSize -ErrorAction Stop

        "Regional settings configured: $($setupConfig.Timezone), $($setupConfig.DateFormat), Paper Size A4" | Write-Log -Level Success
    }
    catch {
        "Failed to configure regional settings: $_" | Write-Log -Level Error
    }
}

# ============================================================
#  SETUP DIRECTORY & FIXUP SCRIPT
# ============================================================

function Initialize-SetupDirectory {
    "Creating setup directory..." | Write-Log
    New-Item -Path $setupConfig.InstallDir -ItemType Directory -Force | Out-Null
    "Setup directory ready: $($setupConfig.InstallDir)" | Write-Log -Level Success
}

function Create-PostUpdateFixupScript {
    $fixupScriptPath = Join-Path $setupConfig.InstallDir "post-update-fixup.ps1"

    "Creating post-update fixup script..." | Write-Log

    $fixupScript = @'
# ============================================================
#  POST-UPDATE FIXUP SCRIPT
#  Runs automatically after Windows Update completes
# ============================================================

$ErrorActionPreference = "Continue"
$logPath = "C:\ProgramData\WinUtilSetup\post-update.log"

function Write-Log {
    param([string]$Message, [string]$Level = 'Info')
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logPath -Value $entry -ErrorAction SilentlyContinue
    Write-Output $entry
}

Write-Log "Post-update fixup script started"

# Function to check if app is installed
function Test-AppInstalled {
    param([string]$AppId)
    try {
        $installed = winget list --id $AppId 2>&1 | Select-String $AppId
        return $null -ne $installed
    } catch {
        return $false
    }
}

# STEP 1: Install core applications
$appsToReinstall = @(
    @{ Id = "9P7BP5VNWKX5"; Name = "Quick Assist" },
    @{ Id = "9WZDNCRFJ364"; Name = "Microsoft Teams" },
    @{ Id = "9PCFS5B6T72H"; Name = "Paint" },
    @{ Id = "9NBLGGH4QGHW"; Name = "Sticky Notes" },
    @{ Id = "9WZDNCRFHWKN"; Name = "Sound Recorder" }
)

foreach ($app in $appsToReinstall) {
    try {
        if (Test-AppInstalled $app.Id) {
            Write-Log "$($app.Name) is already installed - skipping" "Info"
        } else {
            Write-Log "Installing $($app.Name)..."
            winget install --id $app.Id --source msstore --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
            Write-Log "$($app.Name) installed successfully" "Success"
        }
    } catch {
        Write-Log "$($app.Name) installation skipped or failed" "Warning"
    }
}

# STEP 2: Ensure Microsoft 365 Apps
try {
    if (Test-AppInstalled "Microsoft.Office") {
        Write-Log "Microsoft 365 Apps is already installed" "Info"
    } else {
        Write-Log "Installing Microsoft 365 Apps..."
        winget install --id Microsoft.Office --exact --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
        Write-Log "Microsoft 365 Apps installed successfully" "Success"
    }
} catch {
    Write-Log "Microsoft 365 Apps check failed" "Warning"
}

# STEP 3: Install third-party essentials
$thirdPartyApps = @(
    "RARLab.WinRAR",
    "Google.Chrome"
)

foreach ($app in $thirdPartyApps) {
    try {
        if (Test-AppInstalled $app) {
            Write-Log "$app is already installed - skipping" "Info"
        } else {
            Write-Log "Installing $app..."
            winget install --id $app --source winget --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
            Write-Log "$app installed successfully" "Success"
        }
    } catch {
        Write-Log "$app installation skipped or failed" "Warning"
    }
}

# STEP 4: Force Delivery Optimization to LAN-only
try {
    Write-Log "Configuring Delivery Optimization..."
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" `
                     -Name "DODownloadMode" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Log "Delivery Optimization set to LAN-only" "Success"
} catch {
    Write-Log "Delivery Optimization configuration failed" "Warning"
}

Write-Log "Post-update fixup script completed"
'@

    $fixupScript | Out-File -FilePath $fixupScriptPath -Encoding utf8 -Force
    "Post-update fixup script created: $fixupScriptPath" | Write-Log -Level Success
    return $fixupScriptPath
}

# ============================================================
#  POWER CONFIGURATION
# ============================================================

function Configure-PowerSettings {
    "Detecting system type and configuring power settings..." | Write-Log

    $isLaptop = [bool](Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue)

    if ($isLaptop) {
        "Laptop detected - applying AC and battery profiles..." | Write-Log
        & powercfg /change monitor-timeout-ac $setupConfig.DisplayTimeout_AC
        & powercfg /change standby-timeout-ac $setupConfig.StandbyTimeout_AC
        & powercfg /change monitor-timeout-dc $setupConfig.DisplayTimeout_DC
        & powercfg /change standby-timeout-dc $setupConfig.StandbyTimeout_DC
    }
    else {
        "Desktop detected - applying AC profile only..." | Write-Log
        & powercfg /change monitor-timeout-ac $setupConfig.DisplayTimeout_AC
        & powercfg /change standby-timeout-ac $setupConfig.StandbyTimeout_AC
    }
    "Power settings configured." | Write-Log -Level Success
}

# ============================================================
#  SCHEDULED TASK REGISTRATION
# ============================================================

function Register-PostUpdateTask {
    param([string]$FixupScriptPath)

    "Registering post-update scheduled task..." | Write-Log

    try {
        # Remove existing task if present
        schtasks /delete /tn $setupConfig.ScheduledTaskName /f 2>$null

        # Create new task
        $taskAction = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$FixupScriptPath`""

        schtasks /create /tn $setupConfig.ScheduledTaskName `
                 /tr $taskAction `
                 /sc ONEVENT /ec System `
                 /mo "*[System[Provider[@Name='Microsoft-Windows-WindowsUpdateClient'] and EventID=19]]" `
                 /rl HIGHEST /ru SYSTEM /f

        "Scheduled task registered: $($setupConfig.ScheduledTaskName)" | Write-Log -Level Success
    }
    catch {
        "Failed to register scheduled task: $_" | Write-Log -Level Error
    }
}

# ============================================================
#  ENTRA ID CONNECTION
# ============================================================

function Prompt-EntraIDConnection {
    if ($SkipEntraPrompt) {
        "Skipping Microsoft Entra ID prompt (as requested)." | Write-Log
        return
    }

    $response = Read-Host "Connect this computer to Microsoft Entra ID? (Y/N)"

    if ($response -match '^[Yy]') {
        "Opening 'Access work or school' settings..." | Write-Log
        Start-Process "ms-settings:workplace"
    }
    else {
        "Entra ID connection skipped." | Write-Log
    }
}

# ============================================================
#  MAIN EXECUTION FLOW
# ============================================================

function Invoke-SetupSequence {
    "========== WINDOWS SETUP & OPTIMIZATION STARTED ==========" | Write-Log -Level Info
    "Log: $LogPath" | Write-Log

    # Each step is isolated: if one fails it's logged and the rest still run.
    $steps = @(
        { if (-not (Test-AdminPrivileges)) { return } },
        { Set-LocalExecutionPolicy },
        { Initialize-SetupDirectory },
        { Disable-UAC },
        { Configure-VolumeSnapshotService },
        { Configure-RegionalSettings },
        { Configure-PowerSettings }
    )
    foreach ($step in $steps) {
        try { & $step } catch { "Step failed (continuing): $_" | Write-Log -Level Error }
    }

    try {
        $fixupScript = Create-PostUpdateFixupScript
        Register-PostUpdateTask -FixupScriptPath $fixupScript
        "Running post-update fixup script immediately..." | Write-Log
        & powershell -NoProfile -ExecutionPolicy Bypass -File $fixupScript
    } catch {
        "Post-update fixup step failed (continuing): $_" | Write-Log -Level Error
    }

    try { Prompt-EntraIDConnection } catch { "Entra ID prompt failed (continuing): $_" | Write-Log -Level Error }

    "========== SETUP COMPLETE ==========" | Write-Log -Level Success
    "System will be more responsive after restart. Please restart when ready." | Write-Log -Level Warning
}

# Execute main sequence - never call exit (this runs inside the one-liner's session)
try {
    Invoke-SetupSequence
}
catch {
    "SETUP encountered an error but did not abort: $_" | Write-Log -Level Error
}
