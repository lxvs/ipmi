@echo off
if "%1" EQU "" (goto usage)
set /a host=%1
if %host% NEQ %1 (goto usage)
if "%2" EQU "" (
    ping 100.2.76.%1
    goto:eof
)
ipmitool -I lanplus -U admin -P admin -H 100.2.76.%*
goto:eof
:usage
echo.
echo. IPMI script by Johnny Appleseed ^<lllxvs+github.ipmi@gmail.com^> Updated on 20201115
echo. 
echo. Usage:
echo.
echo.   ipmi 255 arg1 arg2 arg3
echo.   stands for:
echo.   ipmitool -I lanplus -U admin -P admin -H 100.2.76.255 arg1 arg2 arg3
echo.
echo.   ipmi 255
echo.   stands for:
echo.   ping 100.2.76.255
echo.
goto:eof
