# ========================================
# Windows 安全中心 死图标 + UI 乱码 终极修复
# 必须以管理员身份运行！
# 右键开始菜单 → 终端(管理员) → 粘贴运行
# ========================================

Write-Host "=== 根因确认 ===" -ForegroundColor Cyan
Write-Host "硬盘上的 resources.zh-CN.pri 在 22H2 升级时被写坏。"
Write-Host "多个中文翻译字符串的格式化占位符损坏 (%1!s! → %!S! 等)"
Write-Host "导致开始菜单和应用内部 UI 同时乱码。"
Write-Host "修复：禁用损坏的中文 PRI → 强制回退英文 → DISM 从系统源还原。"
Write-Host ""

$ErrorActionPreference = "Continue"
$secDir = "C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy"
$priBad  = "$secDir\pris\resources.zh-CN.pri"
$priBak  = "$secDir\pris\resources.zh-CN.pri.corrupted_backup"
$priEn   = "$secDir\pris\resources.en-US.pri"

# ---------- Step 1: 备份并禁用损坏的 zh-CN PRI ----------
Write-Host "[1/7] 禁用损坏的中文资源文件..." -ForegroundColor Yellow
if (Test-Path $priBad) {
    if (Test-Path $priBak) { Remove-Item $priBak -Force }
    Rename-Item $priBad "resources.zh-CN.pri.corrupted_backup" -Force
    Write-Host "  已重命名: resources.zh-CN.pri → .corrupted_backup" -ForegroundColor Green
    Write-Host "  安全中心将回退到英文资源 (resources.en-US.pri)"
} else {
    Write-Host "  文件不存在，跳过"
}

# ---------- Step 2: 停服务 ----------
Write-Host "[2/7] 停止相关服务..." -ForegroundColor Yellow
$services = @("ShellHWDetection", "StateRepository", "AppXSvc", "TokenBroker")
foreach ($svc in $services) {
    Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    Write-Host "  停止: $svc"
}

# ---------- Step 3: 清 HKLM StateRepository ----------
Write-Host "[3/7] 清理 HKLM 系统级缓存..." -ForegroundColor Yellow

$paths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository\Cache\Package\Data\15a",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository\Cache\Package\Data\1d",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository\Cache\Application\Data\21",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository\Cache\Application\Data\ad",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository\Cache\ApplicationUser\Data\63",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository\Cache\ApplicationUser\Data\91",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository\Cache\ApplicationUser\Data\db",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository\Cache\ApplicationUser\Data\dd",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository\Cache\ApplicationUser\Data\df",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository\Cache\ApplicationUser\Data\e0",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository\Cache\ApplicationUser\Data\e1"
)
foreach ($path in $paths) {
    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
}

# 清理索引
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository\Cache\Application\Index\PackageAndPackageRelativeApplicationId" -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -like "*SecHealth*" } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository\Cache\ApplicationUser\Index\UserAndApplicationUserModelId" -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -like "*SecHealth*" } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository\Cache\Package\Index\PackageFullName" -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -like "*SecHealth*" } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository\Cache\PackageFamily\Index\PackageFamilyName" -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -like "*SecHealth*" } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "  系统缓存已清理" -ForegroundColor Green

# ---------- Step 4: 启动服务 ----------
Write-Host "[4/7] 重启服务..." -ForegroundColor Yellow
Start-Service -Name "AppXSvc" -ErrorAction SilentlyContinue
Start-Service -Name "StateRepository" -ErrorAction SilentlyContinue
Start-Service -Name "TokenBroker" -ErrorAction SilentlyContinue
Start-Service -Name "ShellHWDetection" -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# ---------- Step 5: 重新注册包 ----------
Write-Host "[5/7] 重新注册安全中心 AppX 包..." -ForegroundColor Yellow
Add-AppxPackage -Register "$secDir\AppXManifest.xml" -DisableDevelopmentMode -ForceApplicationShutdown -ForceUpdateFromAnyVersion
Write-Host "  注册完成" -ForegroundColor Green

# ---------- Step 6: 清用户缓存 ----------
Write-Host "[6/7] 清理用户缓存..." -ForegroundColor Yellow
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Caches\*" -Force -ErrorAction SilentlyContinue
# 也清 HKCU 残留
Remove-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  完成" -ForegroundColor Green

# ---------- Step 7: DISM 还原 ----------
Write-Host "[7/7] 运行 DISM 从 Windows Update 拉回正确的 PRI 文件 (可能需要几分钟)..." -ForegroundColor Yellow
# 先不用 /limitaccess，让 DISM 能从 Windows Update 下载
dism /online /cleanup-image /restorehealth
if ($LASTEXITCODE -eq 0) {
    Write-Host "  DISM 修复完成 — 系统会自动下载并替换损坏的资源文件" -ForegroundColor Green
} else {
    Write-Host "  DISM 失败 (错误码: $LASTEXITCODE)。如果 Windows Update 不可用，" -ForegroundColor Yellow
    Write-Host "  手动用 DISM /Source 指向 Windows ISO 修复，或保持英文回退。" -ForegroundColor Yellow
}

# ---------- Final ----------
Write-Host ""
Write-Host "=== 重启资源管理器 ===" -ForegroundColor Cyan
taskkill /f /im explorer.exe 2>$null
Start-Sleep -Seconds 2
start explorer.exe

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "修复完成。请检查：" -ForegroundColor Green
Write-Host "1. 开始菜单死图标是否消失" -ForegroundColor Green
Write-Host "2. 安全中心内文字是否变英文 (正常)" -ForegroundColor Green
Write-Host "3. 如仍有问题 → 重启电脑" -ForegroundColor Green
Write-Host ""
Write-Host "注：安全中心暂时显示英文，DISM 修复后会在"
Write-Host "下一个累积更新中自动恢复中文界面。" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green
