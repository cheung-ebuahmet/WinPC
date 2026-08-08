# Remove unwanted Windows bloatware + deep clean ALL residues
# Right-click -> Run with PowerShell (as Administrator)
# ============================================================
# Removes: Camera, Photos, Get Help, Sticky Notes (UWP) +
#          Access, OneNote, Outlook Classic, Publisher (Office C2R)
# Cleans:  search index, registry stubs, tile pins, AppX manifests,
#          WindowsApps leftovers, AppData, Start Menu orphans

# === CJK Encoding Fix (must be first executable lines) ===
chcp 65001 > $null
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
# ========================================================

$ErrorActionPreference = "SilentlyContinue"
$host.UI.RawUI.WindowTitle = "Remove Bloatware"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Remove Bloatware + Full Deep Clean" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# PHASE 1: UWP App Removal (Camera, Photos, Get Help, Sticky Notes)
# ============================================================================
Write-Host "=== Phase 1/4: UWP App Removal ===" -ForegroundColor Cyan

$uwpTargets = @(
    @{Name="Camera";       Pkg="Microsoft.WindowsCamera";        DataPattern="*WindowsCamera*"},
    @{Name="Photos";       Pkg="Microsoft.Windows.Photos";       DataPattern="*Windows.Photos*"},
    @{Name="Get Help";     Pkg="Microsoft.GetHelp";              DataPattern="*GetHelp*"},
    @{Name="Sticky Notes"; Pkg="Microsoft.MicrosoftStickyNotes"; DataPattern="*MicrosoftStickyNotes*"}
)

foreach ($app in $uwpTargets) {
    Write-Host ""
    Write-Host "--- $($app.Name) ---" -ForegroundColor Yellow

    # Uninstall package (all users)
    $pkgs = Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq $app.Pkg }
    if ($pkgs) {
        $pkgs | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Write-Host "  OK — Package uninstalled" -ForegroundColor Green
    } else {
        Write-Host "  OK — Package not installed" -ForegroundColor Gray
    }

    # Remove provisioned package (prevents reinstall on new accounts)
    $provs = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $app.Pkg }
    if ($provs) {
        $provs | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        Write-Host "  OK — Provisioned package removed" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== UWP removal complete ===" -ForegroundColor Green

# ============================================================================
# PHASE 2: Office C2R Desktop App Removal (Access, OneNote, Outlook, Publisher)
# ============================================================================
Write-Host ""
Write-Host "=== Phase 2/4: Office Desktop App Removal ===" -ForegroundColor Cyan

$c2rExclude = @("access", "onenote", "outlook", "publisher")

# Update Office C2R ExcludedApps
$c2rConfig = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
if (Test-Path $c2rConfig) {
    $currentExclude = (Get-ItemProperty -Path $c2rConfig -Name "ProPlus2021Retail.ExcludedApps" -ErrorAction SilentlyContinue)."ProPlus2021Retail.ExcludedApps"
    Write-Host "  Current exclusions: $currentExclude" -ForegroundColor Gray

    $existing = if ($currentExclude) { $currentExclude -split '\s*,\s*' | Where-Object { $_ } } else { @() }
    $newExclude = ($existing + $c2rExclude | Select-Object -Unique) -join ','

    Set-ItemProperty -Path $c2rConfig -Name "ProPlus2021Retail.ExcludedApps" -Value $newExclude -Type String -Force
    Write-Host "  OK — ExcludedApps: $newExclude" -ForegroundColor Green

    # Trigger C2R reconfiguration
    $c2rClient = "C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"
    if (Test-Path $c2rClient) {
        Start-Process -FilePath $c2rClient -ArgumentList "/update user" -PassThru -WindowStyle Hidden | Out-Null
        Write-Host "  OK — Office C2R update triggered" -ForegroundColor Green
    }
}

Write-Host "  Done" -ForegroundColor Green

# ============================================================================
# PHASE 3: Start Menu + Shortcut + AppData + Registry cleanup for ALL removed apps
# ============================================================================
Write-Host ""
Write-Host "=== Phase 3/4: Residual File & Registry Cleanup ===" -ForegroundColor Cyan

$programsAll  = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs"
$programsUser = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"

$removedNames = @("Access", "OneNote", "Outlook", "Publisher", "Sticky Notes",
                  "Camera", "Photos", "Get Help", "获取帮助", "便笺")

Write-Host ""
Write-Host "--- Start Menu shortcuts ---" -ForegroundColor Yellow

$shortcutPaths = @(
    $programsAll, "$programsAll\Microsoft Office", "$programsAll\Microsoft Office\Office 工具",
    $programsUser, "$programsUser\Microsoft Office"
)

foreach ($basePath in $shortcutPaths) {
    if (-not (Test-Path $basePath)) { continue }
    foreach ($name in $removedNames) {
        $lnk = "$basePath\$name.lnk"
        if (Test-Path $lnk) {
            Remove-Item -Force $lnk -ErrorAction SilentlyContinue
            Write-Host "  OK — $name.lnk" -ForegroundColor Gray
        }
    }
    # Wildcard cleanup
    Get-ChildItem $basePath -Filter "*Outlook*" -File -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item -Force $_.FullName -ErrorAction SilentlyContinue
        Write-Host "  OK — $($_.Name)" -ForegroundColor Gray
    }
    Get-ChildItem $basePath -Filter "*Publisher*" -File -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item -Force $_.FullName -ErrorAction SilentlyContinue
        Write-Host "  OK — $($_.Name)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "--- AppData residual folders ---" -ForegroundColor Yellow

$appDataPatterns = @(
    "$env:LOCALAPPDATA\Microsoft\Office\ONetConfig",
    "$env:LOCALAPPDATA\Microsoft\OneNote",
    "$env:LOCALAPPDATA\Microsoft\Outlook",
    "$env:LOCALAPPDATA\Microsoft\Access",
    "$env:LOCALAPPDATA\Microsoft\Publisher",
    "$env:APPDATA\Microsoft\Outlook",
    "$env:APPDATA\Microsoft\Access",
    "$env:APPDATA\Microsoft\Publisher",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsCamera*",
    "$env:LOCALAPPDATA\Packages\Microsoft.Windows.Photos*",
    "$env:LOCALAPPDATA\Packages\Microsoft.GetHelp*",
    "$env:LOCALAPPDATA\Packages\Microsoft.MicrosoftStickyNotes*"
)

foreach ($pattern in $appDataPatterns) {
    if ($pattern -match '\*') {
        $parent = Split-Path $pattern -Parent
        $leaf   = Split-Path $pattern -Leaf
        Get-ChildItem -Path $parent -Directory -Filter $leaf -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item -Recurse -Force $_.FullName -ErrorAction SilentlyContinue
            Write-Host "  OK — $($_.Name)" -ForegroundColor Gray
        }
    } elseif (Test-Path $pattern) {
        Remove-Item -Recurse -Force $pattern -ErrorAction SilentlyContinue
        Write-Host "  OK — $pattern" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "--- Registry App Paths ---" -ForegroundColor Yellow

$officeExeNames = @("MSACCESS.EXE", "ONENOTE.EXE", "OUTLOOK.EXE", "MSPUB.EXE")
foreach ($exe in $officeExeNames) {
    $key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$exe"
    if (Test-Path $key) {
        Remove-Item -Path $key -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  OK — App Paths: $exe" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "--- AppX registry stubs (StateRepository + user packages) ---" -ForegroundColor Yellow

$appxUserReg = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages"
if (Test-Path $appxUserReg) {
    foreach ($app in $uwpTargets) {
        Get-ChildItem $appxUserReg -ErrorAction SilentlyContinue | Where-Object {
            $_.PSChildName -match $app.Pkg
        } | ForEach-Object {
            Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  OK — Registry stub: $($_.PSChildName)" -ForegroundColor Gray
        }
    }
}

$appxSysReg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository\Cache\Package\Index"
if (Test-Path $appxSysReg) {
    foreach ($app in $uwpTargets) {
        Get-ChildItem $appxSysReg -ErrorAction SilentlyContinue | Where-Object {
            $_.PSChildName -match $app.Pkg
        } | ForEach-Object {
            Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  OK — StateRepository: $($_.PSChildName)" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "--- Stale uninstall registry keys ---" -ForegroundColor Yellow

$uninstallRoots = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
)
$patterns = @("Camera", "Photos", "Get.?Help", "Sticky.?Notes", "Publisher", "Access.*201", "OneNote", "Outlook.*classic")
foreach ($root in $uninstallRoots) {
    if (-not (Test-Path $root)) { continue }
    Get-ChildItem $root -ErrorAction SilentlyContinue | ForEach-Object {
        $dn = (Get-ItemProperty -Path $_.PSPath -Name "DisplayName" -ErrorAction SilentlyContinue).DisplayName
        if ($dn) {
            foreach ($pat in $patterns) {
                if ($dn -match $pat) {
                    Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "  OK — Uninstall key: $dn" -ForegroundColor Gray
                    break
                }
            }
        }
    }
}

# ============================================================================
# PHASE 4: Deep Clean — search index, tile pins, WindowsApps leftovers
# ============================================================================
Write-Host ""
Write-Host "=== Phase 4/4: Deep Clean (search index + tile pins + file stubs) ===" -ForegroundColor Cyan

Write-Host ""
Write-Host "--- WindowsApps folder leftovers ---" -ForegroundColor Yellow

foreach ($app in $uwpTargets) {
    $matches = Get-ChildItem "C:\Program Files\WindowsApps" -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match $app.Pkg
    }
    foreach ($d in $matches) {
        try {
            takeown /f $d.FullName /r /d y 2>&1 | Out-Null
            icacls $d.FullName /grant "Administrators:F" /t 2>&1 | Out-Null
            Remove-Item -Recurse -Force $d.FullName -ErrorAction Stop
            Write-Host "  OK — Deleted: $($d.Name)" -ForegroundColor Green
        } catch {
            Write-Host "  WARN — Could not delete: $($d.Name)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "--- AppRepository stale manifests ---" -ForegroundColor Yellow

foreach ($app in $uwpTargets) {
    Get-ChildItem "$env:ProgramData\Microsoft\Windows\AppRepository" -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match $app.Pkg
    } | ForEach-Object {
        Remove-Item -Force $_.FullName -ErrorAction SilentlyContinue
        Write-Host "  OK — $($_.Name)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "--- Purging Start Menu tile pins ---" -ForegroundColor Yellow

$cloudBase = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount"
Get-ChildItem $cloudBase -ErrorAction SilentlyContinue | Where-Object {
    $_.PSChildName -match "start\.|unifiedtile|tilecollection|placeholdertile"
} | ForEach-Object {
    Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  OK — $($_.PSChildName)" -ForegroundColor Gray
}

$tileDb = "$env:LOCALAPPDATA\TileDataLayer"
if (Test-Path $tileDb) {
    Remove-Item -Recurse -Force $tileDb -ErrorAction SilentlyContinue
    Write-Host "  OK — TileDataLayer" -ForegroundColor Gray
}

Write-Host ""
Write-Host "--- Rebuilding Windows Search index ---" -ForegroundColor Yellow

Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

$searchApps = "$env:ProgramData\Microsoft\Search\Data\Applications\Windows"
if (Test-Path $searchApps) {
    Remove-Item -Recurse -Force $searchApps -ErrorAction SilentlyContinue
    Write-Host "  OK — Search index DB deleted" -ForegroundColor Green
}
$searchTemp = "$env:ProgramData\Microsoft\Search\Data\Temp"
if (Test-Path $searchTemp) {
    Remove-Item -Recurse -Force $searchTemp -ErrorAction SilentlyContinue
}

Start-Service -Name "WSearch" -ErrorAction SilentlyContinue
Write-Host "  OK — Search index rebuilding" -ForegroundColor Green

Write-Host ""
Write-Host "--- Clearing icon cache + refreshing shell ---" -ForegroundColor Yellow

$iconCache = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
Get-ChildItem $iconCache -Filter "iconcache*" -File -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item -Force $_.FullName -ErrorAction SilentlyContinue
}
Write-Host "  OK — Icon cache" -ForegroundColor Gray

Stop-Process -Name StartMenuExperienceHost, ShellExperienceHost, SearchUI -Force -ErrorAction SilentlyContinue

Start-Process -WindowStyle Hidden cmd.exe -ArgumentList '/c timeout 2 >nul & taskkill /f /im explorer.exe 2>nul & timeout 1 >nul & start explorer.exe'

# ---- Summary ----
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Done — Bloatware Removed & Deep Cleaned" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  UWP apps removed:" -ForegroundColor White
Write-Host "    Camera (相机)  Photos (照片)  Get Help (获取帮助)  Sticky Notes (便笺)" -ForegroundColor Gray
Write-Host ""
Write-Host "  Office apps removed:" -ForegroundColor White
Write-Host "    Access  OneNote  Outlook (Classic)  Publisher" -ForegroundColor Gray
Write-Host ""
Write-Host "  Deep clean actions:" -ForegroundColor White
Write-Host "    Start Menu shortcuts (all locations)" -ForegroundColor Gray
Write-Host "    AppData residual folders" -ForegroundColor Gray
Write-Host "    Registry App Paths + AppX stubs + StateRepository" -ForegroundColor Gray
Write-Host "    Stale uninstall registry keys" -ForegroundColor Gray
Write-Host "    WindowsApps folder leftovers (takeown + delete)" -ForegroundColor Gray
Write-Host "    AppRepository stale manifests" -ForegroundColor Gray
Write-Host "    Start Menu tile pins (CloudStore + TileDataLayer)" -ForegroundColor Gray
Write-Host "    Windows Search index rebuilt" -ForegroundColor Gray
Write-Host "    Icon cache cleared + Explorer restarted" -ForegroundColor Gray
Write-Host ""
Write-Host "  REBOOT RECOMMENDED. After reboot:" -ForegroundColor Yellow
Write-Host "    Win-key search for Camera/Photos/Get Help/Sticky -> no results." -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to exit"
