# Windows Setup & Optimization Automation

Comprehensive automated setup and optimization for fresh Windows 10/11 installations. Configures system settings, debloats built-in apps, installs essential software, and sets up automatic post-update maintenance.

## Quick Start

Run this single command in PowerShell on any computer:

```powershell
irm https://raw.githubusercontent.com/xnostra/newlyformatscriptoncomputers/main/invoke-setup.ps1 | iex
```

That's it—auto-downloads, auto-elevates to admin, and completes full system setup.

## Features

✅ **System Configuration**
- Disables User Account Control (UAC)
- Configures Volume Shadow Copy (VSS) storage limits
- Sets regional settings (timezone, date format, paper size)
- Applies power management profiles (laptop vs. desktop detection)

✅ **System Tweaks (WinUtil "Standard" parity)**
- Applies the same 12 tweaks as WinUtil's Standard preset, implemented natively (no external dependency, no GUI required)
- Disables activity feed, consumer features, WPBT, location tracking, and telemetry
- Sets non-essential services to manual/disabled
- Creates a system restore point and clears temp files before changes

✅ **Debloat**
- Removes 14 default bloatware apps (Feedback Hub, Get Help, Office Hub, Clipchamp, Alarms, To Do, Solitaire, Power Automate, Dev Home, Weather, Widgets, News, Copilot, Bing Search)
- Keeps Calculator and other useful built-ins

✅ **Application Management**
- Installs curated Microsoft Store apps (Quick Assist, Teams, Paint, Sticky Notes, Sound Recorder)
- Installs Microsoft 365 Apps, Google Chrome, and WinRAR
- Checks if each app is already installed and skips it if so (no redundant reinstalls)
- Uses `winget` for reliable package management

✅ **Delivery & Updates**
- Forces Delivery Optimization to LAN-only mode
- Registers automatic post-update fixup task
- Logs all operations to file

✅ **Optional Entra ID Integration**
- Prompts for Microsoft Entra ID enrollment (can be skipped)
- Integrates with work/school accounts

## Prerequisites

- Windows 10/11 (any edition)
- Administrator privileges (script auto-elevates)
- Internet connection (for downloading packages)
- PowerShell 5.1+ (built-in)

## Deployment Options

**Option 1: One-Liner** (Recommended)

```powershell
irm https://raw.githubusercontent.com/xnostra/newlyformatscriptoncomputers/main/invoke-setup.ps1 | iex
```

**Option 2: Local Execution**

1. Download `setup.ps1`
2. Open PowerShell as Administrator
3. Run:
   ```powershell
   .\setup.ps1
   ```

**Option 3: With Parameters**

Skip Entra ID prompt:
```powershell
.\setup.ps1 -SkipEntraPrompt
```

Custom log path:
```powershell
.\setup.ps1 -LogPath "C:\Logs\setup.log"
```

## What Gets Installed

| Software | Purpose | Source |
|----------|---------|--------|
| Microsoft 365 Apps | Productivity suite | WinGet |
| Google Chrome | Web browser | WinGet |
| WinRAR | File compression | WinGet |
| Quick Assist | Remote support | Microsoft Store |
| Microsoft Teams | Communication | Microsoft Store |
| Paint | Image editing | Microsoft Store |
| Sticky Notes | Note taking | Microsoft Store |
| Sound Recorder | Audio capture | Microsoft Store |

## Configuration Details

**Regional Settings**
- Timezone: Arab Standard Time (UTC+03:00) - Qatar
- Date Format: dd-MM-yyyy
- Paper Size: A4

**Power Settings**

Laptop:
- Display timeout (AC): 60 minutes
- Sleep timeout (AC): Never
- Display timeout (Battery): 15 minutes
- Sleep timeout (Battery): 30 minutes

Desktop:
- Display timeout (AC): 60 minutes
- Sleep timeout (AC): Never

**Auto-Maintenance**
- Post-update fixup task runs automatically after Windows Update
- Logs: `C:\ProgramData\WinUtilSetup\setup.log` and `post-update.log`

## Logging

All operations logged to:
```
C:\ProgramData\WinUtilSetup\setup.log
C:\ProgramData\WinUtilSetup\post-update.log
```

View logs:
```powershell
Get-Content "C:\ProgramData\WinUtilSetup\setup.log" -Tail 50
```

## Important Notes

⚠️ **Restart Required**
- UAC disabling requires a system restart to take effect

⚠️ **Network Requirements**
- `winget` requires internet connectivity
- Some apps may not install if network is unavailable

⚠️ **Entra ID Enrollment**
- Optional and interactive
- Only needed for work/school accounts
- Can be skipped with `-SkipEntraPrompt` flag

## Customization

Edit `setup.ps1` to modify:
- Timezone (change `"Arab Standard Time"`)
- Installed applications (edit app lists)
- Power settings (adjust timeouts)
- Regional settings (date format, paper size)

## Troubleshooting

**"Access Denied" Error**
- Ensure you're running PowerShell as Administrator
- Or set execution policy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force`

**Script Downloads But Doesn't Run**
- Check GitHub URL is correct
- Verify repository is public
- Ensure internet connectivity

**WinGet Package Installation Fails**
- Check Windows Update is installed and up-to-date
- Some packages require specific Windows editions
- Manually install via Microsoft Store if needed

**Scheduled Task Not Running**
- Verify Task Scheduler is enabled
- Check Windows Update service is running
- Review Windows Event Viewer > Windows Logs > System for errors

## Version History

**v2.1** (2026-07-20)
- Replaced WinUtil dependency with native Standard-preset tweaks (avoids WinUtil's headless crash)
- Added debloat step (removes 14 default apps, keeps Calculator)
- Apps now skipped if already installed (efficiency)
- Suppressed verbose output for clean logs

**v2.0** (2026-07-20)
- Complete rewrite with professional error handling and logging
- Improved power management detection (laptop vs. desktop)
- Post-update automatic fixup scheduling
- One-liner launcher support

**v1.0**
- Initial release

## Support

For issues or questions:
- Open an issue on GitHub
- Check logs in `C:\ProgramData\WinUtilSetup\`
- Review PowerShell error output

## License

Provided as-is. Modify and distribute freely.

---

**One-Liner**: `irm https://raw.githubusercontent.com/xnostra/newlyformatscriptoncomputers/main/invoke-setup.ps1 | iex`

**Repository**: https://github.com/xnostra/newlyformatscriptoncomputers

**Last Updated**: 2026-07-20
