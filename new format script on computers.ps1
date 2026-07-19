# ============================================================
#  FINAL SETUP SCRIPT
# ============================================================

# --- Always allow local scripts to run whenever this is launched ---
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# --- Auto-elevate to admin only if not already running elevated (most steps below need it) ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Admin rights are needed - requesting elevation..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# --- ONE-TIME: disable UAC (User Account Control) ---
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0 -Type DWord
Write-Host "UAC disabled. A restart is needed for this to take effect." -ForegroundColor Yellow

# --- ONE-TIME: cap System Restore storage so old restore points auto-purge ---
vssadmin resize shadowstorage /for=C: /on=C: /maxsize=5GB

# --- ONE-TIME: regional settings - Doha/Qatar timezone, dd-MM-yyyy date, A4 paper ---
tzutil /s "Arab Standard Time"   # UTC+03:00, matches Qatar (no DST)
Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "sShortDate" -Value "dd-MM-yyyy"
Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "iPaperSize" -Value "9"   # 9 = A4

# --- Save the recurring fixup script permanently ---
$installDir = "C:\ProgramData\WinUtilSetup"
New-Item -Path $installDir -ItemType Directory -Force | Out-Null
$scriptPath = "$installDir\winutil-setup.ps1"

@'
# --- STEP 1: Apply winutil "Standard" preset tweaks + DeBloat ---
& ([ScriptBlock]::Create((irm "https://christitus.com/win"))) -Preset Standard

# --- STEP 2: Reinstall apps DeBloat removes but we want to keep ---
winget install --id 9P7BP5VNWKX5 --source msstore --accept-package-agreements --accept-source-agreements   # Quick Assist
winget install --id 9WZDNCRFJ364 --source msstore --accept-package-agreements --accept-source-agreements   # Microsoft Teams
winget install --id 9PCFS5B6T72H --source msstore --accept-package-agreements --accept-source-agreements   # Paint
winget install --id 9NBLGGH4QGHW --source msstore --accept-package-agreements --accept-source-agreements   # Sticky Notes
winget install --id 9WZDNCRFHWKN --source msstore --accept-package-agreements --accept-source-agreements   # Sound Recorder

# --- STEP 3: Make sure Microsoft 365 Apps is installed ---
winget install --id Microsoft.Office --exact --silent --accept-package-agreements --accept-source-agreements

# --- STEP 4: Install extra everyday apps ---
winget install --id RARLab.WinRAR --source winget --accept-package-agreements --accept-source-agreements
winget install --id Google.Chrome --source winget --accept-package-agreements --accept-source-agreements

# --- STEP 5: Force Delivery Optimization (P2P) back to LAN-only ---
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 1 -Type DWord

# --- STEP 6: Power plan - laptop gets AC + battery profile, desktop gets AC only ---
$isLaptop = [bool](Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue)

if ($isLaptop) {
    Write-Host "Laptop detected - applying plugged-in and battery power settings."
    powercfg /change monitor-timeout-ac 60   # Plugged in: turn off display after 1 hour
    powercfg /change standby-timeout-ac 0    # Plugged in: never sleep
    powercfg /change monitor-timeout-dc 15   # On battery: turn off display after 15 min
    powercfg /change standby-timeout-dc 30   # On battery: sleep after 30 min
} else {
    Write-Host "Desktop detected - applying plugged-in power settings only."
    powercfg /change monitor-timeout-ac 60
    powercfg /change standby-timeout-ac 0
}
'@ | Out-File -FilePath $scriptPath -Encoding utf8 -Force

# --- Register a scheduled task that fires whenever Windows Update finishes installing an update ---
schtasks /create /tn "WinUtil Post-Update Fixup" `
  /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" `
  /sc ONEVENT /ec System `
  /mo "*[System[Provider[@Name='Microsoft-Windows-WindowsUpdateClient'] and EventID=19]]" `
  /rl HIGHEST /ru SYSTEM /f

# --- Run it once right now, since this is a fresh install ---
powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath

# --- Optional: connect this PC to Microsoft Entra ID (interactive, one-time only) ---
$connectEntra = Read-Host "Connect this computer to Microsoft Entra ID? (Y/N)"
if ($connectEntra -match '^[Yy]') {
    Write-Host "Opening 'Access work or school' - enter your school/work account details there."
    Start-Process "ms-settings:workplace"
} else {
    Write-Host "Skipping Entra ID connection. Setup complete."
}
