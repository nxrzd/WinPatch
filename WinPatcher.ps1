# =========================================
# WinPatcher v2.2
# Author: Noah Richardson
# License: MIT
# =========================================

$ErrorActionPreference = "Stop"

# =========================================
# CONFIGURATION
# =========================================

$MaxRecommendedUptimeHours = 12

$LogDirectory = Join-Path $env:ProgramData "WinPatcher"

$LogFile = Join-Path `
    $LogDirectory `
    ("WinPatcher_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".log")

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

        default {
            Write-Host $line
        }
    }

    if (-not (Test-Path $LogDirectory)) {

        New-Item `
            -ItemType Directory `
            -Path $LogDirectory `
            -Force | Out-Null
    }

    Add-Content `
        -Path $LogFile `
        -Value $line
}

function Pause-AndExit {

    param(
        [string]$Message = "Press ENTER to close..."
    )

    Write-Host ""
    Read-Host $Message
    exit
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
        Write-Host "[INFO] Requesting Administrator privileges..." `
            -ForegroundColor Yellow

        $scriptPath = $PSCommandPath

        if (-not $scriptPath) {

            $scriptPath = $MyInvocation.PSCommandPath
        }

        if (-not $scriptPath) {

            Write-Host ""
            Write-Host "Unable to determine script path." `
                -ForegroundColor Red

            Pause-AndExit
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

                Pause-AndExit
            }
        }
    }
    catch {

        Write-Log `
            "Failed to determine uptime: $_" `
            "ERROR"
    }
}

function Ensure-WinGet {

    Write-Log "Checking for WinGet..."

    $winget = Get-Command winget -ErrorAction SilentlyContinue

    if ($winget) {

        Write-Log "WinGet detected."
        return
    }

    Write-Log `
        "WinGet missing. Attempting repair..." `
        "WARN"

    try {

        $package = Get-AppxPackage `
            Microsoft.DesktopAppInstaller `
            -ErrorAction SilentlyContinue

        if (-not $package) {

            throw "Microsoft App Installer package not found."
        }

        $manifest = Join-Path `
            $package.InstallLocation `
            "AppXManifest.xml"

        Add-AppxPackage `
            -DisableDevelopmentMode `
            -Register `
            $manifest

        Start-Sleep -Seconds 5

        $winget = Get-Command winget -ErrorAction SilentlyContinue

        if (-not $winget) {

            throw "WinGet still unavailable after repair."
        }

        Write-Log "WinGet repaired successfully."
    }
    catch {

        Write-Log `
            "Failed to repair WinGet: $_" `
            "ERROR"

        Write-Host ""
        Write-Host `
            "Install App Installer from Microsoft Store:" `
            -ForegroundColor Yellow

        Write-Host `
            "https://apps.microsoft.com/detail/9NBLGGH4NNS1"

        Pause-AndExit
    }
}

function Upgrade-Packages {

    Write-Log "Starting package upgrade process..."

    try {

        winget source update | Tee-Object `
            -FilePath $LogFile `
            -Append

        winget upgrade `
            --all `
            --include-unknown `
            --accept-source-agreements `
            --accept-package-agreements `
            --silent `
            --disable-interactivity 2>&1 | Tee-Object `
                -FilePath $LogFile `
                -Append

        Write-Log "Package upgrade process completed."
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

    Clear-Host

    Write-Host ""
    Write-Host "========================================" `
        -ForegroundColor Cyan

    Write-Host "            WinPatcher v2.2             " `
        -ForegroundColor Cyan

    Write-Host "========================================" `
        -ForegroundColor Cyan

    Write-Host ""

    Ensure-Administrator

    $windowsVersion = Get-WindowsVersion

    Write-Log "Detected OS: $windowsVersion"

    Check-Uptime

    Ensure-WinGet

    Upgrade-Packages

    Write-Host ""
    Write-Host "========================================" `
        -ForegroundColor Green

    Write-Host "         Patch process complete         " `
        -ForegroundColor Green

    Write-Host "========================================" `
        -ForegroundColor Green

    Write-Host ""

    Write-Log "Patch process completed successfully."

    Write-Host "Log file saved to:"
    Write-Host $LogFile
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

    Write-Host $_.Exception.Message `
        -ForegroundColor Red

    Write-Log `
        "Fatal error: $($_.Exception.Message)" `
        "ERROR"
}

Pause-AndExit
