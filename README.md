# WinPatch

**WinPatch v2.4** is a PowerShell-based Windows maintenance utility that performs system checks, repairs and updates WinGet when necessary, refreshes WinGet sources, upgrades installed packages, and installs Windows Updates.

WinPatch also creates diagnostic logs, captures a timestamped network configuration snapshot, and can optionally copy that snapshot to an **RDP-redirected folder** on the administrator's local computer.

---

## Overview

WinPatch is designed for Windows maintenance and package management using Microsoft's **WinGet** package manager and the Windows Update Agent.

Before and during maintenance operations, WinPatch can:

- Verify administrator privileges
- Automatically request Administrator elevation through Windows UAC
- Relaunch itself in an elevated PowerShell window when required
- Detect the Windows version
- Check system uptime
- Detect a pending Windows reboot
- Capture a network configuration snapshot
- Verify and repair WinGet
- Update WinGet package sources
- Upgrade installed packages
- Search Windows Update
- Display required, optional, and driver updates
- Install required Windows Updates
- Optionally install optional updates and drivers
- Optionally restart Windows when an update requires a reboot
- Save structured logs and a PowerShell transcript
- Optionally export the network snapshot through an RDP-redirected drive

> **Important:** WinPatch requires **Windows PowerShell 5.1 or newer**.

> **Note:** Administrator privileges are required for maintenance operations. WinPatch can automatically request elevation through Windows UAC, so you do not need to manually open an elevated PowerShell window.

> **Note:** Windows Terminal is **not required**. WinPatch runs directly through Windows PowerShell.

---

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1+
- Administrator privileges
- Microsoft App Installer / WinGet
- An active internet connection for package and source updates
- Optional: an RDP session with a redirected drive if RDP export is desired

WinPatch will automatically request Administrator elevation if it is launched from a non-elevated PowerShell session.

The original non-administrator PowerShell process exits after successfully launching the elevated copy.

If WinGet is missing, WinPatch will attempt to repair it.

If Microsoft App Installer is not installed at all, WinPatch will provide the official Microsoft App Installer location rather than silently downloading an external installer.

---

## Administrator Elevation

WinPatch includes built-in UAC self-elevation.

When the script is launched without Administrator privileges, it:

1. Detects that the current PowerShell process is not elevated.
2. Requests Administrator access through Windows UAC.
3. Launches an elevated copy of the same script.
4. Preserves any command-line options supplied to the original script.
5. Closes the original non-administrator PowerShell process.
6. Continues execution in the elevated PowerShell process.

This means WinPatch can be started normally without manually selecting **Run as administrator**.

For example:

```powershell
.\WinPatch.ps1
