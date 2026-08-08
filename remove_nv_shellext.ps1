# Run as SYSTEM to remove NVIDIA shell extensions (TrustedInstaller-protected keys)
$approvedPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved"
$nvEntries = @(
    "{A70C977A-BF00-412C-90B7-034C51DA2439}",
    "{A929C4CE-FD36-4270-B4F5-34ECAC5BD63C}",
    "{E97DEC16-A50D-49bb-AE24-CF682282E08D}",
    "{3D1975AF-48C6-4f8e-A182-BE0E08FA86A9}"
)

Write-Output "Removing from Approved list..."
$approvedKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
    "SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved",
    $true
)
foreach ($entry in $nvEntries) {
    try {
        $approvedKey.DeleteValue($entry)
        Write-Output "  Removed Approved: $entry"
    } catch {
        Write-Output "  FAILED Approved: $entry - $_"
    }
}
$approvedKey.Close()

Write-Output "Removing CLSID entries..."
$bases = @(
    "SOFTWARE\Classes\CLSID",
    "SOFTWARE\WOW6432Node\Classes\CLSID"
)
foreach ($base in $bases) {
    foreach ($entry in $nvEntries) {
        $subkey = "$base\$entry"
        try {
            $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($subkey, $true)
            if ($key) {
                $key.Close()
                [Microsoft.Win32.Registry]::LocalMachine.DeleteSubKeyTree($subkey)
                Write-Output "  Removed: $subkey"
            } else {
                Write-Output "  Not found: $subkey"
            }
        } catch {
            Write-Output "  FAILED: $subkey - $_"
        }
    }
}
Write-Output "Done"
