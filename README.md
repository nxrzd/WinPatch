# WinPatch

WinPatch (WinPatcher v2.4) is a PowerShell utility for Windows diagnostics and application maintenance through Microsoft's WinGet package manager.

## Features

- Requests administrator privileges through Windows UAC.
- Detects the Windows version and checks system uptime.
- Reports pending reboot indicators.
- Captures a timestamped network configuration snapshot.
- Detects WinGet and attempts to repair its App Installer registration when necessary.
- Refreshes WinGet sources and upgrades installed application packages.
- Writes application logs and a PowerShell transcript.
- Exports the network snapshot to an available RDP-redirected drive when enabled.

## Requirements

- Windows 10 or Windows 11.
- Windows PowerShell 5.1 or later.
- Administrator access for maintenance operations.
- Microsoft App Installer / WinGet.
- Internet access for package source refreshes and upgrades.

Windows Terminal is not required. If WinGet cannot be restored, the script displays the official Microsoft App Installer page.

## Usage

Save the script as `WinPatcher.ps1`, open Windows PowerShell in its directory, and run:

```powershell
.\WinPatcher.ps1
```

Press **Enter** at the startup banner. If the session is not elevated, the script requests UAC elevation and relaunches itself.

The maintenance sequence captures network diagnostics, checks uptime and reboot state, verifies WinGet, refreshes package sources, and upgrades applications.

Application upgrades use `winget upgrade --all --include-unknown` with silent installation, agreement acceptance, and interactivity disabled. Review this behavior before running the script on a managed computer.

## Configuration

Edit these values near the top of `WinPatcher.ps1`:

| Setting | Default | Purpose |
| --- | --- | --- |
| `$MaxRecommendedUptimeHours` | `12` | Uptime threshold for a warning. |
| `$RdpExportEnabled` | `$true` | Enables network snapshot export when a redirected drive is available. |
| `$RdpExportPath` | `""` | Automatically discovers an RDP destination; set an explicit path to choose one. |

To retain network snapshots only on the computer running the script:

```powershell
$RdpExportEnabled = $false
```

An explicit RDP export destination must already be available to the session, for example `\\tsclient\C\WinPatcher`.

## Logs

Application logs and transcripts are stored in:

```text
%ProgramData%\WinPatcher\
```

Network snapshots are stored in:

```text
%ProgramData%\WinPatcher\NetworkLogs\
```

Filenames include timestamps. RDP export copies the network snapshot; application logs and transcripts remain local.

## Separate Windows Update project

The standalone Windows Update installer is a separate tool. It searches, downloads, and installs operating system updates and drivers through the Windows Update Agent.

Its `-Include_Optional` and `-Auto_Reboot` switches belong to that installer. They are not parameters of the WinGet maintenance script documented here.

## License

The recovered script identifies its license as MIT. See the repository's license file for the full terms.
