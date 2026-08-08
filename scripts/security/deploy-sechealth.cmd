@echo off
setlocal enabledelayedexpansion
set "LOG=C:\Windows\Temp\deploy_sechealth_result.txt"
echo [%date% %time%] Deploying clean SecHealthUI files... > "%LOG%"

set "TARGET=C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy"
set "SRC=C:\Windows\Temp\sechealth_src"
set "CABROOT=amd64_microsoft-windows-sechealthui.appxmain_31bf3856ad364e35_10.0.19041.7417_none_279bc3cb93442232"
set "RESEN=amd64_microsoft-windows-s...appxmain.resources_31bf3856ad364e35_10.0.19041.7291_en-us_e213375e0c6ecf8f"
set "RESCN=amd64_microsoft-windows-s...appxmain.resources_31bf3856ad364e35_10.0.19041.7291_zh-cn_4199a1cbf390a9a1"

echo [1] Taking ownership of directory... >> "%LOG%"
takeown /f "%TARGET%" /r /d y >> "%LOG%" 2>&1

echo [2] Unlocking each file individually before copy... >> "%LOG%"
for %%F in (
    "resources.pri"
    "SecHealthUI.exe"
    "SecHealthUIAppShell.winmd"
    "SecHealthUIDataModel.dll"
    "SecHealthUIDataModel.winmd"
    "SecHealthUITelemetry.dll"
    "SecHealthUITelemetry.winmd"
    "SecHealthUIViewModels.dll"
    "SecHealthUIViewModels.winmd"
    "pris\resources.en-US.pri"
    "pris\resources.zh-CN.pri"
) do (
    echo Unlocking: %%F >> "%LOG%"
    icacls "%TARGET%\%%~F" /grant "SYSTEM:(F)" /grant "Administrators:(F)" >> "%LOG%" 2>&1
)

echo [3] Copying files... >> "%LOG%"

echo  --- resources.pri --- >> "%LOG%"
copy /y "%SRC%\%CABROOT%\f\microsoft.windows.sechealthui.pri" "%TARGET%\resources.pri" >> "%LOG%" 2>&1
echo  resources.pri: !ERRORLEVEL! >> "%LOG%"

echo  --- SecHealthUI.exe --- >> "%LOG%"
copy /y "%SRC%\%CABROOT%\f\sechealthui.exe" "%TARGET%\SecHealthUI.exe" >> "%LOG%" 2>&1
echo  SecHealthUI.exe: !ERRORLEVEL! >> "%LOG%"

echo  --- AppShell.winmd --- >> "%LOG%"
copy /y "%SRC%\%CABROOT%\f\sechealthuiappshell.winmd" "%TARGET%\SecHealthUIAppShell.winmd" >> "%LOG%" 2>&1
echo  AppShell.winmd: !ERRORLEVEL! >> "%LOG%"

echo  --- DataModel.dll --- >> "%LOG%"
copy /y "%SRC%\%CABROOT%\f\sechealthuidatamodel.dll" "%TARGET%\SecHealthUIDataModel.dll" >> "%LOG%" 2>&1
echo  DataModel.dll: !ERRORLEVEL! >> "%LOG%"

echo  --- DataModel.winmd --- >> "%LOG%"
copy /y "%SRC%\%CABROOT%\f\sechealthuidatamodel.winmd" "%TARGET%\SecHealthUIDataModel.winmd" >> "%LOG%" 2>&1
echo  DataModel.winmd: !ERRORLEVEL! >> "%LOG%"

echo  --- Telemetry.dll --- >> "%LOG%"
copy /y "%SRC%\%CABROOT%\f\sechealthuitelemetry.dll" "%TARGET%\SecHealthUITelemetry.dll" >> "%LOG%" 2>&1
echo  Telemetry.dll: !ERRORLEVEL! >> "%LOG%"

echo  --- Telemetry.winmd --- >> "%LOG%"
copy /y "%SRC%\%CABROOT%\f\sechealthuitelemetry.winmd" "%TARGET%\SecHealthUITelemetry.winmd" >> "%LOG%" 2>&1
echo  Telemetry.winmd: !ERRORLEVEL! >> "%LOG%"

echo  --- ViewModels.dll --- >> "%LOG%"
copy /y "%SRC%\%CABROOT%\f\sechealthuiviewmodels.dll" "%TARGET%\SecHealthUIViewModels.dll" >> "%LOG%" 2>&1
echo  ViewModels.dll: !ERRORLEVEL! >> "%LOG%"

echo  --- ViewModels.winmd --- >> "%LOG%"
copy /y "%SRC%\%CABROOT%\f\sechealthuiviewmodels.winmd" "%TARGET%\SecHealthUIViewModels.winmd" >> "%LOG%" 2>&1
echo  ViewModels.winmd: !ERRORLEVEL! >> "%LOG%"

echo  --- en-US.pri --- >> "%LOG%"
copy /y "%SRC%\%RESEN%\f\microsoft.windows.sechealthui.en-us.pri" "%TARGET%\pris\resources.en-US.pri" >> "%LOG%" 2>&1
echo  en-US.pri: !ERRORLEVEL! >> "%LOG%"

echo  --- zh-CN.pri --- >> "%LOG%"
copy /y "%SRC%\%RESCN%\f\microsoft.windows.sechealthui.zh-cn.pri" "%TARGET%\pris\resources.zh-CN.pri" >> "%LOG%" 2>&1
echo  zh-CN.pri: !ERRORLEVEL! >> "%LOG%"

echo [4] Done >> "%LOG%"
echo === DEPLOY COMPLETE === >> "%LOG%"
exit /b 0
