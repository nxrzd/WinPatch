#Requires -Version 5.1

# =========================================
# WinPatcher v2.4
# Author: https://github.com/nxrzd
# License: MIT
#
# Features:
# - Administrator elevation
# - Windows version detection
# - System uptime warning
# - Pending reboot detection
# - WinGet detection and repair
# - WinGet source update
# - Full WinGet package upgrade
# - Network configuration snapshot
# - Optional RDP redirected-drive export
# - Structured application logging
# - PowerShell transcript logging
# - Console UI / startup banner
#
# Notes:
# - Windows Terminal is NOT required by WinPatcher.
# - Network configuration is captured once.
# - Network logs remain local unless RDP export is enabled.
# =========================================

$ErrorActionPreference = "Stop"

# =========================================
# CONFIGURATION
# =========================================

$MaxRecommendedUptimeHours = 12

# RDP export:
#
# Leave empty to automatically look for an available
# RDP redirected drive under \\tsclient\.
#
# Example explicit path:
# \\tsclient\C\WinPatcher
#
# The destination must be an RDP redirected/shared
# location that is already available to this session.
#
$RdpExportPath = ""

# Set to $false if you do not want automatic RDP export.
$RdpExportEnabled = $true


# =========================================
# PATHS
# =========================================

$LogDirectory = Join-Path `
    $env:ProgramData `
    "WinPatcher"

$NetworkLogDirectory = Join-Path `
    $LogDirectory `
    "NetworkLogs"

$TimeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$LogFile = Join-Path `
    $LogDirectory `
("WinPatcher_" + $TimeStamp + ".log")

$NetworkLogFile = Join-Path `
    $NetworkLogDirectory `
("IPConfig_" + $TimeStamp + ".txt")

$TranscriptFile = Join-Path `
    $LogDirectory `
("Transcript_" + $TimeStamp + ".txt")


# =========================================
# STATE
# =========================================

$transcriptStarted = $false


# =========================================
# FUNCTIONS
# =========================================

function Write-Log {

    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $line = "[$timestamp] [$Level] $Message"

    switch ($Level) {

        "ERROR" {
            Write-Host $line -ForegroundColor Red
        }

        "WARN" {
            Write-Host $line -ForegroundColor Yellow
        }

        "SUCCESS" {
            Write-Host $line -ForegroundColor Green
        }

        default {
            Write-Host $line
        }
    }

    try {

        if (-not (Test-Path $LogDirectory)) {

            New-Item `
                -ItemType Directory `
                -Path $LogDirectory `
                -Force | Out-Null
        }

        Add-Content `
            -Path $LogFile `
            -Value $line `
            -ErrorAction Stop
    }
    catch {

        Write-Host `
            "[WARNING] Unable to write application log: $($_.Exception.Message)" `
            -ForegroundColor Yellow
    }
}


function Wait-AndExit {

    param(
        [string]$Message = "Press ENTER to close..."
    )

    Write-Host ""
    Read-Host $Message
    exit
}


function Show-Banner {

    Clear-Host

    Write-Host @'
 __      __.__      __________         __         .__
/  \    /  \__| ____\______   \_____ _/  |_  ____ |  |__   ___________
\   \/\/   /  |/    \|     ___/\__  \\   __\/ ___\|  |  \_/ __ \_  __ \
 \        /|  |   |  \    |     / __ \|  | \  \___|   Y  \  ___/|  | \/
  \__/\  / |__|___|  /____|    (____  /__|  \___  >___|  /\___  >__|
       \/          \/               \/          \/     \/     \/
'@

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "                 WINPATCHER v2.4"
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "        Windows Maintenance & Package Updater"
    Write-Host ""
    Write-Host "  Press ENTER to initiate system sequence..."
    Write-Host ""
}


function Set-ConsoleUI {

    try {

        $Host.UI.RawUI.BackgroundColor = "Black"
        $Host.UI.RawUI.ForegroundColor = "Green"

        Clear-Host
    }
    catch {
        # Some hosts do not expose RawUI properties.
    }
}


function Ensure-Administrator {

    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()

    $principal = New-Object `
        Security.Principal.WindowsPrincipal($currentIdentity)

    $isAdmin = $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    if (-not $isAdmin) {

        Write-Host ""
        Write-Host `
            "[INFO] Requesting Administrator privileges..." `
            -ForegroundColor Yellow

        $scriptPath = $PSCommandPath

        if (-not $scriptPath) {

            $scriptPath = $MyInvocation.PSCommandPath
        }

        if (-not $scriptPath) {

            Write-Host ""
            Write-Host `
                "Unable to determine script path." `
                -ForegroundColor Red

            Wait-AndExit
        }

        $arguments = @(
            "-NoProfile"
            "-ExecutionPolicy"
            "Bypass"
            "-File"
            "`"$scriptPath`""
        )

        Start-Process `
            -FilePath "powershell.exe" `
            -Verb RunAs `
            -ArgumentList $arguments

        exit
    }
}


function Get-WindowsVersion {

    try {

        $os = Get-CimInstance Win32_OperatingSystem

        $build = [int]$os.BuildNumber

        if ($build -ge 22000) {

            return "Windows 11"
        }

        return "Windows 10"
    }
    catch {

        return "Unknown Windows Version"
    }
}


function Check-Uptime {

    try {

        $lastBoot = (
            Get-CimInstance Win32_OperatingSystem
        ).LastBootUpTime

        $uptime = (Get-Date) - $lastBoot

        $uptimeHours = [math]::Round(
            $uptime.TotalHours,
            1
        )

        Write-Log "System uptime: $uptimeHours hours"

        if ($uptimeHours -gt $MaxRecommendedUptimeHours) {

            Write-Host ""
            Write-Host `
                "WARNING: System uptime exceeds $MaxRecommendedUptimeHours hours." `
                -ForegroundColor Yellow

            Write-Host `
                "A restart is recommended before patching." `
                -ForegroundColor Yellow

            Write-Host ""

            $choice = Read-Host "Continue anyway? (Y/N)"

            if ($choice -notmatch '^[Yy]$') {

                Write-Log `
                    "User cancelled due to uptime warning." `
                    "WARN"

                Wait-AndExit
            }
        }
    }
    catch {

        Write-Log `
            "Failed to determine uptime: $_" `
            "ERROR"
    }
}


function Test-PendingReboot {

    Write-Log "Checking for pending reboot status..."

    try {

        $pendingReasons = @()

        # Windows Update reboot requirement
        $windowsUpdateReboot = Test-Path `
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"

        if ($windowsUpdateReboot) {

            $pendingReasons += "Windows Update"
        }


        # Component Based Servicing
        $cbsReboot = Test-Path `
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"

        if ($cbsReboot) {

            $pendingReasons += "Component Based Servicing"
        }


        # Pending file rename operations
        $sessionManagerPath = `
            "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"

        $pendingFileRename = Get-ItemProperty `
            -Path $sessionManagerPath `
            -Name "PendingFileRenameOperations" `
            -ErrorAction SilentlyContinue

        if ($pendingFileRename) {

            $pendingReasons += "Pending file operations"
        }


        if ($pendingReasons.Count -gt 0) {

            $reasonText = $pendingReasons -join ", "

            Write-Log `
                "A system reboot appears to be pending: $reasonText" `
                "WARN"

            Write-Host ""
            Write-Host `
                "WARNING: Windows indicates that a reboot is pending." `
                -ForegroundColor Yellow

            Write-Host `
                "Detected: $reasonText" `
                -ForegroundColor Yellow

            Write-Host ""
            Write-Host `
                "A restart may be advisable before continuing." `
                -ForegroundColor Yellow

            Write-Host ""

            $choice = Read-Host "Continue patching anyway? (Y/N)"

            if ($choice -notmatch '^[Yy]$') {

                Write-Log `
                    "User cancelled because a reboot was pending." `
                    "WARN"

                Wait-AndExit
            }

            Write-Log `
                "User chose to continue despite pending reboot." `
                "WARN"
        }
        else {

            Write-Log `
                "No pending reboot indicators detected." `
                "SUCCESS"
        }
    }
    catch {

        Write-Log `
            "Unable to determine pending reboot status: $_" `
            "WARN"
    }
}


function Capture-NetworkConfiguration {

    Write-Log "Capturing network configuration..."

    try {

        if (-not (Test-Path $NetworkLogDirectory)) {

            New-Item `
                -ItemType Directory `
                -Path $NetworkLogDirectory `
                -Force | Out-Null
        }

        $header = @"
============================================================
 NETWORK CONFIGURATION SNAPSHOT
============================================================

Date: $(Get-Date)
Machine: $env:COMPUTERNAME
User: $env:USERNAME
OS: $(Get-WindowsVersion)

============================================================

"@

        # Capture ONCE.
        $networkOutput = ipconfig /all

        # Write the complete snapshot to the dedicated
        # network log only.
        $header |
        Out-File `
            -FilePath $NetworkLogFile `
            -Encoding UTF8

        $networkOutput |
        Out-File `
            -FilePath $NetworkLogFile `
            -Append `
            -Encoding UTF8

        Write-Log `
            "Network configuration saved to: $NetworkLogFile" `
            "SUCCESS"

        return $true
    }
    catch {

        Write-Log `
            "Failed to capture network configuration: $_" `
            "ERROR"

        return $false
    }
}


function Find-RdpRedirectedPath {

    if (-not $RdpExportEnabled) {

        return $null
    }

    # If explicitly configured, use that.
    if (-not [string]::IsNullOrWhiteSpace($RdpExportPath)) {

        if (Test-Path $RdpExportPath) {

            return $RdpExportPath
        }

        Write-Log `
            "Configured RDP export path is unavailable: $RdpExportPath" `
            "WARN"

        return $null
    }


    # Automatically look for RDP client redirected drives.
    $tsClientRoot = "\\tsclient"

    if (-not (Test-Path $tsClientRoot)) {

        Write-Log `
            "No RDP redirected drives detected." `
            "WARN"

        return $null
    }

    try {

        $redirectedDrives = Get-ChildItem `
            -Path $tsClientRoot `
            -Directory `
            -ErrorAction Stop

        foreach ($drive in $redirectedDrives) {

            $candidate = $drive.FullName

            if (Test-Path $candidate) {

                return $candidate
            }
        }
    }
    catch {

        Write-Log `
            "Unable to enumerate RDP redirected drives: $_" `
            "WARN"
    }

    return $null
}


function Export-NetworkLogToRdp {

    param(
        [string]$SourceFile
    )

    if (-not $RdpExportEnabled) {

        Write-Log `
            "RDP network-log export is disabled." `
            "INFO"

        return
    }

    if (-not (Test-Path $SourceFile)) {

        Write-Log `
            "Network log does not exist; RDP export skipped." `
            "WARN"

        return
    }

    $rdpRoot = Find-RdpRedirectedPath

    if (-not $rdpRoot) {

        Write-Log `
            "No available RDP redirected location found. Network log remains local." `
            "WARN"

        return
    }

    try {

        $exportDirectory = Join-Path `
            $rdpRoot `
            "WinPatcher"

        if (-not (Test-Path $exportDirectory)) {

            New-Item `
                -ItemType Directory `
                -Path $exportDirectory `
                -Force | Out-Null
        }

        $destination = Join-Path `
            $exportDirectory `
        (Split-Path $SourceFile -Leaf)

        Copy-Item `
            -Path $SourceFile `
            -Destination $destination `
            -Force

        Write-Log `
            "Network log exported through the RDP redirected location." `
            "SUCCESS"

        Write-Host ""
        Write-Host "RDP export:"
        Write-Host "     $destination"
        Write-Host ""
    }
    catch {

        Write-Log `
            "RDP network-log export failed: $_" `
            "WARN"
    }
}


function Ensure-WinGet {

    Write-Log "Checking for WinGet..."

    $winget = Get-Command `
        winget `
        -ErrorAction SilentlyContinue

    if ($winget) {

        Write-Log `
            "WinGet detected." `
            "SUCCESS"

        return
    }

    Write-Log `
        "WinGet missing. Attempting App Installer repair..." `
        "WARN"

    try {

        $package = Get-AppxPackage `
            Microsoft.DesktopAppInstaller `
            -ErrorAction SilentlyContinue

        if ($package) {

            $manifest = Join-Path `
                $package.InstallLocation `
                "AppXManifest.xml"

            if (Test-Path $manifest) {

                Write-Log `
                    "Registering App Installer manifest..." `
                    "INFO"

                Add-AppxPackage `
                    -DisableDevelopmentMode `
                    -Register `
                    $manifest

                Start-Sleep -Seconds 5
            }
        }
        else {

            Write-Log `
                "App Installer package not found for current user." `
                "WARN"
        }

        $winget = Get-Command `
            winget `
            -ErrorAction SilentlyContinue

        if (-not $winget) {

            Write-Log `
                "Manifest repair did not restore WinGet. Trying family registration fallback..." `
                "WARN"

            try {

                Add-AppxPackage `
                    -RegisterByFamilyName `
                    -MainPackage `
                    "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe"

                Start-Sleep -Seconds 5
            }
            catch {

                Write-Log `
                    "Family registration fallback failed: $_" `
                    "WARN"
            }
        }

        $winget = Get-Command `
            winget `
            -ErrorAction SilentlyContinue

        if (-not $winget) {

            throw "WinGet remains unavailable after App Installer repair attempts."
        }

        Write-Log `
            "WinGet repaired successfully." `
            "SUCCESS"
    }
    catch {

        Write-Log `
            "Unable to repair WinGet: $_" `
            "ERROR"

        Write-Host ""
        Write-Host `
            "Microsoft App Installer is required for WinGet." `
            -ForegroundColor Yellow

        Write-Host ""
        Write-Host `
            "Official Microsoft App Installer page:" `
            -ForegroundColor Yellow

        Write-Host `
            "https://apps.microsoft.com/detail/9NBLGGH4NNS1" `
            -ForegroundColor Yellow

        Write-Host ""

        Wait-AndExit
    }
}


function Update-WinGetSources {

    Write-Log "Updating WinGet sources..."

    try {

        winget source update `
            --disable-interactivity 2>&1 |
        Tee-Object `
            -FilePath $LogFile `
            -Append

        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {

            Write-Log `
                "WinGet sources updated successfully." `
                "SUCCESS"
        }
        else {

            Write-Log `
                "WinGet source update returned exit code $exitCode." `
                "WARN"
        }
    }
    catch {

        Write-Log `
            "WinGet source update failed: $_" `
            "WARN"
    }
}


function Upgrade-Packages {

    Write-Log "Starting package upgrade process..."

    try {

        $upgradeArgs = @(
            "upgrade"
            "--all"
            "--include-unknown"
            "--accept-source-agreements"
            "--accept-package-agreements"
            "--silent"
            "--disable-interactivity"
        )

        & winget @upgradeArgs 2>&1 |
        Tee-Object `
            -FilePath $LogFile `
            -Append

        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {

            Write-Log `
                "Package upgrade process completed successfully." `
                "SUCCESS"
        }
        else {

            Write-Log `
                "WinGet upgrade returned exit code $exitCode." `
                "WARN"
        }
    }
    catch {

        Write-Log `
            "WinGet upgrade process failed: $_" `
            "ERROR"
    }
}


# =========================================
# MAIN
# =========================================

try {

    # -------------------------------------
    # Console initialization
    # -------------------------------------

    Set-ConsoleUI

    Show-Banner

    do {

        $key = $Host.UI.RawUI.ReadKey(
            "NoEcho,IncludeKeyDown"
        )

    } until ($key.VirtualKeyCode -eq 13)

    Clear-Host


    # -------------------------------------
    # Administrator elevation
    # -------------------------------------

    Ensure-Administrator


    # -------------------------------------
    # Create directories
    # -------------------------------------

    if (-not (Test-Path $LogDirectory)) {

        New-Item `
            -ItemType Directory `
            -Path $LogDirectory `
            -Force | Out-Null
    }

    if (-not (Test-Path $NetworkLogDirectory)) {

        New-Item `
            -ItemType Directory `
            -Path $NetworkLogDirectory `
            -Force | Out-Null
    }


    # -------------------------------------
    # Start transcript
    # -------------------------------------

    try {

        Start-Transcript `
            -Path $TranscriptFile `
            -ErrorAction Stop |
        Out-Null

        $transcriptStarted = $true
    }
    catch {

        $transcriptStarted = $false

        Write-Host `
            "[WARNING] Unable to start transcript: $($_.Exception.Message)" `
            -ForegroundColor Yellow
    }


    # -------------------------------------
    # Initialize log
    # -------------------------------------

    Write-Log "========================================="
    Write-Log "WinPatcher v2.4 starting."
    Write-Log "Computer: $env:COMPUTERNAME"
    Write-Log "User: $env:USERNAME"
    Write-Log "========================================="


    # -------------------------------------
    # Windows version
    # -------------------------------------

    $windowsVersion = Get-WindowsVersion

    Write-Log `
        "Detected OS: $windowsVersion"


    # -------------------------------------
    # Network configuration
    # -------------------------------------

    Write-Host ""
    Write-Host "[+] Capturing Network Configuration..."

    $networkCaptureSuccessful = `
        Capture-NetworkConfiguration

    if ($networkCaptureSuccessful) {

        Write-Host ""
        Write-Host "[OK] Network log saved to:"
        Write-Host "     $NetworkLogFile"
        Write-Host ""
    }


    # -------------------------------------
    # Optional RDP export
    # -------------------------------------

    Export-NetworkLogToRdp `
        -SourceFile $NetworkLogFile


    # -------------------------------------
    # Uptime check
    # -------------------------------------

    Check-Uptime


    # -------------------------------------
    # Pending reboot check
    # -------------------------------------

    Test-PendingReboot


    # -------------------------------------
    # WinGet
    # -------------------------------------

    Ensure-WinGet

    Write-Host ""


    # -------------------------------------
    # Update WinGet sources
    # -------------------------------------

    Update-WinGetSources

    Write-Host ""


    # -------------------------------------
    # Upgrade packages
    # -------------------------------------

    Write-Host "[+] Running winget upgrade..."
    Write-Host ""

    Upgrade-Packages


    # -------------------------------------
    # Completion
    # -------------------------------------

    Write-Host ""
    Write-Host "========================================" `
        -ForegroundColor Green

    Write-Host "         Patch process complete         " `
        -ForegroundColor Green

    Write-Host "========================================" `
        -ForegroundColor Green

    Write-Host ""

    Write-Log `
        "Patch process completed." `
        "SUCCESS"

    Write-Host "Log file saved to:"
    Write-Host $LogFile

    Write-Host ""
    Write-Host "Network log saved to:"
    Write-Host $NetworkLogFile

    Write-Host ""

}
catch {

    Write-Host ""
    Write-Host "========================================" `
        -ForegroundColor Red

    Write-Host "             FATAL ERROR                " `
        -ForegroundColor Red

    Write-Host "========================================" `
        -ForegroundColor Red

    Write-Host ""

    Write-Host `
        $_.Exception.Message `
        -ForegroundColor Red

    try {

        Write-Log `
            "Fatal error: $($_.Exception.Message)" `
            "ERROR"
    }
    catch {
        # Logging failure should not hide original error.
    }
}
finally {

    if ($transcriptStarted) {

        try {

            Stop-Transcript |
            Out-Null
        }
        catch {
            # Transcript may already have stopped.
        }
    }
}

Wait-AndExit
