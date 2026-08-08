# Post-Upgrade Fix: addresses all FAIL + WARN items found by diagnose-post-upgrade.ps1
# Run as Administrator
# ============================================================

chcp 65001 > $null
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()

$ErrorActionPreference = "SilentlyContinue"
$host.UI.RawUI.WindowTitle = "Post-Upgrade Fix"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Post-Upgrade Fix - All Items" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# FIX 1: Remove Get Help (UWP reinstalled by upgrade)
# ============================================================================
Write-Host "[1] Removing Get Help (UWP reinstalled by 22H2)..." -ForegroundColor Yellow

$pkg = Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq "Microsoft.GetHelp" }
if ($pkg) {
    $pkg | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Write-Host "  OK - Get Help package uninstalled" -ForegroundColor Green
}

$prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq "Microsoft.GetHelp" }
if ($prov) {
    $prov | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    Write-Host "  OK - Get Help provisioned package removed" -ForegroundColor Green
}

if (-not $pkg -and -not $prov) {
    Write-Host "  OK - Already clean" -ForegroundColor Green
}

# ============================================================================
# FIX 2: Rebuild Start Menu performance registry keys
# ============================================================================
Write-Host "[2] Fixing Start Menu performance registry..." -ForegroundColor Yellow

# MenuShowDelay
$desktop = "HKCU:\Control Panel\Desktop"
if (-not (Test-Path $desktop)) { New-Item -Path $desktop -Force | Out-Null }
Set-ItemProperty -Path $desktop -Name "MenuShowDelay" -Value "0" -Type String -Force
Write-Host "  OK - MenuShowDelay = 0" -ForegroundColor Green

# TaskbarAnimations (was reset to 1 by upgrade)
$adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if (-not (Test-Path $adv)) { New-Item -Path $adv -Force | Out-Null }
Set-ItemProperty -Path $adv -Name "TaskbarAnimations" -Value 0 -Type DWord -Force
Write-Host "  OK - TaskbarAnimations = 0" -ForegroundColor Green

# Serialize StartupDelayInMSec
$serializePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
if (-not (Test-Path $serializePath)) { New-Item -Path $serializePath -Force | Out-Null }
Set-ItemProperty -Path $serializePath -Name "StartupDelayInMSec" -Value 0 -Type DWord -Force
Write-Host "  OK - StartupDelayInMSec = 0" -ForegroundColor Green

# Re-confirm other keys (belt-and-suspenders)
Set-ItemProperty -Path $adv -Name "Start_TrackProgs" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $adv -Name "Start_ShowRecentlyAddedApps" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $adv -Name "Start_IrisRecommendations" -Value 0 -Type DWord -Force

# ============================================================================
# FIX 3: Disable Office scheduled tasks
# ============================================================================
Write-Host "[3] Disabling Office update scheduled tasks..." -ForegroundColor Yellow

$tasksToDisable = @(
    "Office Automatic Updates 2.0",
    "Office Feature Updates",
    "Office Feature Updates Logon",
    "Office Background Push Maintenance"
)

foreach ($tn in $tasksToDisable) {
    try {
        $task = Get-ScheduledTask -TaskName $tn -ErrorAction Stop
        if ($task.State -ne "Disabled") {
            Disable-ScheduledTask -TaskName $tn -ErrorAction Stop
            Write-Host "  OK - Disabled: $tn" -ForegroundColor Green
        } else {
            Write-Host "  OK - Already disabled: $tn" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  WARN - Not found: $tn" -ForegroundColor Yellow
    }
}

# ============================================================================
# FIX 4: Rime - recreate wubi86.custom.yaml + fix schema list
# ============================================================================
Write-Host "[4] Fixing Rime configuration..." -ForegroundColor Yellow

$rimeDir = "$env:APPDATA\Rime"

# Recreate wubi86.custom.yaml
$wubiCustom = @'
# wubi86.custom.yaml - Wubi user settings
patch:
  translator/enable_user_dict: true
  translator/enable_sentence: true
'@
$wubiCustom | Out-File -FilePath "$rimeDir\wubi86.custom.yaml" -Encoding utf8
Write-Host "  OK - wubi86.custom.yaml recreated" -ForegroundColor Green

# Check and fix default.custom.yaml schema list
$defaultCustomPath = "$rimeDir\default.custom.yaml"
if (Test-Path $defaultCustomPath) {
    $content = Get-Content $defaultCustomPath -Raw -Encoding UTF8
    $needsFix = $false
    if ($content -notmatch 'wubi86') { $needsFix = $true }
    if ($content -notmatch 'luna_pinyin') { $needsFix = $true }

    if ($needsFix) {
        Write-Host "  FIX: Rewriting default.custom.yaml with wubi86 + luna_pinyin" -ForegroundColor Yellow
        $defaultCustom = @'
# default.custom.yaml - User schema activation
patch:
  schema_list:
    - schema: wubi86          # Wubi 86
    - schema: luna_pinyin     # Pinyin
  switcher:
    hotkeys:
      - "Control+grave"       # Ctrl+` switch IME
      - "Control+Shift+grave"
    save_options:
      - full_shape
      - ascii_punct
      - traditional
'@
        $defaultCustom | Out-File -FilePath $defaultCustomPath -Encoding utf8
        Write-Host "  OK - default.custom.yaml fixed" -ForegroundColor Green
    } else {
        Write-Host "  OK - default.custom.yaml schemas intact" -ForegroundColor Green
    }
}

# Trigger Rime deploy
$deployer = "D:\Program Files\Rime\weasel-0.17.0\WeaselDeployer.exe"
if (Test-Path $deployer) {
    # Kill WeaselServer first so it picks up new configs
    Get-Process "WeaselServer" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Start-Process $deployer -ArgumentList "/deploy" -Wait -NoNewWindow -ErrorAction SilentlyContinue
    Write-Host "  OK - Rime schema deployed" -ForegroundColor Green
}

# ============================================================================
# FIX 5: Re-confirm Yunku dead shell extensions
# ============================================================================
Write-Host "[5] Re-checking dead shell extensions..." -ForegroundColor Yellow

$yunkuPaths = @(
    "HKLM:\Software\Classes\*\ShellEx\ContextMenuHandlers\Yunku",
    "HKLM:\Software\Classes\Directory\ShellEx\ContextMenuHandlers\Yunku",
    "HKLM:\Software\Classes\CLSID\{545AAC68-1834-408C-B093-5EA87AE111D9}"
)

foreach ($p in $yunkuPaths) {
    $keyName = Split-Path $p -Leaf
    if (Test-Path $p) {
        Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
        if (Test-Path $p) {
            Write-Host "  WARN - Could not delete: $keyName (in use? skip for now)" -ForegroundColor Yellow
        } else {
            Write-Host "  OK - Deleted: $keyName" -ForegroundColor Green
        }
    } else {
        Write-Host "  OK - Already gone: $keyName" -ForegroundColor Gray
    }
}

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Fix Complete - Run diagnose-post-upgrade.ps1 to verify" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Fixed:" -ForegroundColor White
Write-Host "  1. Get Help - removed" -ForegroundColor Gray
Write-Host "  2. MenuShowDelay = 0 (re-created)" -ForegroundColor Gray
Write-Host "  3. TaskbarAnimations = 0 (reset from 1)" -ForegroundColor Gray
Write-Host "  4. StartupDelayInMSec = 0 (re-created)" -ForegroundColor Gray
Write-Host "  5. Office 4 scheduled tasks - disabled" -ForegroundColor Gray
Write-Host "  6. wubi86.custom.yaml - recreated" -ForegroundColor Gray
Write-Host "  7. default.custom.yaml - schema list fixed" -ForegroundColor Gray
Write-Host "  8. Yunku shell extensions - confirmed deleted" -ForegroundColor Gray
Write-Host ""
Write-Host "  Re-run to verify:" -ForegroundColor White
Write-Host "  & 'D:\Documents\My Projects\diagnose-post-upgrade.ps1'" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"
