@echo off
setlocal
if "%1"=="" goto usage
if /i "%1"=="t" if "%3"=="" ping -t 100.2.76.%2 & goto:eof
if /i "%1"=="-t" if "%3"=="" ping -t 100.2.76.%2 & goto:eof
set /a host=%1 2>NUL || goto hostparse
if "%host%" NEQ "%1" ipmitool %* & goto:eof
if "%2"=="" ping 100.2.76.%1 & goto:eof
if /i "%2"=="t" if "%3"=="" ping -t 100.2.76.%1 & goto:eof
if /i "%2"=="-t" if "%3"=="" ping -t 100.2.76.%1 & goto:eof
if /i "%2"=="sol" if "%3"=="" goto SOL
ipmitool -I lanplus -U admin -P admin -H 100.2.76.%* & goto:eof
:hostparse
set /a secnum=0
for /f "delims=. tokens=1-4,*" %%a in ("%1") do (
    if "%%a" NEQ "" (set seca=%%a) else goto afterhostparse
    if "%%b" NEQ "" (set secb=%%b) else goto afterhostparse
    if "%%c" NEQ "" (set secc=%%c) else goto afterhostparse
    if "%%d" NEQ "" (set secd=%%d) else goto afterhostparse
    if "%%e" NEQ "" (set sece=%%e) else goto afterhostparse
)
:afterhostparse
if defined sece ((call:err Fatal 230 "IP input has more than 4 sections.") & goto:eof)
:usage
echo.
echo. IPMI script 20201126
echo. Johnny Appleseed ^<lllxvs+github.ipmi@gmail.com^>
echo. 
echo. Usage:
echo.
echo.   ipmi ^<last section of IP^> arg1 [arg2 [...]]   Send IPMITool commands
call:LFN xxx fn
echo.   ipmi ^<last section of IP^> SOL                 Collect SOL log to %fn%
echo.   ipmi ^<last section of IP^> [t]                 Ping
echo.   ipmi [arg1 [arg2 [...]]]                      Get ipmitool help on specific parameter(s).
echo.
echo. Examples:
echo.   ipmi 255 arg1 arg2 arg3
echo.     stands for:
echo.   ipmitool -I lanplus -U admin -P admin -H 100.2.76.255 arg1 arg2 arg3
echo.
echo.   ipmi t 255
echo.     stands for:
echo.   ping -t 100.2.76.255
echo.
goto:eof

:LFN
set "month=%date:~5,2%"
set "year=%date:~,4%"
if "%date:~8,1%"=="0" (set "day=%date:~9,1%") else set "day=%date:~8,2%"
if "%time:~0,1%"==" " (set "hm=0%time:~1,1%%time:~3,2%") else set "hm=%time:~0,2%%time:~3,2%"
if "%3"=="1" if not exist "SOLlogs\%year%%month%%day%" md "SOLlogs\%year%%month%%day%"
set "%2=%cd%\SOLlogs\%year%%month%%day%\76.%1.%hm%.log"
goto:eof

:SOL
echo.
echo.^> Deactivating previous SOL...
echo.
ipmitool -I lanplus -U admin -P admin -H 100.2.76.%1 sol deactivate
call:LFN %1 logfilename 1
type nul> %logfilename% || ((call:err Fatal 510 "Cannot create log file, please consider to change a directory or run as administrator.") & goto:eof)
echo.
echo.^> Log file saved to %logfilename%
echo.^> Activate SOL...
echo.
explorer /select,"%logfilename%"
ipmitool -I lanplus -U admin -P admin -H 100.2.76.%1 sol activate >> %logfilename%
goto:eof

:err
echo.
echo.^> %1 error (%2): %~3
goto:eof
