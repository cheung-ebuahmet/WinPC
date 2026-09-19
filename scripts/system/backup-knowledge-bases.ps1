# ============================================================================
# Wison + My Projects 知识库定期备份
# ============================================================================
# 策略（智能备份，不是为备份而备份）：
#   D:\Wison：
#     - _Ref / _tools / AI_Knowledge / index.md → Git 已版本化（git 本身就是差异备份）
#     - Main_Contract / Subcon_Payments / Project_Info → 证据层 PDF/DOCX/XLSX
#       变更频率极低（合同签完就不动），用 robocopy /MIR 增量同步，只传变化的文件
#     - 排除 .git（Git 对象库由 git bundle 单独处理）
#   D:\Documents\My Projects：
#     - 全量 robocopy /MIR（排除 PaddleOCR 模型数据，可重新下载）
#     - 体积小（~200 KB），即使全量也不疼
#
# 保留策略：4 个轮转副本（与系统还原点同理念）
#   位置：D:\Documents\My Projects\_backup\（知识库专属，不混入 Documents 根）
#   轮转：backup-00（最新）→ backup-01 → backup-02 → backup-03（最旧）
#   每次运行：删 backup-03，shift 0→1, 1→2, 2→3，0 新建 → robocopy 增量填充
#
# 调度：Windows Task Scheduler 每周六 09:07（非整点，避开峰值）
# ============================================================================

$ErrorActionPreference = "Continue"
chcp 65001 > $null
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$backupRoot = "D:\Documents\My Projects\_backup"
$keepCopies = 4
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$failed = $false

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Wison + My Projects 知识库备份" -ForegroundColor Cyan
Write-Host "  Time: $timestamp" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# 轮转
# ============================================================================
Write-Host "[1/4] 轮转旧备份..." -ForegroundColor Yellow

# 删除最旧的
$oldest = "$backupRoot\backup-{0:D2}" -f ($keepCopies - 1)
if (Test-Path $oldest) {
    # 送回收站而非永久删除
    Add-Type -AssemblyName Microsoft.VisualBasic
    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($oldest, 'OnlyErrorDialogs', 'SendToRecycleBin')
    Write-Host "  已送回收站: $oldest" -ForegroundColor Gray
}

# Shift: 02→03, 01→02, 00→01
for ($i = $keepCopies - 2; $i -ge 0; $i--) {
    $src = "$backupRoot\backup-{0:D2}" -f $i
    $dst = "$backupRoot\backup-{0:D2}" -f ($i + 1)
    if (Test-Path $src) {
        Rename-Item -Path $src -NewName (Split-Path $dst -Leaf) -Force -ErrorAction SilentlyContinue
    }
}

# 创建新 00
New-Item -ItemType Directory -Force -Path "$backupRoot\backup-00" | Out-Null
Write-Host "  轮转完成，当前最新: backup-00" -ForegroundColor Green
Write-Host ""

# ============================================================================
# D:\Wison
# ============================================================================
Write-Host "[2/4] D:\Wison — 增量同步..." -ForegroundColor Yellow

$wisonSrc = "D:\Wison"
$wisonDst = "$backupRoot\backup-00\Wison"
New-Item -ItemType Directory -Force -Path $wisonDst | Out-Null

# robocopy /MIR = 镜像（新增+更新+删除已不存在的文件）
# /XD = 排除目录；/XF = 排除文件
# /NP /NFL /NDL = 减少日志噪音；/R:2 /W:5 = 重试策略
$wisonResult = robocopy $wisonSrc $wisonDst /MIR /R:2 /W:5 /NP /NFL /NDL /XD ".git" "__pycache__" /XF "*.pyc" "~$*" "Thumbs.db"

$wisonExit = $LASTEXITCODE
# robocopy exit codes: 0-7 = success (0=nothing copied, 1=files copied, etc.); >=8 = error
if ($wisonExit -lt 8) {
    $wisonSize = [math]::Round((Get-ChildItem $wisonDst -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
    Write-Host "  OK — $wisonSize MB (exit $wisonExit)" -ForegroundColor Green
} else {
    Write-Host "  异常 — robocopy exit $wisonExit" -ForegroundColor Red
    $failed = $true
}

# Git bundle: 把 Git 历史打包成单文件（方便离线还原）
$gitBundle = "$backupRoot\backup-00\Wison.git.bundle"
if (Test-Path "$wisonSrc\.git") {
    Push-Location $wisonSrc
    try {
        git bundle create $gitBundle --all 2>$null
        if ($LASTEXITCODE -eq 0) {
            $bundleSize = [math]::Round((Get-Item $gitBundle).Length / 1MB, 1)
            Write-Host "  Git bundle: $bundleSize MB" -ForegroundColor Gray
        } else {
            Write-Host "  Git bundle 创建失败（可能仓库为空或损坏）" -ForegroundColor DarkYellow
        }
    } catch {
        Write-Host "  Git bundle 跳过: $_" -ForegroundColor DarkGray
    }
    Pop-Location
}

Write-Host ""

# ============================================================================
# D:\Documents\My Projects
# ============================================================================
Write-Host "[3/4] D:\Documents\My Projects — 同步..." -ForegroundColor Yellow

$mpSrc = "D:\Documents\My Projects"
$mpDst = "$backupRoot\backup-00\MyProjects"
New-Item -ItemType Directory -Force -Path $mpDst | Out-Null

# PaddleOCR 模型可重新下载，不备份；临时脚本在根目录，排除模式匹配
$mpResult = robocopy $mpSrc $mpDst /MIR /R:2 /W:5 /NP /NFL /NDL /XD "PaddleOCR" "_backup" "__pycache__" /XF "*.pyc" "~$*" "Thumbs.db"

$mpExit = $LASTEXITCODE
if ($mpExit -lt 8) {
    $mpSizeMB = [math]::Round((Get-ChildItem $mpDst -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1KB, 1)
    Write-Host "  OK — $mpSizeMB KB (exit $mpExit)" -ForegroundColor Green
} else {
    Write-Host "  异常 — robocopy exit $mpExit" -ForegroundColor Red
    $failed = $true
}

Write-Host ""

# ============================================================================
# 摘要
# ============================================================================
Write-Host "[4/4] 摘要" -ForegroundColor Yellow

$existingCopies = Get-ChildItem $backupRoot -Directory -Filter "backup-*" | Sort-Object Name
Write-Host "  现有副本: $($existingCopies.Count) 个 ($($existingCopies.Name -join ', '))" -ForegroundColor White

$totalSize = 0
foreach ($copy in $existingCopies) {
    $size = [math]::Round((Get-ChildItem $copy.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
    Write-Host "    $($copy.Name): $size MB" -ForegroundColor Gray
    $totalSize += $size
}

Write-Host ""
Write-Host "  备份总占用: $([math]::Round($totalSize, 1)) MB" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Done: $backupRoot" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# 显式退出码：让计划任务能正确区分成功/失败（robocopy 的 0-7 是成功，
# 若不显式 exit，进程会把最后的 $LASTEXITCODE 带出，成功也被记为 1）
if ($failed) {
    exit 1
} else {
    exit 0
}
