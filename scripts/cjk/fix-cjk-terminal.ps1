# Fix CJK Rendering in ALL Terminal Environments
# ================================================
# 1. Install Sarasa Mono SC font (system-wide)
# 2. Fix CMD/PowerShell console font (Consolas -> Sarasa Mono SC)
# 3. Fix VS Code integrated terminal font
# 4. Register font for legacy console availability
# Run as Administrator (Right-click -> Run with PowerShell)
# ================================================

chcp 65001 > $null
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()

$ErrorActionPreference = "Stop"
$host.UI.RawUI.WindowTitle = "CJK Terminal Fix"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  CJK Terminal Font Fix - Sarasa Mono SC" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$fontDir    = "D:\Program Files\Sarasa-Mono-SC"
$fontName   = "Sarasa Mono SC"
$fontFile   = "$fontDir\SarasaMonoSC-Regular.ttf"

# ============================================================================
# STEP 1: Verify font files exist
# ============================================================================
Write-Host "[1/6] Checking font files..." -ForegroundColor Yellow
if (-not (Test-Path $fontFile)) {
    Write-Host "  ERROR: Font files not found at $fontDir" -ForegroundColor Red
    Write-Host "  Please extract SarasaMonoSC-TTF-1.0.39.7z to $fontDir first" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "  OK - Font files found" -ForegroundColor Green

# ============================================================================
# STEP 2: Install fonts system-wide
# ============================================================================
Write-Host "[2/6] Installing Sarasa Mono SC fonts (system-wide)..." -ForegroundColor Yellow

$fontsInstalled = $true
try {
    $shell = New-Object -ComObject Shell.Application
    $fontsFolder = $shell.Namespace(0x14)  # C:\Windows\Fonts

    Get-ChildItem $fontDir -Filter "*.ttf" | ForEach-Object {
        $fontNameFile = $_.Name
        # Check if already installed
        if (Test-Path "C:\Windows\Fonts\$fontNameFile") {
            Write-Host "  SKIP - $fontNameFile (already installed)" -ForegroundColor Gray
            return
        }
        $fontsFolder.CopyHere($_.FullName)
        Write-Host "  OK - $fontNameFile" -ForegroundColor Green
    }
} catch {
    Write-Host "  FAIL: $_" -ForegroundColor Red
    $fontsInstalled = $false
}

# Wait for font registration to settle
Start-Sleep -Seconds 3

# ============================================================================
# STEP 3: Register fonts as Console TrueType fonts
# ============================================================================
Write-Host "[3/6] Registering as Console TrueType font..." -ForegroundColor Yellow

$consoleFontsPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont"

# Add "Sarasa Mono SC" to the console font list if not already present
$existingFonts = Get-ItemProperty -Path $consoleFontsPath -ErrorAction SilentlyContinue
$maxIndex = 0
$alreadyRegistered = $false

if ($existingFonts) {
    $existingFonts.PSObject.Properties | Where-Object { $_.Name -match '^\d+$' } | ForEach-Object {
        if ($_.Value -eq $fontName) { $alreadyRegistered = $true }
        $idx = [int]$_.Name
        if ($idx -gt $maxIndex) { $maxIndex = $idx }
    }
}

if (-not $alreadyRegistered) {
    $newIndex = $maxIndex + 1
    New-ItemProperty -Path $consoleFontsPath -Name "$newIndex" -Value $fontName -PropertyType String -Force | Out-Null
    Write-Host "  OK - '$fontName' registered at index $newIndex" -ForegroundColor Green
} else {
    Write-Host "  OK - '$fontName' already registered" -ForegroundColor Green
}

# ============================================================================
# STEP 4: Fix CMD console font
# ============================================================================
Write-Host "[4/6] Configuring CMD console font..." -ForegroundColor Yellow

$cmdPath = "HKCU:\Console\%SystemRoot%_system32_cmd.exe"
if (-not (Test-Path $cmdPath)) { New-Item -Path $cmdPath -Force | Out-Null }
Set-ItemProperty -Path $cmdPath -Name "FaceName"   -Value $fontName  -Type String -Force
Set-ItemProperty -Path $cmdPath -Name "FontFamily" -Value 54          -Type DWord  -Force  # 54 = TrueType
Set-ItemProperty -Path $cmdPath -Name "FontSize"   -Value 0x100000   -Type DWord  -Force  # 16px
Set-ItemProperty -Path $cmdPath -Name "CodePage"   -Value 65001      -Type DWord  -Force
Write-Host "  OK - CMD font set to $fontName" -ForegroundColor Green

# ============================================================================
# STEP 5: Fix PowerShell 5.1 console font
# ============================================================================
Write-Host "[5/6] Configuring PowerShell 5.1 console font..." -ForegroundColor Yellow

$psPath = "HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe"
if (-not (Test-Path $psPath)) { New-Item -Path $psPath -Force | Out-Null }
Set-ItemProperty -Path $psPath -Name "FaceName"   -Value $fontName  -Type String -Force
Set-ItemProperty -Path $psPath -Name "FontFamily" -Value 54          -Type DWord  -Force
Set-ItemProperty -Path $psPath -Name "FontSize"   -Value 0x100000   -Type DWord  -Force
Set-ItemProperty -Path $psPath -Name "CodePage"   -Value 65001      -Type DWord  -Force
Write-Host "  OK - PS 5.1 font set to $fontName" -ForegroundColor Green

# Global console default (for new/future console windows)
Set-ItemProperty -Path "HKCU:\Console" -Name "FaceName" -Value $fontName -Type String -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Console" -Name "CodePage" -Value 65001    -Type DWord  -Force -ErrorAction SilentlyContinue

# ============================================================================
# STEP 6: Fix VS Code integrated terminal
# ============================================================================
Write-Host "[6/6] Configuring VS Code terminal font..." -ForegroundColor Yellow

$vscodeSettings = "$env:APPDATA\Code\User\settings.json"

if (Test-Path $vscodeSettings) {
    $settings = Get-Content $vscodeSettings -Raw -Encoding UTF8 | ConvertFrom-Json

    # Convert to hashtable for easy editing
    $hash = @{}
    $settings.PSObject.Properties | ForEach-Object { $hash[$_.Name] = $_.Value }

    # Set the CJK font family
    $hash["terminal.integrated.fontFamily"] = "'Sarasa Mono SC', 'Microsoft YaHei Mono', Consolas, monospace"

    # Ensure UTF-8 encoding for integrated terminal on Windows
    $hash["terminal.integrated.defaultProfile.windows"] = "PowerShell"

    # Additional terminal tweaks for better CJK rendering
    $hash["terminal.integrated.fontSize"] = 14
    $hash["terminal.integrated.lineHeight"] = 1.2

    # Write back with proper formatting
    $json = $hash | ConvertTo-Json -Depth 5
    # Fix PowerShell 5.1 ConvertTo-Json escaping
    $json = $json -replace '\\u0026', '&'
    [System.IO.File]::WriteAllText($vscodeSettings, $json, [System.Text.UTF8Encoding]::new($false))

    Write-Host "  OK - VS Code terminal configured" -ForegroundColor Green
} else {
    Write-Host "  WARN - VS Code settings not found at $vscodeSettings" -ForegroundColor Yellow
    Write-Host "  Manually add to VS Code settings.json:" -ForegroundColor Gray
    Write-Host "    `"terminal.integrated.fontFamily`": `"'Sarasa Mono SC', Consolas`"," -ForegroundColor White
}

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Done - CJK Terminal Font Fix Applied" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Changes:" -ForegroundColor White
Write-Host "  - Font: Sarasa Mono SC installed system-wide" -ForegroundColor Gray
Write-Host "  - CMD: font -> Sarasa Mono SC (16px, UTF-8)" -ForegroundColor Gray
Write-Host "  - PowerShell 5.1: font -> Sarasa Mono SC (16px, UTF-8)" -ForegroundColor Gray
Write-Host "  - VS Code: terminal.integrated.fontFamily = 'Sarasa Mono SC'" -ForegroundColor Gray
Write-Host ""
Write-Host "  To see the changes:" -ForegroundColor White
Write-Host "  1. Close ALL existing CMD/PowerShell windows" -ForegroundColor Yellow
Write-Host "  2. Open a new terminal - font should now render CJK correctly" -ForegroundColor Yellow
Write-Host "  3. VS Code: restart the integrated terminal (Ctrl+Shift+P ->" -ForegroundColor Yellow
Write-Host "     'Terminal: Kill All Terminals', then open a new one)" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Font family name: $fontName" -ForegroundColor Cyan
Write-Host "  For VS Code, you can also try in settings:" -ForegroundColor Gray
Write-Host "    'Sarasa Mono SC'  (recommended - modern CJK monospace)" -ForegroundColor White
Write-Host "    'Microsoft YaHei Mono'  (built-in, no install needed)" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to exit"
