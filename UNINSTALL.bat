@REM IPMI script uninstallation
@REM Only applies to v5.2.0 and above
@REM https://lxvs.net/ipmi

@echo off
@echo Uninstalling...
setlocal EnableExtensions EnableDelayedExpansion
set "batchfolder=%~dp0"
if "%batchfolder:~-1%" == "\" set "batchfolder=%batchfolder:~0,-1%"
for /f "skip=2 tokens=1,2*" %%a in ('%SystemRoot%\System32\reg.exe query "HKCU\Environment" /v "Path" 2^>NUL') do if /i "%%~a" == "path" set "UserPath=%%c"
if not defined UserPath (
    >&2 echo Unknown error.
    popd
    pause
    exit /b 1
)
setx PATH "!UserPath:%batchfolder%;=!" 1>NUL || (
    popd
    pause
    exit /b 1
)
%SystemRoot%\System32\reg.exe delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\ipmi.exe" /f 1>nul 2>&1
@echo Complete.
@pause
@exit /b 0
