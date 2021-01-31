@echo off
setlocal
if "%1"=="" goto usage
call:hostparse %1 hostpre
if not defined hostpre (call:err Warning 50 "Something strange happend during host parsing.") & goto usage
if "%hostpre%" EQU "crierr" goto:eof
if "%hostpre%" EQU "notint" ipmitool %* & goto:eof
goto exec
:hostparse
set /a host=%1 2>NUL || goto hostparsestart
if "%host%" NEQ "%1" (set "%2=notint") & goto:eof
set "%2=100.2.76."
goto:eof
:hostparsestart
set /a secnum=0
for /f "delims=. tokens=1-4,*" %%a in ("%1") do (
    if "%%a" NEQ "" (set seca=%%a) else goto afterhostparse
    if "%%b" NEQ "" (set secb=%%b) else goto afterhostparse
    if "%%c" NEQ "" (set secc=%%c) else goto afterhostparse
    if "%%d" NEQ "" (set secd=%%d) else goto afterhostparse
    if "%%e" NEQ "" (set sece=%%e) else goto afterhostparse
)
:afterhostparse
if defined sece ((call:err Fatal 230 "IP input has more than 4 sections.") & (set "%2=crierr") & goto:eof)
if defined secd (set %2=) & goto:eof
if defined secc (set %2=100.) & goto:eof
if defined secb (set %2=100.2.) & goto:eof
call:err Warning 240 "Script went to an unexpected place!"
goto:eof
:exec
set hostExec=%hostpre%%1
if "%2"=="" ping %hostExec% -n 2 & goto:eof
if /i "%2"=="t" if "%3"=="" ping -t %hostExec% & goto:eof
if /i "%2"=="-t" if "%3"=="" ping -t %hostExec% & goto:eof
if /i "%2"=="c" if "%3"=="" goto connectionMonitor
if /i "%2"=="sol" (
    if "%3"=="" ((call:SOL %1) & goto:eof)
    if "%4"=="" (
        set solArg=%3
        goto solargparse
    )
    goto default
)
if /i "%2"=="bios" ipmitool -I lanplus -U admin -P admin -H %hostExec% chassis bootdev bios & goto:eof
if /i "%2"=="br" ipmitool -I lanplus -U admin -P admin -H %hostExec% chassis bootdev bios & ipmitool -I lanplus -U admin -P admin -H %hostExec% power reset & goto:eof
goto default
:solargparse
if "%solArg:~-4%"==".log" ((call:SOL %1 %3) & goto:eof)
if "%solArg:~-4%"==".txt" ((call:SOL %1 %3) & goto:eof)
:default
ipmitool -I lanplus -U admin -P admin -H %hostpre%%* & goto:eof
:usage
echo.
echo. IPMI script 20201225
echo. Johnny Appleseed ^<lllxvs+github.ipmi@gmail.com^>
echo. 
echo. Usage:
echo.
echo.   ipmi ^<IP^> arg1 [arg2 [...]]               Send IPMITool commands
call:LFN *IP* fn
echo.   ipmi ^<IP^> SOL                             Collect SOL log to %fn%
echo.   ipmi ^<IP^> SOL [^<FN^>.log ^| ^<FN^>.txt]       Collect SOL log to %cd%\^<FileName^>
echo.   ipmi ^<IP^> [t]                             Ping
echo.   ipmi ^<IP^> c                               Connection monitor
echo.   ipmi ^<IP^> BIOS                            Force to enter BIOS setup on next boot
echo.   ipmi ^<IP^> BR                              Force to enter BIOS setup on next boot and reset immediately
echo.   ipmi [arg1 [arg2 [...]]]                  Get ipmitool help on specific parameter(s)
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
set "lfnMonth=%date:~5,2%"
set "lfnYear=%date:~,4%"
set "lfnDay=%date:~8,2%"
set "lfnWf=%cd%\SolLogs\%lfnYear%%lfnMonth%%lfnDay%"
if "%time:~0,1%"==" " (set "lfnHm=0%time:~1,1%%time:~3,2%") else set "lfnHm=%time:~0,2%%time:~3,2%"
if "%3"=="1" if not exist "%lfnWf%" md "%lfnWf%"
set "%2=%lfnWf%\%1.%lfnHm%.log"
goto:eof

:SOL
echo.
echo.^> Deactivating previous SOL...
echo.
ipmitool -I lanplus -U admin -P admin -H %hostExec% sol deactivate
if "%2" NEQ "" set solLfn=%cd%\%2
if not defined solLfn (call:LFN %hostExec% solLfn 1)
type nul> %solLfn% || ((call:err Fatal 510 "Cannot create log file, please consider to change a directory or run as administrator.") & goto:eof)
echo.
echo.^> Log file saved to %solLfn%
echo.^> Activate SOL...
echo.
explorer /select,"%solLfn%"
ipmitool -I lanplus -U admin -P admin -H %hostExec% sol activate >> %solLfn%
goto:eof

:err
echo.
echo.^> %1^(%2^): %~3
echo.
goto:eof

:connectionMonitor
set /a cmMaxRetry=3
title %hostExec%
set "cmWf=%cd%\ConnectionLogs"
if not exist %cmWf% md %cmWf%
set cmCurrentStatus=
call:write "------- Started -------"
:loop
for /f "skip=2 tokens=1-8 delims= " %%a in ('ping %hostExec% -n 1') do (set TtlSeg=%%f) & goto afterfor
:afterfor
if /i "%TtlSeg:~,3%"=="TTL" (
    if not defined cmCurrentStatus (
        set cmCurrentStatus=g
        title %hostExec%: good
        call:write "Connection is good."
        ping localhost -n 2 >NUL
        goto loop
    )
    if /i "%cmCurrentStatus%" EQU "b" (
        set cmCurrentStatus=g
        title %hostExec%: good
        call:write "Became good."
        ping localhost -n 2 >NUL
        goto loop
    )
    if /i "%cmCurrentStatus:~,1%" EQU "b" (
        set cmCurrentStatus=g
        call:write "Just jitters, ignored." 1
        ping localhost -n 2 >NUL
        goto loop
    )
    ping localhost -n 2 >NUL
    goto loop
)
if not defined cmCurrentStatus (
    set cmCurrentStatus=b
    title %hostExec%: bad!
    call:write "Connection is bad!"
    goto loop
)
if /i "%cmCurrentStatus%"=="b" goto loop
if /i "%cmCurrentStatus:~,1%"=="b" goto trans
if "%cmMaxRetry%" GTR "0" (
    set cmCurrentStatus=b0
    call:write "Bad? retrying." 1
    goto loop
) else goto writebad
:trans
set /a cmRetried=%cmCurrentStatus:~-1%
set /a cmRetried+=1
set cmCurrentStatus=b%cmRetried%
if "%cmRetried%" GEQ "%cmMaxRetry%" (set cmCurrentStatus=b) & goto writebad
call:write "Bad cmRetried = %cmRetried%." 1
goto loop
:writebad
title %hostExec%: bad!
call:write "The connection went to bad!"
goto loop
:write
if not exist %cmWf% md %cmWf%
set "cmTimeStamp=%date:~5,2%/%date:~8,2%/%date:~,4% %time%"
if "%2" NEQ "1" (
    echo %cmTimeStamp%: %~1
    set cmLogMsg=%~1
) else set "cmLogMsg=  ~%~1"
echo %cmTimeStamp%: %cmLogMsg% >> %cmWf%\%hostExec%.log
goto:eof
