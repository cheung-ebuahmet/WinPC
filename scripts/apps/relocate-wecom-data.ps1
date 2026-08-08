# Relocate WeCom data: D:\Documents\WXWork → D:\Program Files\WeCom\Data
# Changes WeCom's OWN registry config (not a shortcut/junction)
# Right-click -> Run with PowerShell (as Administrator)

# === CJK Encoding Fix (must be first executable lines) ===
chcp 65001 > $null
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
# ========================================================

$ErrorActionPreference = "Stop"
$host.UI.RawUI.WindowTitle = "Relocate WeCom Data"

$oldPath = "D:\Documents\WXWork"
$newPath = "D:\Program Files\WeCom\Data"
$regKey  = "HKCU:\Software\Tencent\WXWork"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Relocate WeCom Data Directory" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Current: $oldPath" -ForegroundColor Gray
Write-Host "  Target:  $newPath" -ForegroundColor Gray
Write-Host ""

# ---- Check source ----
if (-not (Test-Path $oldPath)) {
    Write-Host "ERROR: $oldPath not found" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# ---- Check WeCom not running ----
$wecom = Get-Process -Name "WXWork" -ErrorAction SilentlyContinue
if ($wecom) {
    Write-Host "STOP: WeCom is running. Close it first." -ForegroundColor Red
    Write-Host "  1. Right-click WeCom tray icon -> Exit" -ForegroundColor Yellow
    Write-Host "  2. Or: taskkill /f /im WXWork.exe" -ForegroundColor Yellow
    Read-Host "Press Enter after closing WeCom"
    Start-Sleep -Seconds 2
    $wecom = Get-Process -Name "WXWork" -ErrorAction SilentlyContinue
    if ($wecom) {
        Write-Host "WeCom still running — aborting" -ForegroundColor Red
        exit 1
    }
}

# ---- Check destination ----
if (Test-Path $newPath) {
    Write-Host "ERROR: $newPath already exists" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# ---- 1. Move data ----
Write-Host "[1/3] Moving data..." -ForegroundColor Yellow
$sizeMB = [math]::Round((Get-ChildItem $oldPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB, 1)
Write-Host "  Size: $sizeMB MB" -ForegroundColor Gray

Move-Item -Path $oldPath -Destination $newPath -Force
if (Test-Path $newPath) {
    Write-Host "  OK — Moved to $newPath" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Move failed" -ForegroundColor Red
    exit 1
}

# ---- 2. Update registry — replace DWORD 0 with string path ----
Write-Host "[2/3] Updating WeCom data location config..." -ForegroundColor Yellow

# Remove old DWORD value
Remove-ItemProperty -Path $regKey -Name "DataLocation" -Force -ErrorAction SilentlyContinue
# Set new string path
Set-ItemProperty -Path $regKey -Name "DataLocation" -Value $newPath -Type String -Force

# Verify
$newVal = (Get-ItemProperty -Path $regKey -Name "DataLocation" -ErrorAction SilentlyContinue).DataLocation
if ($newVal -eq $newPath) {
    Write-Host "  OK — Registry: DataLocation = `"$newPath`"" -ForegroundColor Green
} else {
    Write-Host "  WARN — Registry value: $newVal (expected: $newPath)" -ForegroundColor Yellow
}

# ---- 3. Verify old path is gone ----
Write-Host "[3/3] Verifying..." -ForegroundColor Yellow
if (Test-Path $oldPath) {
    Write-Host "  WARN — $oldPath still exists (shouldn't)" -ForegroundColor Yellow
} else {
    Write-Host "  OK — Old path no longer exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Done" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Data now at : $newPath" -ForegroundColor White
Write-Host "  Registry    : HKCU\...\WXWork\DataLocation = $newPath" -ForegroundColor White
Write-Host ""
Write-Host "  Launch WeCom — it will use the new location." -ForegroundColor Green
Write-Host "  If WeCom prompts 'data not found', browse to $newPath" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"
