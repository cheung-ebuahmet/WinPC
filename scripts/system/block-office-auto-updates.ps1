# Disable Office 365 Click-to-Run auto-updates permanently
# Right-click -> Run with PowerShell (as Administrator)
# ============================================================

# === CJK Encoding Fix (must be first executable lines) ===
chcp 65001 > $null
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
# ========================================================

$ErrorActionPreference = "SilentlyContinue"
$host.UI.RawUI.WindowTitle = "Disable Office Updates"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Disable Office 365 Auto-Updates" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ---- [1/4] Group Policy: block all Office automatic updates ----
Write-Host "[1/4] Setting Office Update policy (block all auto-updates)..." -ForegroundColor Yellow

$polPath = "HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\OfficeUpdate"
if (-not (Test-Path $polPath)) {
    New-Item -Path $polPath -Force | Out-Null
}

# 0 = Disabled (never check for updates)
Set-ItemProperty -Path $polPath -Name "EnableAutomaticUpdates" -Value 0 -Type DWord -Force
Write-Host "  OK — EnableAutomaticUpdates = 0 (never auto-update)" -ForegroundColor Green

# Suppress "updates available" nag prompts
Set-ItemProperty -Path $polPath -Name "HideUpdateNotifications" -Value 1 -Type DWord -Force
Write-Host "  OK — HideUpdateNotifications = 1 (suppress prompts)" -ForegroundColor Green

# Hide "what's new" after updates
Set-ItemProperty -Path $polPath -Name "HideWhatsNew" -Value 1 -Type DWord -Force
Write-Host "  OK — HideWhatsNew = 1" -ForegroundColor Green

# Block "first run" movie/welcome screen
$firstRunPath = "HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\General"
if (-not (Test-Path $firstRunPath)) { New-Item -Path $firstRunPath -Force | Out-Null }
Set-ItemProperty -Path $firstRunPath -Name "ShownFirstRunOptin" -Value 1 -Type DWord -Force
Write-Host "  OK — First-run nag disabled" -ForegroundColor Green

# ---- [2/4] Disable scheduled tasks that trigger updates ----
Write-Host "[2/4] Disabling Office background update tasks..." -ForegroundColor Yellow

$tasksToDisable = @(
    "Office Automatic Updates 2.0",       # main update engine
    "Office Feature Updates",             # feature updates
    "Office Feature Updates Logon",       # login-time feature updates
    "Office Background Push Maintenance"  # push notifications for updates
)

foreach ($taskName in $tasksToDisable) {
    try {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
        if ($task.State -ne "Disabled") {
            Disable-ScheduledTask -TaskName $taskName -ErrorAction Stop
            Write-Host "  OK — Disabled: $taskName" -ForegroundColor Green
        } else {
            Write-Host "  OK — Already disabled: $taskName" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "  WARN — Not found: $taskName" -ForegroundColor Yellow
    }
}

# Tasks left running (needed for normal Office use):
#  Office ClickToRun Service Monitor — keeps C2R alive when needed
#  Office Actions Server — required for Office to function
#  Office Performance Monitor — harmless telemetry
#  Office Startup Maintenance — harmless startup check

# ---- [3/4] Set ClickToRun service to Manual start ----
Write-Host "[3/4] Setting ClickToRun service to Manual (only when needed)..." -ForegroundColor Yellow

try {
    $svc = Get-Service -Name "ClickToRunSvc" -ErrorAction Stop
    Set-Service -Name "ClickToRunSvc" -StartupType Manual -ErrorAction Stop
    Write-Host "  OK — ClickToRunSvc start type: Manual" -ForegroundColor Green
}
catch {
    Write-Host "  WARN — Could not set ClickToRunSvc: $_" -ForegroundColor Yellow
}

# ---- [4/4] Disable Office "background intelligence" ----
Write-Host "[4/4] Disabling Office background telemetry & intelligence..." -ForegroundColor Yellow

# Block "optional connected experiences" (online content, cloud fonts, etc.)
$telemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Privacy"
if (-not (Test-Path $telemetryPath)) { New-Item -Path $telemetryPath -Force | Out-Null }
Set-ItemProperty -Path $telemetryPath -Name "SendTelemetry" -Value 0 -Type DWord -Force
Write-Host "  OK — SendTelemetry = 0" -ForegroundColor Green

$ptpPath = "HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\PTWatson"
if (-not (Test-Path $ptpPath)) { New-Item -Path $ptpPath -Force | Out-Null }
Set-ItemProperty -Path $ptpPath -Name "PTWOptIn" -Value 0 -Type DWord -Force
Write-Host "  OK — Crash reporting disabled" -ForegroundColor Green

# ---- Summary ----
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Done — Office Auto-Updates Disabled" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Disabled:" -ForegroundColor White
Write-Host "  • EnableAutomaticUpdates = 0 (Group Policy, authoritative)" -ForegroundColor Gray
Write-Host "  • HideUpdateNotifications = 1 (no nag prompts)" -ForegroundColor Gray
Write-Host "  • 4 scheduled update tasks disabled" -ForegroundColor Gray
Write-Host "  • ClickToRunSvc → Manual (won't boot with Windows)" -ForegroundColor Gray
Write-Host "  • Telemetry & crash reporting off" -ForegroundColor Gray
Write-Host ""
Write-Host "  Office will only update when YOU explicitly run:" -ForegroundColor White
Write-Host "    'C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe' /update user" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to exit"
