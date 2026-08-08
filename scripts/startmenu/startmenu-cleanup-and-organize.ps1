# Fix & Reorganize Start Menu
# ===============================
# 1. Disable "Recently Added" group — apps list alphabetically
# 2. Delete all broken shortcuts (Weasel, OneDrive)
# 3. Delete uninstall shortcuts (clutter)
# 4. Group Microsoft Office apps into folder
# 5. Recreate proper Rime (小狼毫) shortcuts
# 6. Group multi-shortcut publishers into folders
#
# Right-click → Run with PowerShell (as Administrator)
# ============================================================


# === CJK Encoding Fix (must be first executable lines) ===
chcp 65001 > $null
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
# ========================================================

$ErrorActionPreference = "SilentlyContinue"
$shell = New-Object -ComObject WScript.Shell

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Start Menu Cleanup & Reorganize" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$programsAll   = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs"
$programsUser  = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"

# ============================================================================
# STEP 1: Disable "Recently Added" group
# ============================================================================
Write-Host "[1/6] Disabling 'Recently Added' group..." -ForegroundColor Yellow
$adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if (-not (Test-Path $adv)) { New-Item -Path $adv -Force | Out-Null }
Set-ItemProperty -Path $adv -Name "Start_ShowRecentlyAddedApps" -Value 0 -Type DWord -Force
Write-Host "  OK — Start Menu will now list apps alphabetically, no 'Recently Added' group" -ForegroundColor Green

# ============================================================================
# STEP 2: Delete broken shortcuts
# ============================================================================
Write-Host "[2/6] Removing broken shortcuts..." -ForegroundColor Yellow

# --- 2a. Weasel folder (11 broken shortcuts → D:\...\Weasel doesn't exist) ---
$weaselDir = "$programsAll\Weasel"
if (Test-Path $weaselDir) {
    Remove-Item -Recurse -Force $weaselDir -ErrorAction SilentlyContinue
    if (-not (Test-Path $weaselDir)) {
        Write-Host "  OK — 11 broken Weasel shortcuts removed" -ForegroundColor Green
    } else {
        Write-Host "  WARN: Could not delete Weasel folder (run in Safe Mode?)" -ForegroundColor Red
    }
}

# --- 2b. OneDrive shortcut ---
$od = "$programsUser\OneDrive.lnk"
if (Test-Path $od) { Remove-Item -Force $od; Write-Host "  OK — OneDrive.lnk removed" -ForegroundColor Green }

# ============================================================================
# STEP 3: Remove uninstall shortcuts (clutter — use Settings > Apps instead)
# ============================================================================
Write-Host "[3/6] Removing uninstall shortcuts..." -ForegroundColor Yellow
$uninstallers = @(
    "$programsAll\Bandizip\Uninstall.lnk",
    "$programsAll\Foxmail\卸载 Foxmail.lnk",
    "$programsAll\WeCom\Uninstall WeCom.lnk"
)
foreach ($u in $uninstallers) {
    if (Test-Path $u) { Remove-Item -Force $u; Write-Host "  OK — $u" -ForegroundColor Gray }
}

# ============================================================================
# STEP 4: Group Microsoft Office apps into one folder
# ============================================================================
Write-Host "[4/6] Grouping Microsoft Office apps..." -ForegroundColor Yellow

$officeDir = "$programsAll\Microsoft Office"
$officeToolsDir = "$officeDir\Office 工具"
New-Item -ItemType Directory -Force -Path $officeDir | Out-Null
New-Item -ItemType Directory -Force -Path $officeToolsDir | Out-Null

# Move loose Office app shortcuts into Microsoft Office\
$officeApps = @(
    "Access.lnk", "Excel.lnk", "OneNote.lnk", "Outlook (classic).lnk",
    "PowerPoint.lnk", "Publisher.lnk", "Word.lnk", "Sticky Notes (new).lnk"
)
foreach ($app in $officeApps) {
    $src = "$programsAll\$app"
    if (Test-Path $src) {
        Move-Item -Force $src "$officeDir\" -ErrorAction SilentlyContinue
        Write-Host "  OK — $app → Microsoft Office\" -ForegroundColor Gray
    }
}

# Move old "Microsoft Office 工具" contents into new folder
$oldTools = "$programsAll\Microsoft Office 工具"
if (Test-Path $oldTools) {
    Get-ChildItem $oldTools | ForEach-Object {
        Move-Item -Force $_.FullName "$officeToolsDir\" -ErrorAction SilentlyContinue
        Write-Host "  OK — $($_.Name) → Microsoft Office\Office 工具\" -ForegroundColor Gray
    }
    Remove-Item $oldTools -Force -ErrorAction SilentlyContinue
    Write-Host "  OK — Consolidated 'Microsoft Office 工具' into Microsoft Office\Office 工具\" -ForegroundColor Green
}

# ============================================================================
# STEP 5: Create proper Rime (小狼毫) shortcuts
# ============================================================================
Write-Host "[5/6] Creating Rime (小狼毫) shortcuts..." -ForegroundColor Yellow

$rimeDir = "$programsAll\Rime"
$rimeInstalled = "D:\Program Files\Rime\weasel-0.17.0"
New-Item -ItemType Directory -Force -Path $rimeDir | Out-Null

# Name, TargetExe, Arguments
$rimeShortcuts = @(
    @("Rime Settings", "$rimeInstalled\WeaselDeployer.exe", ""),
    @("Rime Deploy",   "$rimeInstalled\WeaselDeployer.exe", "/deploy"),
    @("Rime Server",   "$rimeInstalled\WeaselServer.exe", ""),
    @("Rime Setup",    "$rimeInstalled\WeaselSetup.exe", ""),
    @("Rime User Folder", "$env:APPDATA\Rime", "folder")
)

foreach ($entry in $rimeShortcuts) {
    $name = $entry[0]
    $target = $entry[1]
    $arg = $entry[2]
    $lnk = "$rimeDir\$name.lnk"
    if (-not (Test-Path $lnk)) {
        $sc = $shell.CreateShortcut($lnk)
        if ($arg -eq "folder") {
            $sc.TargetPath = "explorer.exe"
            $sc.Arguments = "`"$target`""
        } else {
            $sc.TargetPath = $target
            if ($arg) { $sc.Arguments = $arg }
        }
        $sc.WorkingDirectory = $rimeInstalled
        $sc.Save()
        Write-Host "  OK — $name.lnk" -ForegroundColor Gray
    }
}

Write-Host "  OK — Rime shortcuts created ($($rimeShortcuts.Count) items)" -ForegroundColor Green

# ============================================================================
# STEP 6: Kill dead Yunku shell extension + restart Explorer
# ============================================================================
Write-Host "[6/6] Cleaning dead shell extensions & restarting Explorer..." -ForegroundColor Yellow

$yunkuPaths = @(
    "HKLM:\Software\Classes\*\ShellEx\ContextMenuHandlers\Yunku",
    "HKLM:\Software\Classes\Directory\ShellEx\ContextMenuHandlers\Yunku",
    "HKLM:\Software\Classes\CLSID\{545AAC68-1834-408C-B093-5EA87AE111D9}"
)
foreach ($p in $yunkuPaths) {
    if (Test-Path $p) {
        Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  OK — $p" -ForegroundColor Gray
    }
}

# Refresh Start Menu without killing Explorer (avoids hang)
Stop-Process -Name "StartMenuExperienceHost" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "ShellExperienceHost" -Force -ErrorAction SilentlyContinue

# Signal Explorer to pick up shortcut changes
$null = (New-Object -ComObject Shell.Application).Windows() | ForEach-Object {
    $_.Refresh()
}

# Restart Explorer in a detached process so script exits cleanly
Start-Process -WindowStyle Hidden cmd.exe -ArgumentList '/c timeout 2 >nul & taskkill /f /im explorer.exe 2>nul & start explorer.exe'

# ============================================================================
# Summary
# ============================================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Done — Start Menu Reorganized" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  • 'Recently Added' group disabled" -ForegroundColor White
Write-Host "  • Apps now listed alphabetically" -ForegroundColor White
Write-Host "  • 11 broken Weasel shortcuts → deleted" -ForegroundColor White
Write-Host "  • 5 new Rime shortcuts → D:\Program Files\Rime\*" -ForegroundColor White
Write-Host "  • 3 uninstall shortcuts → removed (use Settings > Apps)" -ForegroundColor White
Write-Host "  • Microsoft Office apps → grouped in 'Microsoft Office' folder" -ForegroundColor White
Write-Host "  • Dead Yunku shell extension → removed" -ForegroundColor White
Write-Host "  • Explorer restarted" -ForegroundColor White
Write-Host ""
Write-Host "  Start Menu structure now:" -ForegroundColor Cyan
Write-Host "  ├── Bandizip\Bandizip.lnk" -ForegroundColor Gray
Write-Host "  ├── Foxmail\Foxmail.lnk" -ForegroundColor Gray
Write-Host "  ├── Git\ (Git Bash, Git CMD, Git GUI, ...)" -ForegroundColor Gray
Write-Host "  ├── Microsoft Office\ (Access, Excel, Word, ... + Office 工具\)" -ForegroundColor Gray
Write-Host "  ├── OneCommander\OneCommander.lnk" -ForegroundColor Gray
Write-Host "  ├── Rime\ (Rime 设置, 重新部署, 用户文件夹, ...)" -ForegroundColor Gray
Write-Host "  └── WeCom\WeCom.lnk" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to exit"
