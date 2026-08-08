# NVIDIA Complete Cleanup Script
# Run as Administrator: Right-click PowerShell -> "Run as Administrator"
# Then paste: & 'D:\Documents\My Projects\remove-nvidia-admin.ps1'

Write-Host "========================================" -ForegroundColor Yellow
Write-Host " NVIDIA Complete Removal Script" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

# 1. Stop all NVIDIA services
Write-Host "`n[1/6] Stopping NVIDIA services..." -ForegroundColor Cyan
$nvidiaServices = @(
    "NVDisplay.ContainerLocalSystem",
    "NvContainerLocalSystem",
    "NvContainerNetworkService"
)
foreach ($svcName in $nvidiaServices) {
    $s = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($s) {
        Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
        Write-Host "  Stopped: $svcName"
    } else {
        Write-Host "  Not found: $svcName"
    }
}

# 2. Disable NVIDIA services permanently
Write-Host "`n[2/6] Disabling NVIDIA services..." -ForegroundColor Cyan
foreach ($svcName in $nvidiaServices) {
    $s = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($s) {
        sc.exe config $svcName start=disabled
        Write-Host "  Disabled: $svcName"
    }
}

# 3. Remove NVIDIA driver packages via pnputil
Write-Host "`n[3/6] Removing NVIDIA driver packages..." -ForegroundColor Cyan
$output = pnputil /enum-drivers 2>&1 | Out-String
$lines = $output -split "`n"
$nvidiaInfs = @()
foreach ($line in $lines) {
    if ($line -match 'Published Name.*(nv.*\.inf)') {
        $infName = $Matches[1]
        $nvidiaInfs += $infName
        Write-Host "  Found: $infName"
    }
}
if ($nvidiaInfs.Count -eq 0) {
    # Fallback: search driver store directly
    Write-Host "  Searching driver store for NVIDIA packages..."
    Get-ChildItem "C:\Windows\System32\DriverStore\FileRepository" -Directory | Where-Object {
        $_.Name -like '*nvidia*' -or $_.Name -like '*nv_dispi*' -or $_.Name -like '*nvle*'
    } | ForEach-Object {
        $infFiles = Get-ChildItem $_.FullName -Filter "*.inf" -ErrorAction SilentlyContinue
        foreach ($inf in $infFiles) {
            Write-Host "  Removing: $($inf.BaseName)"
            pnputil /delete-driver $inf.BaseName /uninstall /force
        }
    }
} else {
    foreach ($inf in $nvidiaInfs) {
        Write-Host "  Removing: $inf"
        pnputil /delete-driver $inf /uninstall /force
    }
}

# 4. Delete NVIDIA folders
Write-Host "`n[4/6] Removing NVIDIA folders..." -ForegroundColor Cyan
$folders = @(
    "C:\Program Files\NVIDIA Corporation",
    "C:\Program Files (x86)\NVIDIA Corporation",
    "C:\ProgramData\NVIDIA",
    "C:\ProgramData\NVIDIA Corporation",
    "C:\Users\Admin\AppData\Local\NVIDIA",
    "C:\Users\Admin\AppData\Local\NVIDIA Corporation",
    "C:\Users\Admin\AppData\Roaming\NVIDIA"
)
foreach ($folder in $folders) {
    if (Test-Path $folder) {
        try {
            takeown /F $folder /R /D Y 2>&1 | Out-Null
            icacls $folder /grant "Administrators:F" /T /Q 2>&1 | Out-Null
            Remove-Item $folder -Recurse -Force -ErrorAction Stop
            Write-Host "  Removed: $folder"
        } catch {
            Write-Host "  WARNING: Could not remove $folder - $_"
        }
    } else {
        Write-Host "  Not present: $folder"
    }
}

# 5. Clean NVIDIA registry entries
Write-Host "`n[5/6] Cleaning registry..." -ForegroundColor Cyan
$regKeys = @(
    "HKLM:\Software\NVIDIA Corporation",
    "HKLM:\Software\WOW6432Node\NVIDIA Corporation",
    "HKCU:\Software\NVIDIA Corporation"
)
foreach ($key in $regKeys) {
    if (Test-Path $key) {
        try {
            Remove-Item $key -Recurse -Force -ErrorAction Stop
            Write-Host "  Removed: $key"
        } catch {
            Write-Host "  WARNING: Could not remove $key - $_"
        }
    }
}
# Clean NVIDIA entries from Run keys
$runKeys = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
)
foreach ($key in $runKeys) {
    $props = Get-ItemProperty $key -ErrorAction SilentlyContinue
    if ($props) {
        $props.PSObject.Properties | Where-Object {
            $_.Name -notin @('PSPath','PSParentPath','PSChildName','PSDrive','PSProvider') -and
            $_.Value -like '*nvidia*'
        } | ForEach-Object {
            Remove-ItemProperty -Path $key -Name $_.Name -Force -ErrorAction SilentlyContinue
            Write-Host "  Removed Run entry: $($_.Name)"
        }
    }
}

# 6. Remove NVIDIA scheduled tasks
Write-Host "`n[6/6] Removing scheduled tasks..." -ForegroundColor Cyan
Get-ScheduledTask | Where-Object {
    $_.TaskName -like '*NVIDIA*' -or $_.TaskPath -like '*NVIDIA*'
} | ForEach-Object {
    try {
        Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false -ErrorAction Stop
        Write-Host "  Removed: $($_.TaskName)"
    } catch {
        Write-Host "  WARNING: Could not remove $($_.TaskName) - $_"
    }
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host " Done! Please restart your PC now." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
