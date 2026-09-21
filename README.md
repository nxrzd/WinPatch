# WinPatcher

**WinPatcher v2.4** is a PowerShell-based Windows maintenance utility that performs system checks, repairs and updates WinGet when necessary, refreshes WinGet sources, upgrades installed packages, and creates diagnostic logs.

It also captures a timestamped network configuration snapshot and can optionally copy that snapshot to an **RDP-redirected folder** on the administrator's local computer.

---

## Overview

WinPatcher is designed for Windows maintenance and package management using Microsoft's **WinGet** package manager.

Before performing package upgrades, WinPatcher can:

- Verify administrator privileges
- Detect the Windows version
- Check system uptime
- Detect a pending Windows reboot
- Capture a network configuration snapshot
- Verify and repair WinGet
- Update WinGet package sources
- Upgrade installed packages
- Save structured logs and a PowerShell transcript
- Optionally export the network snapshot through an RDP redirected drive

> **Important:** WinPatcher requires **Windows PowerShell 5.1 or newer** and administrator privileges.

> **Note:** Windows Terminal is **not required**. WinPatcher runs directly through Windows PowerShell.

---

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1+
- Administrator privileges
- Microsoft App Installer / WinGet
- An active internet connection for package/source updates
- Optional: an RDP session with a redirected drive if RDP export is desired

The script will attempt to repair WinGet if it is missing.

If Microsoft App Installer is not installed at all, WinPatcher will provide the official Microsoft App Installer location rather than silently downloading an external installer.

---

## Features

### Administrator Elevation

WinPatcher automatically checks whether it is running as Administrator.

If it isn't, the script requests elevation through Windows UAC and relaunches itself with the required privileges.

You do not need to manually open an elevated PowerShell window.

### Windows Version Detection

WinPatcher detects the installed Windows version using the operating-system build number.

The detected version is recorded in the application log and included in the network snapshot.

### System Uptime Check

WinPatcher checks how long the system has been running.

The default recommended maximum uptime is:

```text
12 hours
