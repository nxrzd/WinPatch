WinPatcher

WinPatcher v2.4 is a PowerShell-based Windows maintenance utility that performs system checks, repairs and updates WinGet when necessary, refreshes WinGet sources, upgrades installed packages, and creates diagnostic logs.

It also captures a timestamped network configuration snapshot and can optionally copy that snapshot to an RDP-redirected folder on the administrator's local computer.

Overview

WinPatcher is designed for Windows maintenance and package management using Microsoft's WinGet package manager.

Before performing package upgrades, WinPatcher can:

Verify administrator privileges

Detect the Windows version

Check system uptime

Detect a pending Windows reboot

Capture a network configuration snapshot

Verify and repair WinGet

Update WinGet package sources

Upgrade installed packages

Save structured logs and a PowerShell transcript

Optionally export the network snapshot through an existing RDP redirected drive

Important: WinPatcher requires Windows PowerShell 5.1 or newer and administrator privileges.

Note: Windows Terminal is not required. WinPatcher runs directly through Windows PowerShell.

Requirements

Windows 10 or Windows 11

Windows PowerShell 5.1+

Administrator privileges

Microsoft App Installer / WinGet

An active internet connection for package/source updates

Optional: an RDP session with a redirected drive if RDP export is desired

The script will attempt to repair WinGet if it is missing.

If Microsoft App Installer is not installed at all, WinPatcher will provide the official Microsoft App Installer location rather than silently downloading an external installer.

Features
Administrator Elevation

WinPatcher automatically checks whether it is running as Administrator.

If it isn't, the script requests elevation through Windows UAC and relaunches itself with the required privileges.

You do not need to manually open an elevated PowerShell window.

Windows Version Detection

WinPatcher detects the installed Windows version using the operating-system build number.

The detected version is recorded in the application log and included in the network snapshot.

System Uptime Check

WinPatcher checks how long the system has been running.

The default recommended maximum uptime is:

12 hours


If the system has been running longer than this threshold, WinPatcher displays a warning and allows the operator to decide whether to continue.

The threshold can be changed in the configuration section:

$MaxRecommendedUptimeHours = 12

Pending Reboot Detection

WinPatcher checks several Windows indicators for a pending restart, including:

Windows Update restart requirements

Component Based Servicing restart requirements

Pending file operations

If a reboot appears to be pending, the operator is warned before package upgrades begin.

The operator can choose to continue or exit.

Network Configuration Snapshot

WinPatcher captures:

ipconfig /all


once per execution.

The resulting snapshot is saved as a timestamped text file.

Example:

C:\ProgramData\WinPatcher\NetworkLogs\IPConfig_2026-09-21_09-30-00.txt


The complete network configuration is kept in the dedicated network log rather than duplicated into the general application log.

Privacy note: ipconfig /all can contain network configuration information such as IP addresses, DNS servers, adapter information, and other system/network details. Treat the generated network log as potentially sensitive.

RDP Network Log Export

If WinPatcher is being run inside an RDP session with a redirected local drive, the network snapshot can optionally be copied through the existing RDP redirected filesystem.

By default:

$RdpExportEnabled = $true


WinPatcher looks for an available RDP redirected location under:

\\tsclient\


For example:

\\tsclient\C


It then creates:

\\tsclient\C\WinPatcher\


and copies the network snapshot there.

This does not create a separate outbound connection or "call home" to an IP address. It uses the existing RDP drive-redirection mechanism.

Disable RDP export

To disable automatic export:

$RdpExportEnabled = $false

Specify an explicit RDP destination

You can also specify a particular redirected location:

$RdpExportPath = "\\tsclient\C\Users\YourName\Desktop"


When a path is explicitly configured, WinPatcher uses that location instead of automatically searching for an available redirected drive.

If no RDP redirected location is available, the network log simply remains on the Windows machine.

WinGet Detection and Repair

WinPatcher checks whether winget is available.

If WinGet is missing, it attempts to repair Microsoft App Installer using two methods.

Method 1 — App Installer manifest registration

If Microsoft App Installer is installed, WinPatcher locates its installation directory and registers:

AppXManifest.xml

Method 2 — Family registration fallback

If the first repair method does not restore WinGet, WinPatcher attempts:

Add-AppxPackage `
    -RegisterByFamilyName `
    -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe


WinPatcher then verifies that winget is available.

If App Installer itself is missing, the script stops and displays the official Microsoft App Installer location.

WinGet Source Update

Before upgrading installed packages, WinPatcher runs:

winget source update


This refreshes the configured WinGet package sources before the upgrade operation.

Package Upgrades

WinPatcher performs the equivalent of:

winget upgrade --all


with the following options:

--all
--include-unknown
--accept-source-agreements
--accept-package-agreements
--silent
--disable-interactivity


This allows WinPatcher to upgrade applicable installed packages while minimizing interactive prompts.

The resulting WinGet output is written to the application log.

Logging

WinPatcher stores its logs under:

C:\ProgramData\WinPatcher\


The directory structure looks approximately like:

C:\ProgramData\WinPatcher\
│
├── WinPatcher_2026-09-21_09-30-00.log
├── Transcript_2026-09-21_09-30-00.txt
│
└── NetworkLogs\
    └── IPConfig_2026-09-21_09-30-00.txt

Application Log

The main log contains operational information such as:

Detected Windows version

System uptime

Pending reboot status

WinGet status

WinGet repair attempts

Source update results

Package upgrade results

Errors and warnings

Completion status

PowerShell Transcript

The transcript records the PowerShell session output generated during the elevated WinPatcher process.

Network Log

The network log contains the complete ipconfig /all snapshot.

Keeping the network snapshot separate prevents the general application log from becoming unnecessarily large and keeps network information isolated.

Configuration

The primary configuration options are located near the top of the script.

Maximum recommended uptime
$MaxRecommendedUptimeHours = 12

RDP export
$RdpExportEnabled = $true

RDP export path

Leave empty for automatic detection:

$RdpExportPath = ""


Or specify a redirected RDP location:

$RdpExportPath = "\\tsclient\C\Users\YourName\Desktop"

Usage
1. Download or clone the repository

Place WinPatcher.ps1 somewhere convenient.

2. Open PowerShell

Windows PowerShell 5.1 is supported.

You do not need to manually launch PowerShell as Administrator; WinPatcher will request elevation itself.

3. Run the script

From the directory containing the script:

.\WinPatcher.ps1


Windows will display a UAC prompt if administrator privileges are required.

4. Press ENTER

After the banner appears, press ENTER to begin the maintenance sequence.

WinPatcher will then:

Administrator check
        ↓
Windows version detection
        ↓
Network configuration snapshot
        ↓
Optional RDP export
        ↓
System uptime check
        ↓
Pending reboot check
        ↓
WinGet detection/repair
        ↓
WinGet source update
        ↓
Package upgrade
        ↓
Logging / completion

Execution Policy

WinPatcher launches its elevated process using:

-ExecutionPolicy Bypass


This means you generally do not need to permanently change the system's PowerShell execution policy just to run WinPatcher.

If Windows or your organization's security policy prevents script execution, that policy may still need to be addressed by the system administrator.

Avoid permanently setting the machine-wide execution policy to an unnecessarily permissive setting just to run this script.

Security and Privacy

WinPatcher performs system maintenance operations with Administrator privileges.

The script writes information to:

C:\ProgramData\WinPatcher\


The network snapshot may contain potentially sensitive information, including:

Local IP addresses

DNS configuration

Network adapter information

DHCP information

Gateway information

MAC addresses

If RDP export is enabled, the network snapshot may also be copied to an RDP-redirected folder on the administrator's local machine.

The script does not establish an independent "call home" connection or transmit the network snapshot to a hard-coded IP address.

Why Windows Terminal Isn't Installed

Earlier versions of WinPatcher included an optional Windows Terminal installation.

This has been removed in v2.4.

Windows Terminal is not required to run WinGet or PowerShell, and installing unrelated software during a maintenance operation is unnecessary.

WinPatcher therefore limits itself to the components required for its maintenance workflow.

Troubleshooting
winget is not found

WinPatcher automatically attempts to repair Microsoft App Installer.

If repair fails, install Microsoft App Installer and run WinPatcher again.

RDP export isn't working

Verify that drive redirection is enabled for the RDP session.

From PowerShell, you can check whether the RDP redirected location exists:

Test-Path "\\tsclient"


If a redirected drive is available, you can inspect it with:

Get-ChildItem "\\tsclient"


You can also specify the exact destination manually:

$RdpExportPath = "\\tsclient\C\Users\YourName\Desktop"

A reboot warning appears

WinPatcher detected one or more indicators that Windows may require a restart.

You can either restart Windows before running the patch process or choose to continue when prompted.

Package upgrade returns a warning

WinGet can return non-zero exit codes for individual package or installer conditions that don't necessarily mean the entire system is broken.

Check:

C:\ProgramData\WinPatcher\


for the application log and transcript to determine what occurred.

Log Location

All logs are stored here:

C:\ProgramData\WinPatcher\


Network snapshots:

C:\ProgramData\WinPatcher\NetworkLogs\


RDP-exported snapshots, when enabled:

\\tsclient\<RedirectedDrive>\WinPatcher\

License

MIT License.

Copyright © nxrzd
