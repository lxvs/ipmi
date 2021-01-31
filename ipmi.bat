@echo off
if "%1"=="" goto usage
set /a host=%1 >NUL 2>&1
if "%host%" NEQ "%1" goto usage
if "%2"=="" ping 100.2.76.%1 & goto:eof
if "%2"=="t" if "%3"=="" ping -t 100.2.76.%1 & goto:eof
if "%2"=="-t" if "%3"=="" ping -t 100.2.76.%1 & goto:eof
if "%2"=="sol" (
    SETLOCAL ENABLEDELAYEDEXPANSION
    if "%date:~5,2%"=="10" set "month=A" & goto continue
    if "%date:~5,2%"=="11" set "month=B" & goto continue
    if "%date:~5,2%"=="12" set "month=C" & goto continue
    set "month=%date:~6,1%"
    :continue
    if "%date:~8,1%"=="0" (set "day=%date:~9,1%") else set "day=%date:~8,2%"
    if "%time:~0,1%"==" " (set "hm=%time:~1,1%%time:~3,1%") else set "hm=%time:~0,2%%time:~3,1%"
    set "logfile=76.%1.!month!!day!.!hm!.log"
    ipmitool -I lanplus -U admin -P admin -H 100.2.76.%1 sol deactivate >NUL 2>&1
    ipmitool -I lanplus -U admin -P admin -H 100.2.76.%1 sol activate > !logfile!
    SETLOCAL DISABLEDELAYEDEXPANSION
    goto:eof
)
ipmitool -I lanplus -U admin -P admin -H 100.2.76.%*
goto:eof
:usage
echo.
echo. IPMI script by Johnny Appleseed ^<lllxvs+github.ipmi@gmail.com^> Updated on 20201116
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
