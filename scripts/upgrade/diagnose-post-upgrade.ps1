# Post-21H2 to 22H2 Upgrade Diagnostic - Read-Only
# Scans all previously configured settings, reports what survived.
# Run as Administrator (right-click -> Run with PowerShell)
# ============================================================

chcp 65001 > $null
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()

$ErrorActionPreference = "SilentlyContinue"
$host.UI.RawUI.WindowTitle = "Post-Upgrade Diagnostic"

$pass = 0; $warn = 0; $fail = 0

function Check($label, $expected, $actual, $note) {
    if ($actual -eq $expected) {
        Write-Host "  [PASS] $label" -ForegroundColor Green
        $script:pass++
    } elseif ($actual -eq $null -or $actual -eq "") {
        Write-Host "  [WARN] $label --- NOT FOUND (was: $expected)" -ForegroundColor Yellow
        if ($note) { Write-Host "         $note" -ForegroundColor Gray }
        $script:warn++
    } else {
        Write-Host "  [FAIL] $label --- got: $actual (expected: $expected)" -ForegroundColor Red
        if ($note) { Write-Host "         $note" -ForegroundColor Gray }
        $script:fail++
    }
}

function CheckExists($label, $path) {
    if (Test-Path $path) {
        Write-Host "  [PASS] $label" -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host "  [WARN] $label --- missing: $path" -ForegroundColor Yellow
        $script:warn++
    }
}

function CheckAbsent($label, $pathOrKey) {
    if (Test-Path $pathOrKey) {
        Write-Host "  [FAIL] $label --- STILL EXISTS: $pathOrKey" -ForegroundColor Red
        $script:fail++
    } else {
        Write-Host "  [PASS] $label --- gone" -ForegroundColor Green
        $script:pass++
    }
}

function Section($title) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Post-Upgrade Diagnostic - 21H2 -> 22H2" -ForegroundColor Cyan
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# ============================================================================
# 0. OS Version
# ============================================================================
Section "0. OS Version"

$os = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
$build = $os.CurrentBuild
$ubr   = $os.UBR
$display = $os.DisplayVersion
$edition = $os.EditionID
Write-Host "  Edition : $edition" -ForegroundColor White
Write-Host "  Version : $display (Build $build.$ubr)" -ForegroundColor White
if ([int]$build -ge 19045) {
    Write-Host "  Status  : 22H2 confirmed" -ForegroundColor Green
} else {
    Write-Host "  Status  : Pre-22H2 (Build $build)" -ForegroundColor Yellow
}

# ============================================================================
# 1. UWP Bloatware Status
# ============================================================================
Section "1. UWP Bloatware Status"
Write-Host "  (Should be: NOT INSTALLED)" -ForegroundColor Gray

$uwpTargets = @(
    @{Name="Camera";       Pkg="Microsoft.WindowsCamera"},
    @{Name="Photos";       Pkg="Microsoft.Windows.Photos"},
    @{Name="Get Help";     Pkg="Microsoft.GetHelp"},
    @{Name="Sticky Notes"; Pkg="Microsoft.MicrosoftStickyNotes"}
)

foreach ($app in $uwpTargets) {
    $pkg = Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq $app.Pkg }
    $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $app.Pkg }
    if ($pkg) {
        Write-Host "  [FAIL] $($app.Name) --- UWP package REINSTALLED" -ForegroundColor Red
        $script:fail++
    } elseif ($prov) {
        Write-Host "  [FAIL] $($app.Name) --- provisioned pkg restored (new users)" -ForegroundColor Red
        $script:fail++
    } else {
        Write-Host "  [PASS] $($app.Name) --- not installed" -ForegroundColor Green
        $script:pass++
    }
}

# ============================================================================
# 2. Office C2R Excluded Apps
# ============================================================================
Section "2. Office C2R Excluded Apps"
Write-Host "  (Should include: Access, OneNote, Outlook, Publisher)" -ForegroundColor Gray

$c2rConfig = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
$excluded = (Get-ItemProperty -Path $c2rConfig -Name "ProPlus2021Retail.ExcludedApps" -ErrorAction SilentlyContinue)."ProPlus2021Retail.ExcludedApps"
$expectedExclude = @("access","onenote","outlook","publisher")
$missingExclude = @()
foreach ($e in $expectedExclude) {
    if ($excluded -notmatch $e) { $missingExclude += $e }
}
if ($missingExclude.Count -eq 0) {
    Write-Host "  [PASS] ExcludedApps = $excluded" -ForegroundColor Green
    $script:pass++
} elseif (-not $excluded) {
    Write-Host "  [FAIL] ExcludedApps NOT FOUND - Office may have restored apps" -ForegroundColor Red
    $script:fail++
} else {
    Write-Host "  [FAIL] Missing exclusions: $($missingExclude -join ', ')" -ForegroundColor Red
    Write-Host "         Current: $excluded" -ForegroundColor Gray
    $script:fail++
}

# ============================================================================
# 3. Start Menu Performance Registry
# ============================================================================
Section "3. Start Menu Performance Registry"

$adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

Check "MenuShowDelay = 0" "0" `
    (Get-ItemProperty -Path $adv -Name "MenuShowDelay" -ErrorAction SilentlyContinue).MenuShowDelay `
    "Animation delay for menus"

Check "Start_TrackProgs = 0" 0 `
    (Get-ItemProperty -Path $adv -Name "Start_TrackProgs" -ErrorAction SilentlyContinue).Start_TrackProgs `
    "Program usage tracking"

Check "TaskbarAnimations = 0" 0 `
    (Get-ItemProperty -Path $adv -Name "TaskbarAnimations" -ErrorAction SilentlyContinue).TaskbarAnimations

Check "Start_ShowRecentlyAddedApps = 0" 0 `
    (Get-ItemProperty -Path $adv -Name "Start_ShowRecentlyAddedApps" -ErrorAction SilentlyContinue).Start_ShowRecentlyAddedApps

Check "Start_IrisRecommendations = 0" 0 `
    (Get-ItemProperty -Path $adv -Name "Start_IrisRecommendations" -ErrorAction SilentlyContinue).Start_IrisRecommendations `
    "Start suggestions"

$serializePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
Check "Serialize StartupDelayInMSec = 0" 0 `
    (Get-ItemProperty -Path $serializePath -Name "StartupDelayInMSec" -ErrorAction SilentlyContinue).StartupDelayInMSec

# ============================================================================
# 4. Web Search and Cortana
# ============================================================================
Section "4. Web Search and Cortana"

$searchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
Check "BingSearchEnabled = 0" 0 `
    (Get-ItemProperty -Path $searchPath -Name "BingSearchEnabled" -ErrorAction SilentlyContinue).BingSearchEnabled

Check "CortanaConsent = 0" 0 `
    (Get-ItemProperty -Path $searchPath -Name "CortanaConsent" -ErrorAction SilentlyContinue).CortanaConsent

Check "AllowSearchToUseLocation = 0" 0 `
    (Get-ItemProperty -Path $searchPath -Name "AllowSearchToUseLocation" -ErrorAction SilentlyContinue).AllowSearchToUseLocation

$searchSettings = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\Settings"
Check "IsDynamicSearchBoxEnabled = 0" 0 `
    (Get-ItemProperty -Path $searchSettings -Name "IsDynamicSearchBoxEnabled" -ErrorAction SilentlyContinue).IsDynamicSearchBoxEnabled

$polSearch = "HKLM:\Software\Policies\Microsoft\Windows\Windows Search"
Check "HKLM: DisableWebSearch = 1" 1 `
    (Get-ItemProperty -Path $polSearch -Name "DisableWebSearch" -ErrorAction SilentlyContinue).DisableWebSearch

Check "HKLM: ConnectedSearchUseWeb = 0" 0 `
    (Get-ItemProperty -Path $polSearch -Name "ConnectedSearchUseWeb" -ErrorAction SilentlyContinue).ConnectedSearchUseWeb

Check "HKLM: AllowCortana = 0" 0 `
    (Get-ItemProperty -Path $polSearch -Name "AllowCortana" -ErrorAction SilentlyContinue).AllowCortana

# ============================================================================
# 5. Transparency and Visual
# ============================================================================
Section "5. Transparency and Visual Settings"

$themePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
Check "EnableTransparency = 0" 0 `
    (Get-ItemProperty -Path $themePath -Name "EnableTransparency" -ErrorAction SilentlyContinue).EnableTransparency

# ============================================================================
# 6. Console Font Settings (CMD + PowerShell)
# ============================================================================
Section "6. Console Font Configuration"

Check "CMD FaceName = Consolas" "Consolas" `
    (Get-ItemProperty -Path "HKCU:\Console\%SystemRoot%_system32_cmd.exe" -Name "FaceName" -ErrorAction SilentlyContinue).FaceName

Check "CMD CodePage = 65001" 65001 `
    (Get-ItemProperty -Path "HKCU:\Console\%SystemRoot%_system32_cmd.exe" -Name "CodePage" -ErrorAction SilentlyContinue).CodePage

Check "PS5.1 FaceName = Consolas" "Consolas" `
    (Get-ItemProperty -Path "HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe" -Name "FaceName" -ErrorAction SilentlyContinue).FaceName

Check "PS5.1 CodePage = 65001" 65001 `
    (Get-ItemProperty -Path "HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe" -Name "CodePage" -ErrorAction SilentlyContinue).CodePage

Check "Global Console CodePage = 65001" 65001 `
    (Get-ItemProperty -Path "HKCU:\Console" -Name "CodePage" -ErrorAction SilentlyContinue).CodePage

# ============================================================================
# 7. Win32PrioritySeparation
# ============================================================================
Section "7. CPU Priority - Win32PrioritySeparation"

$priorityPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
Check "Win32PrioritySeparation = 38 (0x26)" 38 `
    (Get-ItemProperty -Path $priorityPath -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue).Win32PrioritySeparation

# ============================================================================
# 8. Office Auto-Update Block
# ============================================================================
Section "8. Office Update Block Policy"

$officePol = "HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\OfficeUpdate"
Check "EnableAutomaticUpdates = 0" 0 `
    (Get-ItemProperty -Path $officePol -Name "EnableAutomaticUpdates" -ErrorAction SilentlyContinue).EnableAutomaticUpdates

Check "HideUpdateNotifications = 1" 1 `
    (Get-ItemProperty -Path $officePol -Name "HideUpdateNotifications" -ErrorAction SilentlyContinue).HideUpdateNotifications

Check "HideWhatsNew = 1" 1 `
    (Get-ItemProperty -Path $officePol -Name "HideWhatsNew" -ErrorAction SilentlyContinue).HideWhatsNew

$officeGeneral = "HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\General"
Check "ShownFirstRunOptin = 1" 1 `
    (Get-ItemProperty -Path $officeGeneral -Name "ShownFirstRunOptin" -ErrorAction SilentlyContinue).ShownFirstRunOptin

# ---- Scheduled tasks ----
Write-Host ""
Write-Host "  --- Office Scheduled Tasks ---" -ForegroundColor Gray
$tasksToCheck = @(
    "Office Automatic Updates 2.0",
    "Office Feature Updates",
    "Office Feature Updates Logon",
    "Office Background Push Maintenance"
)
foreach ($tn in $tasksToCheck) {
    try {
        $task = Get-ScheduledTask -TaskName $tn -ErrorAction Stop
        if ($task.State -eq "Disabled") {
            Write-Host "  [PASS] $tn --- State: Disabled" -ForegroundColor Green
            $script:pass++
        } else {
            Write-Host "  [FAIL] $tn --- State: $($task.State) (should be Disabled)" -ForegroundColor Red
            $script:fail++
        }
    } catch {
        Write-Host "  [WARN] $tn --- NOT FOUND" -ForegroundColor Yellow
        $script:warn++
    }
}

# ClickToRun service
$c2rSvc = Get-Service -Name "ClickToRunSvc" -ErrorAction SilentlyContinue
if ($c2rSvc) {
    if ($c2rSvc.StartType -eq "Manual") {
        Write-Host "  [PASS] ClickToRunSvc --- StartType: Manual" -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host "  [FAIL] ClickToRunSvc --- StartType: $($c2rSvc.StartType) (should be Manual)" -ForegroundColor Red
        $script:fail++
    }
} else {
    Write-Host "  [WARN] ClickToRunSvc --- service not found" -ForegroundColor Yellow
    $script:warn++
}

# ============================================================================
# 9. Rime Input Method
# ============================================================================
Section "9. Rime Input Method"

CheckExists "WeaselServer.exe" "D:\Program Files\Rime\weasel-0.17.0\WeaselServer.exe"
CheckExists "default.custom.yaml" "$env:APPDATA\Rime\default.custom.yaml"
CheckExists "weasel.custom.yaml" "$env:APPDATA\Rime\weasel.custom.yaml"
CheckExists "wubi86.custom.yaml" "$env:APPDATA\Rime\wubi86.custom.yaml"
CheckExists "luna_pinyin.custom.yaml" "$env:APPDATA\Rime\luna_pinyin.custom.yaml"
CheckExists "installation.yaml" "$env:APPDATA\Rime\installation.yaml"

$defaultCustom = "$env:APPDATA\Rime\default.custom.yaml"
if (Test-Path $defaultCustom) {
    $content = Get-Content $defaultCustom -Raw -Encoding UTF8
    if ($content -match "wubi86" -and $content -match "luna_pinyin") {
        Write-Host "  [PASS] default.custom.yaml --- wubi86 + luna_pinyin schemas" -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host "  [FAIL] default.custom.yaml --- schema list incomplete" -ForegroundColor Red
        $script:fail++
    }
}

# ============================================================================
# 10. Start Menu Shortcut Structure
# ============================================================================
Section "10. Start Menu Shortcuts"

$programs = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs"

# Should exist
CheckExists "Bandizip shortcut" "$programs\Bandizip.lnk"
CheckExists "Foxmail shortcut" "$programs\Foxmail.lnk"
CheckExists "WeCom shortcut" "$programs\WeCom.lnk"
CheckExists "OneCommander shortcut" "$programs\OneCommander.lnk"
CheckExists "VS Code shortcut" "$programs\VS Code.lnk"
CheckExists "Microsoft Office folder" "$programs\Microsoft Office"
CheckExists "Rime folder" "$programs\Rime"

# Should NOT exist
CheckAbsent "Weasel broken folder" "$programs\Weasel"
CheckAbsent "OneDrive shortcut" "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"
CheckAbsent "Bandizip uninstall" "$programs\Bandizip\Uninstall.lnk"
CheckAbsent "Foxmail uninstall" "$programs\Foxmail\uninstall Foxmail.lnk"
CheckAbsent "WeCom uninstall" "$programs\WeCom\Uninstall WeCom.lnk"

# Rime shortcuts
CheckExists "Rime Settings.lnk" "$programs\Rime\Rime Settings.lnk"
CheckExists "Rime Deploy.lnk"   "$programs\Rime\Rime Deploy.lnk"
CheckExists "Rime Server.lnk"   "$programs\Rime\Rime Server.lnk"
CheckExists "Rime User Folder.lnk" "$programs\Rime\Rime User Folder.lnk"

# ============================================================================
# 11. Dead Shell Extensions
# ============================================================================
Section "11. Dead Shell Extensions"

CheckAbsent "Yunku ContextMenu (*)" "HKLM:\Software\Classes\*\ShellEx\ContextMenuHandlers\Yunku"
CheckAbsent "Yunku ContextMenu (Dir)" "HKLM:\Software\Classes\Directory\ShellEx\ContextMenuHandlers\Yunku"
CheckAbsent "Yunku CLSID" "HKLM:\Software\Classes\CLSID\{545AAC68-1834-408C-B093-5EA87AE111D9}"

# ============================================================================
# 12. WeCom Data Location
# ============================================================================
Section "12. WeCom Data Location"

$wecomReg = (Get-ItemProperty -Path "HKCU:\Software\Tencent\WXWork" -Name "DataLocation" -ErrorAction SilentlyContinue).DataLocation
$expectedWecom = "D:\Program Files\WeCom\Data"
Check "WeCom DataLocation" $expectedWecom $wecomReg
CheckExists "WeCom data directory" "D:\Program Files\WeCom\Data"

# ============================================================================
# 13. Default App Associations
# ============================================================================
Section "13. Default App Associations"
Write-Host "  (Check if defaults were reset to Microsoft apps)" -ForegroundColor Gray

$pdfProgId = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" -Name "ProgId" -ErrorAction SilentlyContinue).ProgId
if ($pdfProgId) {
    Write-Host "  [INFO] .pdf handler: $pdfProgId" -ForegroundColor White
    if ($pdfProgId -match "Edge" -or $pdfProgId -match "MSEdge") {
        Write-Host "  [WARN] .pdf opened by Edge --- may want Sumatra PDF" -ForegroundColor Yellow
        $script:warn++
    } else {
        $script:pass++
    }
} else {
    Write-Host "  [WARN] .pdf --- no UserChoice set" -ForegroundColor Yellow
    $script:warn++
}

$htmlProgId = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.html\UserChoice" -Name "ProgId" -ErrorAction SilentlyContinue).ProgId
if ($htmlProgId) {
    Write-Host "  [INFO] .html handler: $htmlProgId" -ForegroundColor White
    if ($htmlProgId -match "Chrome") {
        Write-Host "  [PASS] .html opened by Chrome" -ForegroundColor Green
        $script:pass++
    } elseif ($htmlProgId -match "Edge" -or $htmlProgId -match "MSEdge") {
        Write-Host "  [WARN] .html opened by Edge --- may have been reset" -ForegroundColor Yellow
        $script:warn++
    } else {
        $script:pass++
    }
} else {
    Write-Host "  [WARN] .html --- no UserChoice set" -ForegroundColor Yellow
    $script:warn++
}

# ============================================================================
# 14. System Restore Points
# ============================================================================
Section "14. System Restore Points"

try {
    $restorePoints = Get-ComputerRestorePoint -ErrorAction Stop | Sort-Object CreationTime -Descending
    if ($restorePoints) {
        Write-Host "  Restore points found: $($restorePoints.Count)" -ForegroundColor White
        $restorePoints | Select-Object -First 5 | ForEach-Object {
            $tag = ""
            if ($_.Description -match "22H2|Update|Upgrade") { $tag = " [UPGRADE]" }
            Write-Host "    #$($_.SequenceNumber) $($_.CreationTime.ToString('yyyy-MM-dd HH:mm')) $($_.Description)$tag" -ForegroundColor Gray
        }
        $script:pass++
    } else {
        Write-Host "  [WARN] No restore points found --- System Restore may be off" -ForegroundColor Yellow
        $script:warn++
    }
} catch {
    Write-Host "  [WARN] Cannot enumerate restore points: $_" -ForegroundColor Yellow
    $script:warn++
}

# ============================================================================
# 15. Installed Software Quick Check
# ============================================================================
Section "15. Installed Software Quick Check"

$swChecks = @(
    @{Name="PowerToys";       Path="D:\Program Files\PowerToys\PowerToys.exe"},
    @{Name="Python 3.10";    Path="D:\Program Files\Python310\python.exe"},
    @{Name="Tesseract OCR";  Path="D:\Program Files\Tesseract-OCR\tesseract.exe"},
    @{Name="Node.js";        Path="D:\Program Files\NodeJS\node.exe"},
    @{Name="Git";            Path="D:\Program Files\Git\bin\git.exe"},
    @{Name="VS Code";        Path="D:\Program Files\Microsoft VS Code\Code.exe"},
    @{Name="OneCommander";   Path="D:\Program Files\OneCommander\OneCommander.exe"},
    @{Name="Bandizip";       Path="D:\Program Files\Bandizip\Bandizip.exe"},
    @{Name="Google Chrome";  Path="D:\Program Files\Google Chrome\Application\chrome.exe"}
)

foreach ($sw in $swChecks) {
    if (Test-Path $sw.Path) {
        Write-Host "  [PASS] $($sw.Name)" -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host "  [WARN] $($sw.Name) --- not found" -ForegroundColor Yellow
        $script:warn++
    }
}

# ============================================================================
# 16. Office Telemetry and Privacy
# ============================================================================
Section "16. Office Telemetry and Privacy"

$officePrivacy = "HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\Privacy"
Check "SendTelemetry = 0" 0 `
    (Get-ItemProperty -Path $officePrivacy -Name "SendTelemetry" -ErrorAction SilentlyContinue).SendTelemetry

$ptpPath = "HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\Common\PTWatson"
Check "PTWOptIn = 0 (crash reporting)" 0 `
    (Get-ItemProperty -Path $ptpPath -Name "PTWOptIn" -ErrorAction SilentlyContinue).PTWOptIn

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                    D I A G N O S T I C   D O N E" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$total = $pass + $warn + $fail
if ($total -gt 0) {
    $pctPass = [math]::Round($pass / $total * 100, 1)
} else {
    $pctPass = 0
}

Write-Host "  Total checks : $total" -ForegroundColor White
Write-Host "  PASS         : $pass  ($pctPass%)" -ForegroundColor Green
Write-Host "  WARN         : $warn" -ForegroundColor Yellow
Write-Host "  FAIL         : $fail" -ForegroundColor Red
Write-Host ""

if ($fail -eq 0 -and $warn -eq 0) {
    Write-Host "  All settings preserved. No action needed." -ForegroundColor Green
} elseif ($fail -eq 0) {
    Write-Host "  Minor issues only - review WARN items above." -ForegroundColor Yellow
} else {
    Write-Host "  Some settings were reset by the upgrade." -ForegroundColor Red
    Write-Host "  Re-run the relevant fix scripts:" -ForegroundColor White
    Write-Host "    - remove-bloatware.ps1 (if UWP apps came back)" -ForegroundColor Gray
    Write-Host "    - startmenu-boost-performance.ps1 (if Start settings reset)" -ForegroundColor Gray
    Write-Host "    - block-office-auto-updates.ps1 (if Office policies lost)" -ForegroundColor Gray
    Write-Host "    - startmenu-cleanup-and-organize.ps1 (if Start Menu broken)" -ForegroundColor Gray
}

Write-Host ""
Read-Host "Press Enter to exit"
