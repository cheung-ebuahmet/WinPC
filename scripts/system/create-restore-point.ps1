# Fix System Restore + Create today restore point - must run as Administrator


# === CJK Encoding Fix (must be first executable lines) ===
chcp 65001 > $null
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
# ========================================================

Write-Host "=== System Restore Fix ===" -ForegroundColor Cyan

# 0. Bypass 24-hour throttle
Write-Host "[0/5] Disabling 24-hour restore point throttle..." -ForegroundColor Yellow
$regPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore"
try {
    Set-ItemProperty -Path $regPath -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -Force
    Write-Host "  OK - Throttle cleared" -ForegroundColor Green
}
catch {
    Write-Host "  FAIL: $_" -ForegroundColor Red
}

# 1. Disable
Write-Host "[1/5] Disabling C: drive system restore..." -ForegroundColor Yellow
try {
    Disable-ComputerRestore -Drive "C:\"
    Write-Host "  OK - Disabled" -ForegroundColor Green
}
catch {
    Write-Host "  FAIL: $_" -ForegroundColor Red
}

# 2. Enable
Write-Host "[2/5] Re-enabling C: drive system restore..." -ForegroundColor Yellow
try {
    Enable-ComputerRestore -Drive "C:\"
    Write-Host "  OK - Enabled" -ForegroundColor Green
}
catch {
    Write-Host "  FAIL: $_" -ForegroundColor Red
}

# 3. Create restore point
Write-Host "[3/5] Creating today restore point..." -ForegroundColor Yellow
try {
    Checkpoint-Computer -Description "2026-06-18 Fix Anchor" -RestorePointType MODIFY_SETTINGS
    Write-Host "  OK - Restore point created" -ForegroundColor Green
}
catch {
    Write-Host "  FAIL: $_" -ForegroundColor Red
}

# 4. Verify
Write-Host "[4/5] Current restore points:" -ForegroundColor Yellow
try {
    Get-ComputerRestorePoint | Format-Table SequenceNumber, CreationTime, Description -AutoSize
}
catch {
    Write-Host "  FAIL: $_" -ForegroundColor Red
}

# 5. Restore throttle
Write-Host "[5/5] Restoring default throttle (1440 min)..." -ForegroundColor Yellow
try {
    Set-ItemProperty -Path $regPath -Name "SystemRestorePointCreationFrequency" -Value 1440 -Type DWord -Force
    Write-Host "  OK - Throttle restored" -ForegroundColor Green
}
catch {
    Write-Host "  FAIL: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Cyan
Write-Host "You can now open rstrui.exe to see the restore point" -ForegroundColor Green
Read-Host "Press Enter to exit"
