# Weasel (小狼毫/RIME) Install + Configure Pinyin + Wubi
# Run as Administrator


# === CJK Encoding Fix (must be first executable lines) ===
chcp 65001 > $null
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
# ========================================================

$installer = "D:\Applications\weasel小狼毫-0.17.0.0-installer.exe"
$installDir = "D:\Program Files\Weasel"

Write-Host "=== Weasel (RIME) Install ===" -ForegroundColor Cyan

# 1. Create target directory
Write-Host "[1/6] Creating install directory: $installDir" -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $installDir | Out-Null
Write-Host "  OK" -ForegroundColor Green

# 2. Silent install (NSIS: /S must be capital, /D= must be last, no quotes)
Write-Host "[2/6] Installing Weasel silently..." -ForegroundColor Yellow
$proc = Start-Process -FilePath $installer -ArgumentList "/S /NCRC /D=$installDir" -Wait -PassThru
Write-Host "  Exit code: $($proc.ExitCode)" -ForegroundColor $(if ($proc.ExitCode -eq 0) { "Green" } else { "Red" })

# Wait for install to settle
Start-Sleep -Seconds 3

# 3. Check install result
Write-Host "[3/6] Checking installation..." -ForegroundColor Yellow
$weaselExe = "$installDir\WeaselServer.exe"
if (Test-Path $weaselExe) {
    Write-Host "  Found: $weaselExe" -ForegroundColor Green
} else {
    Write-Host "  WARNING: WeaselServer.exe not in expected path, searching..." -ForegroundColor Yellow
    Get-ChildItem $installDir -Recurse -Filter "WeaselServer.exe" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "  Found: $($_.FullName)" -ForegroundColor Green
    }
    Get-ChildItem $installDir -Depth 2 -ErrorAction SilentlyContinue | Select-Object Name, FullName | Format-Table -AutoSize
}

Write-Host "[3/6] Listing install directory:" -ForegroundColor Yellow
Get-ChildItem $installDir -Depth 0 | Select-Object Name, LastWriteTime | Format-Table -AutoSize

# 4. Configure RIME: Pinyin + Wubi
Write-Host "[4/6] Configuring RIME schemas (Pinyin + Wubi)..." -ForegroundColor Yellow
$rimeDir = "$env:APPDATA\Rime"
New-Item -ItemType Directory -Force -Path $rimeDir | Out-Null

# Wait for RIME to initialize its files
Start-Sleep -Seconds 2

# ---- default.custom.yaml ----
Write-Host "  Writing default.custom.yaml..." -ForegroundColor Gray
$defaultCustom = @"
# default.custom.yaml - User schema activation
patch:
  schema_list:
    - schema: wubi86          # 五笔86
    - schema: luna_pinyin     # 朙月拼音
  switcher:
    hotkeys:
      - "Control+grave"       # Ctrl+` switch IME
      - "Control+Shift+grave" # Ctrl+Shift+`
    save_options:
      - full_shape
      - ascii_punct
      - traditional
"@
$defaultCustom | Out-File -FilePath "$rimeDir\default.custom.yaml" -Encoding utf8
Write-Host "  OK" -ForegroundColor Green

# ---- weasel.custom.yaml ----
Write-Host "  Writing weasel.custom.yaml..." -ForegroundColor Gray
$weaselCustom = @"
# weasel.custom.yaml - Weasel display settings
patch:
  style:
    color_scheme: aqua
    font_face: "Microsoft YaHei"
    font_point: 14
    horizontal: true
    inline_preedit: true
  app_options:
    cmd.exe:
      inline_preedit: false
"@
$weaselCustom | Out-File -FilePath "$rimeDir\weasel.custom.yaml" -Encoding utf8
Write-Host "  OK" -ForegroundColor Green

# ---- wubi86.custom.yaml (optional user dict) ----
Write-Host "  Writing wubi86.custom.yaml..." -ForegroundColor Gray
$wubiCustom = @"
# wubi86.custom.yaml - Wubi user settings
patch:
  translator/enable_user_dict: true
  translator/enable_sentence: true
"@
$wubiCustom | Out-File -FilePath "$rimeDir\wubi86.custom.yaml" -Encoding utf8
Write-Host "  OK" -ForegroundColor Green

# ---- luna_pinyin.custom.yaml ----
Write-Host "  Writing luna_pinyin.custom.yaml..." -ForegroundColor Gray
$pinyinCustom = @"
# luna_pinyin.custom.yaml - Pinyin user settings
patch:
  translator/enable_user_dict: true
  translator/enable_sentence: true
"@
$pinyinCustom | Out-File -FilePath "$rimeDir\luna_pinyin.custom.yaml" -Encoding utf8
Write-Host "  OK" -ForegroundColor Green

# ---- installation.yaml (sync dir for backups) ----
if (-not (Test-Path "$rimeDir\installation.yaml")) {
    Write-Host "  Writing installation.yaml..." -ForegroundColor Gray
    $installYaml = @"
distribution_code_name: Weasel
distribution_name: 小狼毫
distribution_version: 0.17.0.0
install_time: "$(Get-Date -Format 'ddd MMM dd HH:mm:ss yyyy')"
installation_id: "$(hostname)-rime"
sync_dir: "$env:USERPROFILE\RimeSync"
"@
    $installYaml | Out-File -FilePath "$rimeDir\installation.yaml" -Encoding utf8
    Write-Host "  OK" -ForegroundColor Green
}

# 5. Disable auto-update (Weasel has its own update check)
Write-Host "[5/6] Checking for updater..." -ForegroundColor Yellow
$updaters = Get-ChildItem $installDir -Recurse -Filter "*update*" -ErrorAction SilentlyContinue
if ($updaters) {
    foreach ($u in $updaters) {
        $bak = "$($u.FullName).bak"
        Rename-Item $u.FullName "$($u.Name).bak" -Force -ErrorAction SilentlyContinue
        Write-Host "  Renamed: $($u.Name)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  No updater found (Weasel doesn't auto-update)" -ForegroundColor Gray
}

# 6. Deploy RIME (restart service)
Write-Host "[6/6] Deploying RIME..." -ForegroundColor Yellow
# Kill WeaselServer if running, it will restart on next IME activation
Get-Process "WeaselServer" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
# Start Weasel
try {
    Start-Process "$installDir\WeaselServer.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
    Write-Host "  WeaselServer started" -ForegroundColor Green
} catch {
    Write-Host "  Start WeaselServer manually if needed" -ForegroundColor Yellow
}

# Trigger RIME deploy via WeaselDeployer
$deployer = "$installDir\WeaselDeployer.exe"
if (Test-Path $deployer) {
    try {
        Start-Process $deployer -ArgumentList "/deploy" -Wait -ErrorAction SilentlyContinue
        Write-Host "  RIME schema deployed" -ForegroundColor Green
    } catch {
        Write-Host "  Deploy manually via tray icon -> Deploy" -ForegroundColor Yellow
    }
} else {
    Write-Host "  WeaselDeployer.exe not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Cyan
Write-Host "Installed: $installDir" -ForegroundColor Green
Write-Host "Config:    $rimeDir" -ForegroundColor Green
Write-Host "Schemas:   wubi86 (五笔) + luna_pinyin (拼音)" -ForegroundColor Green
Write-Host ""
Write-Host "Usage:" -ForegroundColor White
Write-Host "  1. Switch to Weasel IME via language bar or Win+Space" -ForegroundColor White
Write-Host "  2. Press Ctrl+grave (Ctrl+`) to switch between Wubi and Pinyin" -ForegroundColor White
Write-Host "  3. Right-click tray icon -> Deploy after changing configs" -ForegroundColor White

Read-Host "Press Enter to exit"
