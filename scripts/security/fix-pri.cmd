@echo off
setlocal enabledelayedexpansion
set "LOGFILE=C:\Windows\Temp\fix_pri_result.txt"
echo [%date% %time%] Starting PRI fix... > "%LOGFILE%"

set "TARGET=C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy\pris\resources.zh-CN.pri"
set "SOURCE=C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy\pris\resources.en-US.pri"

echo [1/5] Checking source file... >> "%LOGFILE%"
if not exist "%SOURCE%" (
    echo FAIL: Source en-US.pri not found >> "%LOGFILE%"
    exit /b 1
)
echo OK: Source exists >> "%LOGFILE%"

echo [2/5] Taking ownership from TrustedInstaller... >> "%LOGFILE%"
takeown /f "%TARGET%" >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    echo WARN: takeown failed, trying icacls anyway... >> "%LOGFILE%"
)

echo [3/5] Granting write access... >> "%LOGFILE%"
icacls "%TARGET%" /grant "SYSTEM:(F)" /grant "Administrators:(F)" /inheritance:e >> "%LOGFILE%" 2>&1
echo icacls exit: %ERRORLEVEL% >> "%LOGFILE%"

echo [4/5] Copying en-US PRI over damaged zh-CN PRI... >> "%LOGFILE%"
copy /y "%SOURCE%" "%TARGET%" >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    echo FAIL: Copy failed - file is still locked >> "%LOGFILE%"
    echo Trying alternative: rename approach... >> "%LOGFILE%"
    ren "%TARGET%" "resources.zh-CN.pri.bak" >> "%LOGFILE%" 2>&1
    copy /y "%SOURCE%" "%TARGET%" >> "%LOGFILE%" 2>&1
    if errorlevel 1 (
        echo FAIL: All approaches failed >> "%LOGFILE%"
        exit /b 1
    )
)

echo [5/5] Verifying... >> "%LOGFILE%"
fc /b "%TARGET%" "%SOURCE%" >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    echo WARN: Files differ (size check)... >> "%LOGFILE%"
    dir "%TARGET%" "%SOURCE%" >> "%LOGFILE%" 2>&1
) else (
    echo OK: Files are identical >> "%LOGFILE%"
)

echo === DONE - Restart Explorer to apply === >> "%LOGFILE%"
exit /b 0
