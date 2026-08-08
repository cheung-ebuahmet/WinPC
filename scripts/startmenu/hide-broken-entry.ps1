# Hide ms-resource:DisplayName from Start Menu all-apps list
# Sets AppListEntry="none" — app stays fully functional, just hidden from list
# Fully reversible: restore AppxManifest.xml.backup
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$manifestPath = "C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy\AppxManifest.xml"
$backupPath  = "$manifestPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Hide SecHealthUI from Start Menu" -ForegroundColor Cyan
Write-Host "  (app stays fully functional)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Take ownership
Write-Host "[1/5] Taking ownership of manifest directory..." -ForegroundColor Yellow
takeown /f "$manifestPath" 2>&1 | Out-Null
icacls "$manifestPath" /grant "BUILTIN\Administrators:(F)" 2>&1 | Out-Null
Write-Host "  Ownership acquired" -ForegroundColor Green

# Step 2: Backup
Write-Host "[2/5] Creating backup..." -ForegroundColor Yellow
Copy-Item $manifestPath $backupPath -Force
Write-Host "  Backup: $backupPath" -ForegroundColor Green

# Step 3: Check current value
Write-Host "[3/5] Reading current setting..." -ForegroundColor Yellow
[xml]$manifest = Get-Content $manifestPath
$ns = New-Object Xml.XmlNamespaceManager($manifest.NameTable)
$ns.AddNamespace("d", "http://schemas.microsoft.com/appx/manifest/foundation/windows10")
$ns.AddNamespace("uap", "http://schemas.microsoft.com/appx/manifest/uap/windows10")
$app = $manifest.SelectSingleNode("//d:Package/d:Applications/d:Application", $ns)
$visuals = $app.SelectSingleNode("uap:VisualElements", $ns)
Write-Host "  Current AppListEntry: '$($visuals.AppListEntry)' (empty=default=shown)"
Write-Host "  Current DisplayName: $($visuals.DisplayName)"

# Step 4: Set AppListEntry="none"
Write-Host "[4/5] Setting AppListEntry='none'..." -ForegroundColor Yellow
$visuals.SetAttribute("AppListEntry", "none")
$manifest.Save($manifestPath)
Write-Host "  AppListEntry set to 'none'" -ForegroundColor Green

# Step 5: Restore ownership + restart Start Menu
Write-Host "[5/5] Restoring permissions + refreshing Start Menu..." -ForegroundColor Yellow
icacls "$manifestPath" /setowner "NT SERVICE\TrustedInstaller" 2>&1 | Out-Null
icacls "$manifestPath" /reset 2>&1 | Out-Null

# Clear tile cache
Stop-Process -Name "StartMenuExperienceHost" -Force -ErrorAction SilentlyContinue
$cacheDir = "$env:LOCALAPPDATA\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\TempState"
if (Test-Path $cacheDir) {
    Remove-Item "$cacheDir\*" -Force -ErrorAction SilentlyContinue
}

# Clear icon cache
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*" -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ✅ DONE — Start Menu entry hidden" -ForegroundColor Green
Write-Host "  Backup saved at: $backupPath" -ForegroundColor Green
Write-Host ""
Write-Host "  To verify: open Start Menu → all apps → '&' group" -ForegroundColor Cyan
Write-Host "  SecHealthUI still works via:" -ForegroundColor Cyan
Write-Host "    - Windows Search (type 'Windows 安全中心')" -ForegroundColor Gray
Write-Host "    - Settings → Update & Security → Windows Security" -ForegroundColor Gray
Write-Host "    - System tray shield icon" -ForegroundColor Gray
Write-Host "    - Win+R: windowsdefender:" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Green

Read-Host "Press Enter to close"
