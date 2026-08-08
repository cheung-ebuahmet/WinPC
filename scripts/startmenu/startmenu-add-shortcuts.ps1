# Start Menu: collapse single-shortcut folders + add missing shortcuts
# Right-click -> Run with PowerShell (as Administrator)
# ============================================================

# === CJK Encoding Fix (must be first executable lines) ===
chcp 65001 > $null
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
# ========================================================

Write-Host "=== Start Menu Refine ===" -ForegroundColor Cyan
$programs = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs"
$shell = New-Object -ComObject WScript.Shell

# ---- 1. Collapse single-shortcut folders to root ----
Write-Host "[1/3] Collapsing single-shortcut folders..." -ForegroundColor Yellow
$collapse = @("Bandizip", "FortiClient VPN", "Foxmail", "OneCommander", "WeCom")
foreach ($f in $collapse) {
    $folder = "$programs\$f"
    if (Test-Path $folder) {
        $lnks = Get-ChildItem $folder -Filter "*.lnk" -File
        if ($lnks.Count -eq 1) {
            $targetName = "$f.lnk"
            Move-Item -Force $lnks[0].FullName "$programs\$targetName"
            Remove-Item -Recurse -Force $folder
            Write-Host "  ${f}\ -> ${targetName}" -ForegroundColor Green
        } else {
            Write-Host ("  {0}: {1} lnks — keeping folder" -f $f, $lnks.Count) -ForegroundColor Gray
        }
    }
}

# TP-Link — deep folder, single lnk
$tplink = "$programs\TP-Link Archer TX1U Nano Driver"
if (Test-Path $tplink) {
    $lnks = Get-ChildItem $tplink -Recurse -Filter "*.lnk" -File
    if ($lnks.Count -eq 1) {
        Move-Item -Force $lnks[0].FullName "$programs\"
        Remove-Item -Recurse -Force $tplink
        Write-Host "  TP-Link Archer TX1U Nano Driver\ -> $($lnks[0].Name)" -ForegroundColor Green
    }
}

# Cleanup: empty leftover subfolders inside collapsed dirs
$empties = Get-ChildItem $programs -Directory | Where-Object {
    (Get-ChildItem $_.FullName -Recurse -Filter "*.lnk" -File -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0
}
foreach ($e in $empties) {
    Remove-Item -Recurse -Force $e.FullName -ErrorAction SilentlyContinue
    Write-Host "  Removed empty: $($e.Name)" -ForegroundColor Gray
}

# ---- 2. Add missing shortcuts ----
Write-Host "[2/3] Adding missing shortcuts..." -ForegroundColor Yellow

# VS Code
$vscode = "$programs\VS Code.lnk"
if (Test-Path "D:\Program Files\Microsoft VS Code\Code.exe") {
    if (-not (Test-Path $vscode)) {
        $sc = $shell.CreateShortcut($vscode)
        $sc.TargetPath = "D:\Program Files\Microsoft VS Code\Code.exe"
        $sc.WorkingDirectory = "D:\Program Files\Microsoft VS Code"
        $sc.Description = "Visual Studio Code"
        $sc.Save()
        Write-Host "  + VS Code.lnk" -ForegroundColor Green
    } else { Write-Host "  VS Code.lnk already exists" -ForegroundColor Gray }
}

# Sumatra PDF
$sumatra = "$programs\Sumatra PDF.lnk"
if (Test-Path "D:\Program Files\Sumatra PDF\SumatraPDF.bat") {
    if (-not (Test-Path $sumatra)) {
        $sc = $shell.CreateShortcut($sumatra)
        $sc.TargetPath = "D:\Program Files\Sumatra PDF\SumatraPDF.bat"
        $sc.WorkingDirectory = "D:\Program Files\Sumatra PDF"
        $sc.Description = "Sumatra PDF"
        $sc.Save()
        Write-Host "  + Sumatra PDF.lnk" -ForegroundColor Green
    } else { Write-Host "  Sumatra PDF.lnk already exists" -ForegroundColor Gray }
}

# ---- 3. Sort all root entries by name ----
Write-Host "[3/3] Verifying layout..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Folders:"
Get-ChildItem $programs -Directory | Sort-Object Name | ForEach-Object {
    $cnt = (Get-ChildItem $_.FullName -Recurse -Filter "*.lnk" -File -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "    $($_.Name)\ ($cnt shortcuts)"
}
Write-Host ""
Write-Host "  Root shortcuts:"
Get-ChildItem $programs -Filter "*.lnk" -File | Sort-Object Name | ForEach-Object {
    Write-Host "    $($_.Name)"
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Cyan
Read-Host "Press Enter to exit"
