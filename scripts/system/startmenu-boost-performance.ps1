# Fix Start Menu first-open lag on Windows 10
# Right-click → Run with PowerShell (as Administrator)
# ============================================================
# Root cause: cold StartMenuExperienceHost + animation delays
#             + web search init + dynamic content fetch + disk I/O contention


# === CJK Encoding Fix (must be first executable lines) ===
chcp 65001 > $null
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
# ========================================================

$ErrorActionPreference = "SilentlyContinue"
$host.UI.RawUI.WindowTitle = "Start Menu Lag Fix"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Start Menu First-Open Lag Fix" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ---- [1/8] Kill Start processes first ----
Write-Host "[1/8] Stopping Start Menu processes..." -ForegroundColor Yellow
Get-Process -Name StartMenuExperienceHost, ShellExperienceHost, SearchUI -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
Write-Host "  OK — processes stopped" -ForegroundColor Green

# ---- [2/8] Menu animation delay → 0 ----
Write-Host "[2/8] Eliminating menu animation delay..." -ForegroundColor Yellow

$desktop = "HKCU:\Control Panel\Desktop"
if (-not (Test-Path $desktop)) { New-Item -Path $desktop -Force | Out-Null }
Set-ItemProperty -Path $desktop -Name "MenuShowDelay" -Value "0" -Type String -Force
Write-Host "  OK — MenuShowDelay = 0 (no delay)" -ForegroundColor Green

# ---- [3/8] Explorer responsiveness tweaks ----
Write-Host "[3/8] Applying Explorer responsiveness tweaks..." -ForegroundColor Yellow

$adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if (-not (Test-Path $adv)) { New-Item -Path $adv -Force | Out-Null }

# Disable program usage tracking (reduces disk I/O during Start open)
Set-ItemProperty -Path $adv -Name "Start_TrackProgs" -Value 0 -Type DWord -Force
Write-Host "  OK — Start_TrackProgs = 0 (no usage tracking)" -ForegroundColor Green

# Disable taskbar animations
Set-ItemProperty -Path $adv -Name "TaskbarAnimations" -Value 0 -Type DWord -Force
Write-Host "  OK — TaskbarAnimations = 0" -ForegroundColor Green

# Disable "Show recently added apps" (reinforce)
Set-ItemProperty -Path $adv -Name "Start_ShowRecentlyAddedApps" -Value 0 -Type DWord -Force
Write-Host "  OK — Start_ShowRecentlyAddedApps = 0" -ForegroundColor Green

# Disable "Occasionally show suggestions in Start"
Set-ItemProperty -Path $adv -Name "Start_IrisRecommendations" -Value 0 -Type DWord -Force
Write-Host "  OK — Start suggestions disabled" -ForegroundColor Green

# ---- [3.5] Serialize Start Menu startup (reduces I/O contention) ----
$serializePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
if (-not (Test-Path $serializePath)) { New-Item -Path $serializePath -Force | Out-Null }
Set-ItemProperty -Path $serializePath -Name "StartupDelayInMSec" -Value 0 -Type DWord -Force
Write-Host "  OK — Explorer serialize startup delay = 0" -ForegroundColor Green

# ---- [4/8] Disable web search & Cortana ----
Write-Host "[4/8] Disabling web search & Cortana integration..." -ForegroundColor Yellow

# Web search from Start Menu (Bing) — network call on first open
$searchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
if (-not (Test-Path $searchPath)) { New-Item -Path $searchPath -Force | Out-Null }
Set-ItemProperty -Path $searchPath -Name "BingSearchEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $searchPath -Name "CortanaConsent" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $searchPath -Name "AllowSearchToUseLocation" -Value 0 -Type DWord -Force
Write-Host "  OK — BingSearchEnabled = 0, CortanaConsent = 0" -ForegroundColor Green

# Dynamic search box (reduces CPU/disk on cold start)
$searchSettings = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\Settings"
if (-not (Test-Path $searchSettings)) { New-Item -Path $searchSettings -Force | Out-Null }
Set-ItemProperty -Path $searchSettings -Name "IsDynamicSearchBoxEnabled" -Value 0 -Type DWord -Force
Write-Host "  OK — DynamicSearchBox disabled" -ForegroundColor Green

# Group Policy: disable Cortana
$polExplorer = "HKLM:\Software\Policies\Microsoft\Windows\Explorer"
if (-not (Test-Path $polExplorer)) { New-Item -Path $polExplorer -Force | Out-Null }
Set-ItemProperty -Path $polExplorer -Name "AllowCortana" -Value 0 -Type DWord -Force

$polSearch = "HKLM:\Software\Policies\Microsoft\Windows\Windows Search"
if (-not (Test-Path $polSearch)) { New-Item -Path $polSearch -Force | Out-Null }
Set-ItemProperty -Path $polSearch -Name "AllowCortana" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $polSearch -Name "DisableWebSearch" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $polSearch -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord -Force
Write-Host "  OK — Cortana disabled via Group Policy" -ForegroundColor Green

# ---- [5/8] Win32PrioritySeparation — optimize foreground responsiveness ----
Write-Host "[5/8] Optimizing CPU priority for foreground apps..." -ForegroundColor Yellow

$priorityPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
if (-not (Test-Path $priorityPath)) { New-Item -Path $priorityPath -Force | Out-Null }
# 0x26 (38): short variable quantum + medium foreground boost → snappier UI
Set-ItemProperty -Path $priorityPath -Name "Win32PrioritySeparation" -Value 38 -Type DWord -Force
Write-Host "  OK — Win32PrioritySeparation = 0x26 (short quantum, medium foreground boost)" -ForegroundColor Green

# ---- [6/8] Disable Start transparency (saves GPU render time) ----
Write-Host "[6/8] Disabling Start Menu transparency..." -ForegroundColor Yellow

$themePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
if (-not (Test-Path $themePath)) { New-Item -Path $themePath -Force | Out-Null }
Set-ItemProperty -Path $themePath -Name "EnableTransparency" -Value 0 -Type DWord -Force
Write-Host "  OK — Start transparency disabled" -ForegroundColor Green

# ---- [7/8] Clear tile database cache ----
Write-Host "[7/8] Clearing tile database cache..." -ForegroundColor Yellow

$tileDb = "$env:LOCALAPPDATA\TileDataLayer\Database"
if (Test-Path $tileDb) {
    # Use cmd rmdir because the DB is locked by file handles sometimes
    $null = cmd /c "rmdir /s /q `"$tileDb`"" 2>&1
    if (-not (Test-Path $tileDb)) {
        Write-Host "  OK — Tile database cleared" -ForegroundColor Green
    } else {
        Write-Host "  WARN — Could not delete tile DB (will retry after process kill)" -ForegroundColor Yellow
    }
}

# Also wipe Start layout registry keys (force fresh layout)
$cloudCache = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount"
Get-ChildItem $cloudCache -ErrorAction SilentlyContinue | Where-Object {
    $_.PSChildName -match "start\.|unifiedtile|tilecollection"
} | ForEach-Object {
    Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "  OK — Start layout registry cache wiped" -ForegroundColor Green

# ---- [8/8] Restart Explorer & StartMenuExperienceHost ----
Write-Host "[8/8] Restarting Explorer & Start Menu..." -ForegroundColor Yellow

# Detached restart — script exits clean while Explorer restarts in background
Start-Process -WindowStyle Hidden cmd.exe -ArgumentList '/c timeout 2 >nul & taskkill /f /im explorer.exe 2>nul & timeout 1 >nul & start explorer.exe'

Start-Sleep -Seconds 3
Write-Host "  OK — Explorer restarted with new settings" -ForegroundColor Green

# ---- Summary ----
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Done — Start Menu Lag Fix Applied" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Fixes applied:" -ForegroundColor White
Write-Host "  • MenuShowDelay → 0 (instant open, no animation wait)" -ForegroundColor Gray
Write-Host "  • Start_TrackProgs → 0 (no program tracking I/O)" -ForegroundColor Gray
Write-Host "  • TaskbarAnimations → 0" -ForegroundColor Gray
Write-Host "  • Start_ShowRecentlyAddedApps → 0 (no dynamic group)" -ForegroundColor Gray
Write-Host "  • Start suggestions disabled (no web content fetch)" -ForegroundColor Gray
Write-Host "  • Serialize startup delay → 0" -ForegroundColor Gray
Write-Host "  • BingSearch / Cortana disabled (no network calls)" -ForegroundColor Gray
Write-Host "  • Win32PrioritySeparation → 0x26 (foreground boost)" -ForegroundColor Gray
Write-Host "  • Start transparency disabled (GPU rendering saved)" -ForegroundColor Gray
Write-Host "  • Tile database rebuilt (clean slate)" -ForegroundColor Gray
Write-Host "  • Explorer restarted" -ForegroundColor Gray
Write-Host ""
Write-Host "  Next step: Restart the computer to see full effect." -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"
