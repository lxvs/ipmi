@REM Run this script to setup in order to call ipmi everywhere.
@REM https://github.com/lxvs/ipmi

@setlocal
@set "fn=ipmi.cmd"
@pushd "%SYSTEMROOT%"
@if exist "%fn%" (
    del "%fn%" 1>nul 2>&1
    if exist "%fn%" goto err
)

@where /q ipmi && (
    @echo ERROR: found a name conflict with:
    @where ipmi
    @pause
    exit /b 1
)

@if not exist %~dp0\ipmi.bat (
    @echo ERROR: Couldn't find file ipmi.bat in current directory.
    @pause
    exit /b 2
)

@set "pth=%~dp0"
@if "%pth:~-1%" == "\" (set "pth=%pth%ipmi.bat") else set "pth=%pth%\ipmi.bat"
@setx IPMI_SCRIPT "%pth%" /m 1>nul || goto err

@>"%fn%" (
echo @if not defined IPMI_SCRIPT ^(
echo     @echo ERROR: environment variable IPMI_SCRIPT not defined. Please run %~nx0 as Administrator to fix it.
echo     exit /b 1
echo ^)
echo @if not exist %%IPMI_SCRIPT%% ^(
echo     @echo ERROR: couldn't find the ipmi script. Please run %~nx0 as Administrator to fix it.
echo     exit /b 2
echo ^)
echo @%%IPMI_SCRIPT%% %%*
) || goto err

@pushd "%USERPROFILE%"
@if exist "ipmi.bat" (
    @echo removing 4.x verison of ipmi script.
    @del /f /q ipmi.bat CHANGELOG LICENSE README.md VERSION ipmitool.exe libeay32.dll 1>nul 2>&1
)
@popd

@echo Complete!
@echo Now you can use command 'ipmi' everywhere in Command Prompt or PowerShell.
@echo Please close all CMD/PowerShell consoles to make changes take effect.
@pause
@exit /b 0

:err
@echo ERROR: Please make sure to run as Administrator.
@pause
@exit /b 3
