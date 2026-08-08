# clean-temp.ps1 — Auto-clean stale files from the user TEMP folder.
#
# Deletes files NOT modified within the last -Days days from -TempDir, skipping
# any file locked / in use (left for the next run). Then prunes empty subfolders
# older than the cutoff. Never deletes the TEMP root itself.
#
# DELETION POLICY: everything goes to the RECYCLE BIN (recoverable), never a
# permanent delete. (Recycle Bin auto-purges oldest when full, so space is still
# bounded.)
#
# Runs daily via Windows Task Scheduler (task: Clean-UserTemp-DDocuments).
# Target is hardcoded to the user TEMP on D: — it must NOT touch C:\WINDOWS\TEMP.
param(
    [int]$Days = 30,
    [string]$TempDir = "D:\Documents\Temp",
    [switch]$WhatIf
)
$ErrorActionPreference = "SilentlyContinue"
if (-not (Test-Path -LiteralPath $TempDir)) { return }

Add-Type -AssemblyName Microsoft.VisualBasic

function Recycle-File([string]$p) {
    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
        $p, 'OnlyErrorDialogs', 'SendToRecycleBin', 'ThrowException')
}
function Recycle-Dir([string]$p) {
    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(
        $p, 'OnlyErrorDialogs', 'SendToRecycleBin', 'ThrowException')
}

$cutoff = (Get-Date).AddDays(-$Days)
$log    = Join-Path $PSScriptRoot "clean-temp.log"

$freed = 0; $del = 0; $fail = 0

# 1) Recycle stale files (older than cutoff by LastWriteTime)
Get-ChildItem -LiteralPath $TempDir -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoff } |
    ForEach-Object {
        $sz = $_.Length
        if ($WhatIf) { $del++; $freed += $sz; return }
        try {
            Recycle-File $_.FullName
            $del++; $freed += $sz
        } catch { $fail++ }   # locked / in use -> leave for next run
    }

# 2) Prune empty subfolders older than cutoff (deepest first) -> Recycle Bin
Get-ChildItem -LiteralPath $TempDir -Recurse -Directory -Force -ErrorAction SilentlyContinue |
    Sort-Object { $_.FullName.Length } -Descending |
    ForEach-Object {
        $hasChild = Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
        if (-not $hasChild -and $_.LastWriteTime -lt $cutoff -and -not $WhatIf) {
            try { Recycle-Dir $_.FullName } catch { }
        }
    }

$mb   = [math]::Round($freed / 1MB, 1)
$mode = if ($WhatIf) { "DRYRUN " } else { "RECYCLE" }
$line = "{0}  {1} recycled={2} files, {3} MB, skipped(locked)={4}, keep<={5}d" -f `
        (Get-Date -Format 'yyyy-MM-dd HH:mm'), $mode, $del, $mb, $fail, $Days
Add-Content -LiteralPath $log -Value $line -Encoding utf8
Write-Output $line
