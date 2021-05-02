@REM Run this script to revert everything ipmi_setup.bat did.
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

@REG query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "IPMI_SCRIPT" 1>nul 2>&1

@if %errorlevel% EQU 0 @REG delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /f /v "IPMI_SCRIPT" 1>nul || goto err

@echo Complete!
@echo Now everything ipmi_setup.bat did was all reverted.
@pause
@exit /b 0

:err
@echo ERROR: Please make sure to run as Administrator.
@pause
@exit /b 3
