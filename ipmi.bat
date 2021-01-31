@echo off
setlocal
if "%1"=="" goto usage
set /a host=%1 2>NUL || goto hostparse
if "%host%" NEQ "%1" ipmitool %* & goto:eof
set hostpre=100.2.76.
goto exec
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
if defined secd (set hostpre=) & goto exec
if defined secc (set hostpre=100.) & goto exec
if defined secb (set hostpre=100.2.) & goto exec
call:err Warning 240 "Script went to an unexpected place!"
:exec
if "%2"=="" ping %hostpre%%1 -n 2 & goto:eof
if /i "%2"=="t" if "%3"=="" ping -t %hostpre%%1 & goto:eof
if /i "%2"=="-t" if "%3"=="" ping -t %hostpre%%1 & goto:eof
if /i "%2"=="sol" (
    if "%3"=="" ((call:SOL %1) & goto:eof)
    if "%4"=="" (
        set solarg=%3
        goto solargparse
    )
    goto default
)
goto default
:solargparse
if "%solarg:~-4%"==".log" ((call:SOL %1 %3) & goto:eof)
if "%solarg:~-4%"==".txt" ((call:SOL %1 %3) & goto:eof)
:default
ipmitool -I lanplus -U admin -P admin -H %hostpre%%* & goto:eof
:usage
echo.
echo. IPMI script 20201127
echo. Johnny Appleseed ^<lllxvs+github.ipmi@gmail.com^>
echo. 
echo. Usage:
echo.
echo.   ipmi ^<IP^> arg1 [arg2 [...]]               Send IPMITool commands
call:LFN xxx fn
echo.   ipmi ^<IP^> SOL                             Collect SOL log to %fn%
echo.   ipmi ^<IP^> SOL [^<FN^>.log ^| ^<FN^>.txt]       Collect SOL log to %cd%\^<FileName^>
echo.   ipmi ^<IP^> [t]                             Ping
echo.   ipmi [arg1 [arg2 [...]]]                  Get ipmitool help on specific parameter(s).
echo.
echo. Examples:
echo.   ipmi 255 arg1 arg2 arg3
echo.     stands for:
echo.   ipmitool -I lanplus -U admin -P admin -H 100.2.76.255 arg1 arg2 arg3
echo.
echo.   ipmi 254.255 t
echo.     stands for:
echo.   ping 100.2.254.255 -t
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
ipmitool -I lanplus -U admin -P admin -H %hostpre%%1 sol deactivate
if "%2" NEQ "" set logfilename=%cd%\%2
if not defined logfilename (call:LFN %1 logfilename 1)
type nul> %logfilename% || ((call:err Fatal 510 "Cannot create log file, please consider to change a directory or run as administrator.") & goto:eof)
echo.
echo.^> Log file saved to %logfilename%
echo.^> Activate SOL...
echo.
explorer /select,"%logfilename%"
ipmitool -I lanplus -U admin -P admin -H %hostpre%%1 sol activate >> %logfilename%
goto:eof

:err
echo.
echo.^> %1^(%2^): %~3
echo.
goto:eof
