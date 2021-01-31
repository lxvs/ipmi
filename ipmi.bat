@echo off
if "%1"=="" goto usage
if /i "%1"=="t" if "%3"=="" ping -t 100.2.76.%2 & goto:eof
if /i "%1"=="-t" if "%3"=="" ping -t 100.2.76.%2 & goto:eof
set /a host=%1
if "%host%" NEQ "%1" goto usage
if "%2"=="" ping 100.2.76.%1 & goto:eof
if /i "%2"=="t" if "%3"=="" ping -t 100.2.76.%1 & goto:eof
if /i "%2"=="-t" if "%3"=="" ping -t 100.2.76.%1 & goto:eof
if /i "%2"=="sol" goto SOL
ipmitool -I lanplus -U admin -P admin -H 100.2.76.%* & goto:eof
:usage
echo.
echo. IPMI script 20201120
echo. Johnny Appleseed ^<lllxvs+github.ipmi@gmail.com^>
echo. 
echo. Usage:
echo.
echo.   ipmi ^<last section of IP^> [t]                         Ping
echo.   ipmi ^<last section of IP^> [arg1 [arg2 [arg3 [...]]]   Send IPMITool commands
call:LFN xxx fn
echo.   ipmi ^<last section of IP^> SOL                         Collect SOL log to %cd%\%fn%
echo.
echo. Examples:
echo.   ipmi 255 arg1 arg2 arg3
echo.     stands for
echo.   ipmitool -I lanplus -U admin -P admin -H 100.2.76.255 arg1 arg2 arg3
echo.
echo.   ipmi 255
echo.     stands for:
echo.   ping 100.2.76.255
echo.
goto:eof

:LFN
set "month=%date:~5,2%"
if "%date:~8,1%"=="0" (set "day=%date:~9,1%") else set "day=%date:~8,2%"
if "%time:~0,1%"==" " (set "hm=0%time:~1,1%%time:~3,2%") else set "hm=%time:~0,2%%time:~3,2%"
set "%2=76.%1.%month%%day%.%hm%.log"
goto:eof

:SOL
ipmitool -I lanplus -U admin -P admin -H 100.2.76.%1 sol deactivate >NUL 2>&1
call:LFN %1 logfilename
type nul> %logfilename%
explorer /select,"%cd%\%logfilename%"
ipmitool -I lanplus -U admin -P admin -H 100.2.76.%1 sol activate >> %logfilename%
goto:eof
