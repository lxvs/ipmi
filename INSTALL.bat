@REM IPMI script installation
@REM https://lxvs.net/ipmi

@echo off
@echo Installing...
setlocal

set "batchname=%~nx0"
set "batchfolder=%~dp0"
if "%batchfolder:~-1%" == "\" set "batchfolder=%batchfolder:~0,-1%"

pushd %batchfolder%

if not exist %batchfolder%\ipmi.bat (
    >&2 echo ERROR: Couldn't find file ipmi.bat in current directory.
    popd
    pause
    exit /b 1
)

@REM uninstall previous versions
%SystemRoot%\System32\reg.exe query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "IPMI_SCRIPT" 1>nul 2>&1 && (
    @echo Uninstalling previous version installation...
    %SystemRoot%\System32\reg.exe delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /f /v "IPMI_SCRIPT" 1>nul || goto GetAdmin
)

if exist "%SYSTEMROOT%\ipmi.cmd" (
    @echo Uninstalling previous version installation...
    del "%SYSTEMROOT%\ipmi.cmd" || goto GetAdmin
)
if exist "%USERPROFILE%\ipmi.bat" (
    @echo Uninstalling previous version installation...
    pushd %USERPROFILE%
    del /f /q ipmi.bat CHANGELOG LICENSE README.md VERSION ipmitool.exe libeay32.dll 1>nul 2>&1
    popd
)

pushd %USERPROFILE%
set "conflict="
for /f %%i in ('where ipmi 2^>NUL') do set "conflict=%%~i"

if defined conflict (
    if "%batchfolder%\ipmi.bat" == "%conflict%" (
        >&2 echo ERROR: this version has already installed.
    ) else (
        >&2 echo ERROR: found a name conflict with %conflict%
    )
    popd
    popd
    pause
    exit /b 1
)
popd

for /f "skip=2 tokens=1,2*" %%a in ('%SystemRoot%\System32\reg.exe query "HKCU\Environment" /v "Path" 2^>NUL') do if /i "%%~a" == "path" set "UserPath=%%c"
if not defined UserPath (
    >&2 echo Unknown error.
    popd
    pause
    exit /b 1
)

setx PATH "%batchfolder%;%UserPath%" 1>NUL || (
    popd
    pause
    exit /b 1
)

%SystemRoot%\System32\reg.exe add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\ipmi.exe" /ve /d "%batchfolder%\ipmi.bat" 1>nul

@echo Complete.
@echo;
@echo Now you can use command 'ipmi' everywhere in Command Prompt or PowerShell.
@echo Please close all CMD/PowerShell windows to make changes take effect.
popd
pause
exit /b 0

:GetAdmin
@echo;
@echo     Requesting Administrative Privileges...
@echo     Press YES in UAC Prompt to Continue
@echo;
>"%TEMP%\uac.vbs" (
echo Set UAC = CreateObject^("Shell.Application"^)
echo args = "ELEV "
echo For Each strArg in WScript.Arguments
echo args = args ^& strArg ^& " "
echo Next
echo UAC.ShellExecute "%batchname%", args, "%batchfolder%", "runas", 1
)
cscript //nologo "%TEMP%\uac.vbs"
del /f "%TEMP%\uac.vbs"
exit /b
