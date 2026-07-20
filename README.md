Windows Workstation Provisioning Script
Overview
This repository contains a post-installation PowerShell script (new format script on computers.ps1) engineered to automate the setup of newly formatted Windows workstations. It reduces manual configuration time and ensures consistent system environments across organizational deployments.

Designed for institutional IT environments, this tool not only configures the baseline operating system but also creates a persistent, automated task that maintains system optimization and software standardization even after major Windows Updates.

Core Capabilities
1. Initial System Baselines & Security
Automatic Elevation: Detects execution context and automatically requests Administrator privileges if required.

Execution Policies: Enforces RemoteSigned for local scripts to ensure execution reliability.

UAC Modification: Disables User Account Control (UAC) to streamline administrative setups (requires a system restart).

Storage Management: Caps System Restore shadow storage at 5GB to prevent automatic backups from consuming local disk space over time.

2. Regional & Institutional Standardization
Time & Date: Configures the system timezone to Arab Standard Time (UTC+03:00) and enforces a uniform dd-MM-yyyy short date format.

Print Settings: Sets the default system paper size to A4.

3. Persistent Optimization (Post-Update Fixup)
Windows Updates frequently revert system debloat configurations. This script counteracts that by generating a secondary payload (winutil-setup.ps1) and binding it to a Windows Task Scheduler event.

Trigger: Automatically executes silently in the background via the SYSTEM account whenever the Windows Update Client finishes an installation (Event ID 19).

Debloat Maintenance: Re-applies the Chris Titus "Standard" Windows Utility preset to strip unnecessary telemetry and bloatware.

4. Software Deployment & Restoration
To balance a debloated system with daily operational needs, the script handles necessary software provisioning via winget:

App Restoration: Automatically reinstalls essential native utilities removed by aggressive debloat presets (Quick Assist, Microsoft Teams, Paint, Sticky Notes, Sound Recorder).

Productivity Suite: Silently deploys Microsoft 365 Apps.

Standard Utilities: Installs institutional staples like Google Chrome and WinRAR.

5. Network & Power Optimization
Delivery Optimization: Forces Windows Update P2P sharing (Delivery Optimization) to LAN-only mode, preserving external bandwidth.

Hardware-Aware Power Plans: Dynamically queries the WMI chassis type.

Laptops: Applies specific display and sleep timeouts for both AC (Plugged-In) and DC (Battery) states.

Desktops: Applies aggressive continuous-run AC settings (1-hour display timeout, no sleep).

6. Directory Integration
Microsoft Entra ID: Concludes the setup with an interactive prompt, launching the exact Windows settings page required to join the device to an organizational Entra ID (Work or School) domain.

Prerequisites
OS: Windows 10 or Windows 11 (Pro/Enterprise/Education recommended).

Network: An active internet connection is strictly required for winget package installations and the WinUtil download.

Permissions: Local Administrator rights.

Execution Instructions
Download new format script on computers.ps1 to the target machine.

Right-click the file and select Run with PowerShell.

Accept the UAC prompt if it appears. The script will automatically elevate itself if run from a standard window.

Allow the script to run through the winget installations and debloat process.

At the end of the script, press Y if you wish to connect the machine to Microsoft Entra ID, or N to skip.

Restart the computer to apply the UAC and system-level modifications.
