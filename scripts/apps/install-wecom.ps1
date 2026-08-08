# WeCom silent install + disable auto-update
# Run as Administrator


# === CJK Encoding Fix (must be first executable lines) ===
chcp 65001 > $null
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
# ========================================================

$installer = "D:\Applications\WeCom_5.0.8.6009.exe"
$installDir = "D:\Program Files\WeCom"

Write-Host "=== WeCom Install ===" -ForegroundColor Cyan

# 1. Create target directory
Write-Host "[1/4] Creating install directory: $installDir" -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $installDir | Out-Null
Write-Host "  OK" -ForegroundColor Green

# 2. Silent install
# WeCom uses NSIS installer. /S = silent, /D= must be LAST param, no quotes, no trailing backslash
Write-Host "[2/4] Installing WeCom silently to $installDir ..." -ForegroundColor Yellow
$proc = Start-Process -FilePath $installer -ArgumentList "/S /D=$installDir" -Wait -PassThru
Write-Host "  Exit code: $($proc.ExitCode)" -ForegroundColor $(if ($proc.ExitCode -eq 0) { "Green" } else { "Red" })

# 3. Disable auto-update via registry
# WeCom stores update settings in HKCU
Write-Host "[3/4] Disabling auto-update..." -ForegroundColor Yellow
$regPath = "HKCU:\Software\Tencent\WeWork"
try {
    New-Item -Path $regPath -Force | Out-Null
    Set-ItemProperty -Path $regPath -Name "DisableUpdate" -Value 1 -Type DWord -Force
    Write-Host "  OK - Auto-update disabled" -ForegroundColor Green
} catch {
    Write-Host "  FAIL: $_" -ForegroundColor Red
}

# Also check HKLM
$regPathLM = "HKLM:\Software\Tencent\WeWork"
try {
    New-Item -Path $regPathLM -Force | Out-Null
    Set-ItemProperty -Path $regPathLM -Name "DisableUpdate" -Value 1 -Type DWord -Force
} catch { }

# 4. Verify
Write-Host "[4/4] Verification:" -ForegroundColor Yellow
$wecomExe = "$installDir\WXWork.exe"
if (Test-Path $wecomExe) {
    $ver = (Get-Item $wecomExe).VersionInfo
    Write-Host "  Installed: $wecomExe" -ForegroundColor Green
    Write-Host "  Version:   $($ver.ProductVersion)" -ForegroundColor Green
} else {
    Write-Host "  WARNING: WXWork.exe not found. Checking directory..." -ForegroundColor Yellow
    Get-ChildItem $installDir -Recurse -Filter "*.exe" | Select-Object -First 5 | ForEach-Object { Write-Host "  Found: $($_.FullName)" }
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Cyan
Read-Host "Press Enter to exit"
