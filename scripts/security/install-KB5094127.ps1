# KB5094127 安装脚本 — 修复 Windows 安全中心 SecHealthUI
# 需要管理员权限运行
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$host.UI.RawUI.WindowTitle = "KB5094127 Installation"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  KB5094127 安装 — 修复安全中心" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "当前 OS: $(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion"
Write-Host ""

$baseDir = "D:\Documents\Temp\kb-extract"
$ssuCab   = Join-Path $baseDir "SSU-19041.7402-x64.cab"
$mainCab  = Join-Path $baseDir "Windows10.0-KB5094127-x64.cab"

if (-not (Test-Path $mainCab)) {
    Write-Host "ERROR: KB5094127 .cab not found at $mainCab" -ForegroundColor Red
    Write-Host "请确认 D:\Documents\Temp\kb-extract 目录存在且包含更新文件" -ForegroundColor Yellow
    pause
    exit 1
}

# ── Step 1: SSU ──────────────────────────────────
Write-Host "Step 1/2: Installing Servicing Stack Update..." -ForegroundColor Yellow
if (Test-Path $ssuCab) {
    $start = Get-Date
    dism /Online /Add-Package /PackagePath:$ssuCab /NoRestart
    Write-Host "  SSU finished in $([math]::Round(((Get-Date)-$start).TotalSeconds,0))s (exit: $LASTEXITCODE)" -ForegroundColor Gray
} else {
    Write-Host "  SSU not found, skipping" -ForegroundColor Gray
}

# ── Step 2: Main KB ──────────────────────────────
Write-Host "Step 2/2: Installing KB5094127 (857MB, may take 5-10 minutes)..." -ForegroundColor Yellow
$start = Get-Date
dism /Online /Add-Package /PackagePath:$mainCab /NoRestart
$rc = $LASTEXITCODE
$elapsed = [math]::Round(((Get-Date)-$start).TotalSeconds, 0)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($rc -eq 0 -or $rc -eq 3010) {
    Write-Host "  ✅ KB5094127 installed successfully!" -ForegroundColor Green
    Write-Host "  Elapsed: ${elapsed}s" -ForegroundColor Green
    Write-Host "  Reboot required to complete" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  After reboot, check:"
    Write-Host "    1. Start Menu '&' group — ms-resource:DisplayName should be gone"
    Write-Host "    2. Windows Security icon should show normal name"
    Write-Host ""
    $confirm = Read-Host "  Restart now? (y/n)"
    if ($confirm -eq 'y') { Restart-Computer -Force }
} else {
    Write-Host "  ❌ Installation failed (exit code: $rc)" -ForegroundColor Red
    Write-Host "  DISM log: C:\Windows\Logs\DISM\dism.log" -ForegroundColor Yellow
}
Write-Host "========================================" -ForegroundColor Cyan
pause
