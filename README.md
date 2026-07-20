# Windows Setup & Optimization Script

Comprehensive automated setup and optimization for fresh Windows 10/11 installations. Configures system settings, debloats built-in apps, installs essential software, and sets up automatic post-update maintenance.

## Features

✅ **System Configuration**
- Disables User Account Control (UAC)
- Configures Volume Shadow Copy (VSS) storage limits
- Sets regional settings (timezone, date format, paper size)
- Applies power management profiles (laptop vs. desktop detection)

✅ **Application Management**
- Applies WinUtil "Standard" preset for system debloating
- Selectively reinstalls useful Microsoft Store apps (Teams, Paint, Sticky Notes, etc.)
- Installs Microsoft 365 Apps
- Deploys third-party essentials (Google Chrome, WinRAR)
- Uses `winget` for reliable package management

✅ **Delivery & Updates**
- Forces Delivery Optimization to LAN-only mode
- Registers automatic post-update fixup task
- Logs all operations to file

✅ **Optional Entra ID Integration**
- Prompts for Microsoft Entra ID enrollment (can be skipped)
- Integrates with work/school accounts

## Quick Start

### Option 1: One-Liner (Recommended)

Run this single command in PowerShell on any computer:

```powershell
irm https://github.com/YOUR_USERNAME/windows-setup-scripts/raw/main/invoke-setup.ps1 | iex
```

Replace `YOUR_USERNAME` with your GitHub username.

### Option 2: Local Execution

1. Download `setup.ps1` to your computer
2. Open PowerShell as Administrator
3. Run:
   ```powershell
   .\setup.ps1
   ```

### Option 3: With Parameters

Skip the Entra ID prompt:
```powershell
.\setup.ps1 -SkipEntraPrompt
```

Specify a custom log path:
```powershell
.\setup.ps1 -LogPath "C:\Logs\setup.log"
```

## Prerequisites

- **Windows 10/11** (any edition)
- **Administrator privileges** (script will auto-elevate)
- **Internet connection** (for downloading packages)
- **PowerShell 5.1+** (built-in on Windows 10/11)

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

### Regional Settings
- **Timezone**: Arab Standard Time (UTC+03:00) - Qatar
- **Date Format**: dd-MM-yyyy
- **Paper Size**: A4

### Power Settings

**Laptop:**
- Display timeout (AC): 60 minutes
- Sleep timeout (AC): Never
- Display timeout (Battery): 15 minutes
- Sleep timeout (Battery): 30 minutes

**Desktop:**
- Display timeout (AC): 60 minutes
- Sleep timeout (AC): Never

### Auto-Maintenance
- Post-update fixup task runs automatically after Windows Update installs updates
- Logs written to: `C:\ProgramData\WinUtilSetup\post-update.log`

## Logging

All operations are logged to:
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
- Plan accordingly for production systems

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
- Installed applications (add/remove from `appsToReinstall` or `thirdPartyApps`)
- Power settings (adjust `DisplayTimeout_AC`, `StandbyTimeout_DC`, etc.)
- Regional date format and paper size

## Troubleshooting

### "Access Denied" Error
- Ensure you're running PowerShell **as Administrator**
- If using the one-liner, you may need to set execution policy first:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
  ```

### Script Downloads But Doesn't Run
- Check GitHub URL is correct
- Verify the repository is public
- Ensure internet connectivity

### WinGet Package Installation Fails
- Check Windows Update is installed and up-to-date
- Some packages require specific Windows editions
- Manually install via Microsoft Store if needed

### Scheduled Task Not Running
- Verify Task Scheduler is enabled
- Check Windows Update service is running
- Review Windows Event Viewer > Windows Logs > System for errors

## Support & Feedback

For issues, enhancements, or questions:
- Open an issue on GitHub
- Check the logs in `C:\ProgramData\WinUtilSetup\`
- Review PowerShell error output

## Version History

**v2.0** (2026-07-20)
- Complete rewrite with proper error handling
- Added comprehensive logging
- Improved power management detection
- Better app installation resilience
- Added post-update automatic fixup scheduling
- Professional documentation

**v1.0** (Original)
- Initial release

## License

Provided as-is. Modify and distribute freely.

## Author

Windows Setup & Optimization Team

---

**Last Updated**: 2026-07-20  
**Repository**: https://github.com/YOUR_USERNAME/windows-setup-scripts
