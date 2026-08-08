# Take ownership of parent directory
takeown /f "C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy" /r /d y 2>&1 | Out-Null
icacls "C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy" /grant "BUILTIN\Administrators:(F)" /t 2>&1 | Out-Null

# Stop explorer briefly to unlock files
Stop-Process -Name "StartMenuExperienceHost" -Force -ErrorAction SilentlyContinue

# Replace main resources.pri
Copy-Item "D:\Documents\Temp\kb-extract\inner\amd64_microsoft-windows-sechealthui.appxmain_31bf3856ad364e35_10.0.19041.7417_none_279bc3cb93442232\f\microsoft.windows.sechealthui.pri" "C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy\resources.pri" -Force
Write-Host "Main resources.pri replaced: $?"

# Replace zh-CN
Copy-Item "D:\Documents\Temp\kb-extract\inner\amd64_microsoft-windows-s...appxmain.resources_31bf3856ad364e35_10.0.19041.7291_zh-cn_4199a1cbf390a9a1\f\microsoft.windows.sechealthui.zh-cn.pri" "C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy\pris\resources.zh-CN.pri" -Force
Write-Host "zh-CN PRI replaced: $?"

# Replace en-US
Copy-Item "D:\Documents\Temp\kb-extract\inner\amd64_microsoft-windows-s...appxmain.resources_31bf3856ad364e35_10.0.19041.7291_en-us_e213375e0c6ecf8f\f\microsoft.windows.sechealthui.en-us.pri" "C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy\pris\resources.en-US.pri" -Force
Write-Host "en-US PRI replaced: $?"

# Restore ownership
icacls "C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy" /setowner "NT SERVICE\TrustedInstaller" /t 2>&1 | Out-Null
icacls "C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy" /reset /t 2>&1 | Out-Null

Write-Host "=== PRI replacement complete ==="
Read-Host "Press Enter to close"
