# Fix CJK font in legacy PowerShell & CMD consoles
# Run as Administrator once — settings persist permanently
# ============================================================


# === CJK Encoding Fix (must be first executable lines) ===
chcp 65001 > $null
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
# ========================================================

Write-Host "=== CJK Console Font Fix ===" -ForegroundColor Cyan
Write-Host ""

# FontFamily 54 = TrueType (0x36)
# FontSize = 0x100000 (high word = height 16, low word = width 8)
$fontFamily = 54       # TrueType
$fontSize   = 0x100000 # 16px height
$fontName   = "Consolas"

# ---- CMD ----
$cmdPath = "HKCU:\Console\%SystemRoot%_system32_cmd.exe"
if (-not (Test-Path $cmdPath)) { New-Item -Path $cmdPath -Force | Out-Null }
Set-ItemProperty -Path $cmdPath -Name "FaceName"   -Value $fontName   -Type String  -Force
Set-ItemProperty -Path $cmdPath -Name "FontFamily" -Value $fontFamily -Type DWord   -Force
Set-ItemProperty -Path $cmdPath -Name "FontSize"   -Value $fontSize   -Type DWord   -Force
Set-ItemProperty -Path $cmdPath -Name "CodePage"   -Value 65001       -Type DWord   -Force
Write-Host "  OK — CMD font → $fontName + UTF-8" -ForegroundColor Green

# ---- PowerShell 5.1 ----
$psPath = "HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe"
if (-not (Test-Path $psPath)) { New-Item -Path $psPath -Force | Out-Null }
Set-ItemProperty -Path $psPath -Name "FaceName"   -Value $fontName   -Type String  -Force
Set-ItemProperty -Path $psPath -Name "FontFamily" -Value $fontFamily -Type DWord   -Force
Set-ItemProperty -Path $psPath -Name "FontSize"   -Value $fontSize   -Type DWord   -Force
Set-ItemProperty -Path $psPath -Name "CodePage"   -Value 65001       -Type DWord   -Force
Write-Host "  OK — PowerShell 5.1 font → $fontName + UTF-8" -ForegroundColor Green

# ---- Global console default ----
Set-ItemProperty -Path "HKCU:\Console" -Name "FaceName"   -Value $fontName   -Type String  -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Console" -Name "FontFamily" -Value $fontFamily -Type DWord   -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Console" -Name "CodePage"   -Value 65001       -Type DWord   -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Done. New CMD / PowerShell windows will use Consolas + UTF-8." -ForegroundColor Cyan
Write-Host "Existing windows must be closed and reopened." -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"
