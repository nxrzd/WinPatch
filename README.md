WinPatch

WinPatch v2.4 is a PowerShell-based Windows maintenance utility that performs system checks, repairs and updates WinGet when necessary, refreshes WinGet sources, upgrades installed packages, and installs Windows Updates.

WinPatch also creates diagnostic logs, captures a timestamped network configuration snapshot, and can optionally copy that snapshot to an RDP-redirected folder on the administrator's local computer.

Overview

WinPatch is designed for Windows maintenance and package management using Microsoft's WinGet package manager and the Windows Update Agent.

Before and during maintenance operations, WinPatch can:

Verify administrator privileges

Automatically request Administrator elevation through Windows UAC

Relaunch itself in an elevated PowerShell window when required

Detect the Windows version

Check system uptime

Detect a pending Windows reboot

Capture a network configuration snapshot

Verify and repair WinGet

Update WinGet package sources

Upgrade installed packages

Search Windows Update

Display required, optional, and driver updates

Install required Windows Updates

Optionally install optional updates and drivers

Optionally restart Windows when an update requires a reboot

Save structured logs and a PowerShell transcript

Optionally export the network snapshot through an RDP-redirected drive

Important: WinPatch requires Windows PowerShell 5.1 or newer.

Note: Administrator privileges are required for maintenance operations. WinPatch can automatically request elevation through Windows UAC, so you do not need to manually open an elevated PowerShell window.

Note: Windows Terminal is not required. WinPatch runs directly through Windows PowerShell.

Requirements

Windows 10 or Windows 11

Windows PowerShell 5.1+

Administrator privileges

Microsoft App Installer / WinGet

An active internet connection for package and source updates

Optional: an RDP session with a redirected drive if RDP export is desired

WinPatch will automatically request Administrator elevation if it is launched from a non-elevated PowerShell session.

The original non-administrator PowerShell process exits after successfully launching the elevated copy.

If WinGet is missing, WinPatch will attempt to repair it.

If Microsoft App Installer is not installed at all, WinPatch will provide the official Microsoft App Installer location rather than silently downloading an external installer.

Administrator Elevation

WinPatch includes built-in UAC self-elevation.

When the script is launched without Administrator privileges, it:

Detects that the current PowerShell process is not elevated.

Requests Administrator access through Windows UAC.

Launches an elevated copy of the same script.

Preserves any command-line options supplied to the original script.

Closes the original non-administrator PowerShell process.

Continues execution in the elevated PowerShell process.

This means WinPatch can be started normally without manually selecting Run as administrator.

For example:

.\WinPatch.ps1


Windows will display the normal UAC elevation prompt when required.

If the UAC request is cancelled, WinPatch exits without performing maintenance operations.

Windows Version Detection

WinPatch detects the installed Windows version using the operating-system build number.

The detected Windows version is recorded in the application log and included in the network snapshot.

System Uptime Check

WinPatch checks how long the system has been running.

The default recommended maximum uptime is:

12 hours


The uptime information is recorded during the system health checks and can be used to identify systems that may benefit from a restart.

Windows Update

WinPatch can search Windows Update and present available updates in three categories:

Required Updates
Optional Updates
Drivers


Required updates are selected for installation by default.

Optional updates and driver updates are displayed but are not selected unless explicitly enabled.

Default Windows Update behavior

Running WinPatch without additional Windows Update options results in:

Required updates:  YES
Optional updates:  NO
Drivers:           NO
Automatic reboot:  NO


The user is prompted for confirmation before the selected updates are downloaded and installed.

Windows Update Options
Required Updates Only

The default behavior installs required Windows Updates:

.\WinPatch.ps1


Optional updates and drivers are displayed but are not selected.

Required Updates + Optional Updates + Drivers

Use:

.\WinPatch.ps1 -Include_Optional


This enables installation of:

Required Windows Updates

Optional Windows Updates

Driver Updates

Required Updates + Optional Updates + Drivers + Automatic Reboot

Use:

.\WinPatch.ps1 -Include_Optional -Auto_Reboot


If the current update operation requires a restart, WinPatch will display a countdown and automatically restart Windows.

Windows Update Reboot Behavior

WinPatch distinguishes between an existing pending reboot and a reboot required by the current update operation.

If Windows already reports a pending reboot when WinPatch starts:

Pending reboot detected


WinPatch does not automatically restart the computer at this stage.

An automatic restart only occurs when the current Windows Update operation reports that a reboot is required and -Auto_Reboot was specified.

Without -Auto_Reboot, WinPatch reports that a restart is required and allows the administrator to restart Windows manually.

Windows Update Selection

The Windows Update section displays available updates before installation.

Example:

WINDOWS UPDATE
------------------------------------------------------------

Required Updates
  ● KB1234567 Cumulative Update for Windows
      Size: 850.5 MB

Optional Updates
  ● KB1234568 Preview Update
      Size: 125.2 MB

Drivers
  ● Manufacturer - Display Driver
      Size: 450.0 MB

Available Updates:
  Required:         1
  Optional:         1
  Drivers:          1

Selected for installation: 1


By default, only required updates are selected.

Using -Include_Optional selects all three categories.

Installation Confirmation

Before downloading and installing Windows Updates, WinPatch prompts for confirmation:

Install selected updates? [Y/N]


Selecting N cancels the Windows Update operation without installing anything.

Windows Update Results

After installation, WinPatch reports the result of each update individually.

Possible results include:

Installed successfully

Installed with errors

Installation failed

Installation aborted

Unknown installation result

WinPatch also reports:

Installation duration

Number of successful installations

Number of installations with errors

Number of failed updates

Number of unknown results

Download failures

Whether a reboot is required

WinGet Maintenance

WinPatch uses Microsoft's WinGet package manager for application package maintenance.

WinPatch can:

Verify WinGet availability

Repair WinGet when necessary

Refresh WinGet package sources

Upgrade installed packages

Report package operation results

Record package-management activity in the application logs

If WinGet or Microsoft App Installer is unavailable, WinPatch provides appropriate diagnostic information rather than silently installing an untrusted package.

Network Configuration Snapshot

WinPatch captures a timestamped network configuration snapshot as part of its diagnostic process.

The snapshot can contain information useful for troubleshooting:

IP configuration

Network adapters

DNS configuration

Routing information

Network connectivity

Hostname information

The snapshot is stored alongside the WinPatch diagnostic information.

RDP Snapshot Export

When WinPatch is running inside an RDP session with a redirected local drive, the network configuration snapshot can optionally be copied to the redirected location.

This allows an administrator to retrieve diagnostic information directly on the local computer without manually copying files from the remote system.

RDP export is optional and does not affect normal WinPatch operation when no redirected drive is available.

Logging

WinPatch creates diagnostic logs to assist with troubleshooting and maintenance auditing.

Logging includes information such as:

Script start and completion times

Computer name

Windows version

Administrator status

System uptime

Pending reboot status

WinGet status

WinGet source operations

Package upgrade results

Windows Update search results

Windows Update installation results

Reboot requirements

Errors and warnings

WinPatch also maintains a PowerShell transcript where configured.

Command-Line Usage
Standard Maintenance
.\WinPatch.ps1


Runs WinPatch using the default maintenance and Windows Update behavior.

Include Optional Windows Updates and Drivers
.\WinPatch.ps1 -Include_Optional


Installs required updates, optional updates, and drivers.

Include Optional Updates and Automatically Reboot
.\WinPatch.ps1 -Include_Optional -Auto_Reboot


Installs required updates, optional updates, and drivers, then automatically restarts Windows if the current update operation requires it.

Default Behavior

When WinPatch is run without flags:

Administrator elevation: Automatic
Required updates:        Selected
Optional updates:        Not selected
Drivers:                 Not selected
Automatic reboot:        Disabled
Existing pending reboot: Does not trigger automatic restart
Installation:            Requires user confirmation


This makes the default mode suitable for interactive maintenance where the administrator wants to review available Windows Updates before installation.

Exit Codes

The Windows Update component uses the following exit codes:

Code	Meaning
0	Success
1	Administrator elevation/startup failure
2	Windows Update initialization failure
3	Windows Update search failure
10	User cancelled installation
20	Download operation failure
21	No selected updates downloaded successfully
30	Installation operation failure
40	One or more updates failed or could not be downloaded
3010	Updates completed successfully but a reboot is required

A reboot-required result does not necessarily indicate an error.

For example:

3010 = Windows Updates completed successfully.
       Windows must restart to finish applying the updates.

Safety and Design

WinPatch is designed to avoid unexpected system restarts.

In particular:

UAC elevation is requested explicitly by Windows.

The original non-admin process exits after successful elevation.

Required Windows Updates are selected by default.

Optional updates and drivers require explicit -Include_Optional.

Windows Update installation requires user confirmation.

An existing pending reboot does not automatically cause a restart.

Automatic reboot requires explicit -Auto_Reboot.

Failed updates are reported individually.

Download failures are reported separately from installation failures.

Version History
WinPatch v2.4
Added

Windows Update integration.

Required, optional, and driver update categorization.

Windows Update download and installation handling.

Individual Windows Update installation results.

Windows Update reboot detection.

Optional automatic reboot functionality.

Windows Update exit codes.

Automatic UAC self-elevation.

Automatic relaunch of the script in an elevated PowerShell process.

Preservation of command-line options during elevation.

Handling for cancelled or failed UAC elevation.

Changed

Removed the requirement to manually launch PowerShell as Administrator.

Replaced #requires -RunAsAdministrator behavior with built-in self-elevation.

The original non-administrator PowerShell process exits after launching the elevated copy.

Added administrator verification after elevation.

Updated startup information to indicate elevated execution.

Preserved existing WinGet maintenance, diagnostic logging, network snapshot, and RDP export functionality.

Windows Update Defaults
Required updates:  YES
Optional updates:  NO
Drivers:           NO
Automatic reboot:  NO

Usage
.\WinPatch.ps1

.\WinPatch.ps1 -Include_Optional

.\WinPatch.ps1 -Include_Optional -Auto_Reboot

License

See the repository license for licensing information.
