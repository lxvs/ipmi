@echo off
setlocal
REM --- Default values are set here
set "defaultHostPrefix=100.2.76"
set /a cmMaxRetry=3
set /a cmLogLvl=2
set /a cmColorEnabled=1
REM --- Default Values end
set "_version=4.23.0"
title IPMI %_version%
if "%cmColorEnabled%"=="1" (
    set "clrSuf=[0m"
    set "errPre=[101;93m"
) else (
    set clrSuf=
    set errPre=
)
if "%~1"=="" goto usage
set cmLogLvlTmp=
set cmMaxRetryTmp=
echo %1 | findstr /i "? help usage" >NUL && goto usage
if /i "%~1"=="-v" goto version
if /i "%~1"=="/v" goto version
echo %1 | findstr /i "version" >NUL && goto version
call:hostparse %1 hostpre
if "%hostpre%" EQU "crierr" goto:eof
if "%hostpre%" EQU "notint" ipmitool %* & goto:eof
goto exec
:hostparse
set /a host=%1 2>NUL || goto hostparsestart
if "%host%" NEQ "%~1" (set "%2=notint") & goto:eof
REM integer without dot.
:hostparsestart
for /f "delims=. tokens=1-3" %%a in ("%defaultHostPrefix%") do (
    if %%a. NEQ . (set prea=%%a) else goto hostparsemid
    if %%b. NEQ . (set preb=%%b) else goto hostparsemid
    if %%c. NEQ . (set prec=%%c) else goto hostparsemid
)
:hostparsemid
for /f "delims=. tokens=1-4,*" %%a in ("%~1") do (
    if "%%a" NEQ "" (set seca=%%a) else goto afterhostparse
    if "%%b" NEQ "" (set secb=%%b) else goto afterhostparse
    if "%%c" NEQ "" (set secc=%%c) else goto afterhostparse
    if "%%d" NEQ "" (set secd=%%d) else goto afterhostparse
    if "%%e" NEQ "" (set sece=%%e) else goto afterhostparse
)
:afterhostparse
if defined sece ((call:err Error 230 "IP input has more than 4 sections.") & (set "%2=crierr") & goto:eof)
if defined secd (set %2=) & goto:eof
if defined secc if defined prea (set %2=%prea%.) & goto:eof
if defined secb if defined preb (set %2=%prea%.%preb%.) & goto:eof
if defined seca if defined prec (set %2=%prea%.%preb%.%prec%.) & goto:eof
call:err Error 240 "Parsed IP has less than 4 sections." ^
         "Check either input or variable 'defaultHostPrefix'."
set "%2=crierr"
goto:eof
:exec
set hostExec=%hostpre%%1
if "%~2"=="" ping %hostExec% -n 2 & goto:eof
if /i "%~2"=="t" if "%~3"=="" ping -t %hostExec% & goto:eof
if /i "%~2"=="-t" if "%~3"=="" ping -t %hostExec% & goto:eof
if /i "%~2"=="cm" if "%~3"=="" (set cmVer=0) & goto connectionMonitor
if /i "%~2"=="c" (
    set cmVer=1
    if "%~3"=="" goto connectionMonitor
    goto preCmParse
    )
if /i "%~2"=="sol" (
    if "%~3"=="" ((call:SOL %1) & goto:eof)
    if "%~4"=="" (
        set solArg=%3
        goto solargparse
    )
    goto default
)
if /i "%~2"=="fan" (
    if "%~3"=="" ipmitool -I lanplus -U admin -P admin -H %hostExec% raw 0x3c 0x2f & goto:eof
    if "%~3"=="0" ipmitool -I lanplus -U admin -P admin -H %hostExec% raw 0x3c 0x2e 0 & goto:eof
    if "%~3"=="auto" ipmitool -I lanplus -U admin -P admin -H %hostExec% raw 0x3c 0x2e 0 & goto:eof
    ipmitool -I lanplus -U admin -P admin -H %hostExec% raw 0x3c 0x2e 1
    ipmitool -I lanplus -U admin -P admin -H %hostExec% raw 0x3c 0x2c 0xff %3
    goto:eof
)
if /i "%~2"=="bios" ipmitool -I lanplus -U admin -P admin -H %hostExec% chassis bootdev bios & goto:eof
if /i "%~2"=="br" ipmitool -I lanplus -U admin -P admin -H %hostExec% chassis bootdev bios & ipmitool -I lanplus -U admin -P admin -H %hostExec% power reset & goto:eof
goto default
:preCmParse
if /i "%~3"=="" goto postCmParse
if /i "%~3"=="-L" (
    if "%~4"=="" goto postCmParse
    set cmLogLvlTmp=%4
    shift /3
    shift /3
    goto preCmParse
)
if /i "%~3"=="-M" (
    if "%~4"=="" goto postCmParse
    set cmMaxRetryTmp=%4
    shift /3
    shift /3
    goto preCmParse
)
call:err Warning 760 "Unsupported CM parameter(s) met!"
:postCmParse
set /a cmLogLvlTmpPost=cmLogLvlTmp
set /a cmMaxRetryTmpPost=cmMaxRetryTmp
if "%cmLogLvlTmp%" NEQ "" if "%cmLogLvlTmpPost%"=="%cmLogLvlTmp%" (set /a cmLogLvl=cmLogLvlTmpPost) else call:err Warning 800 "Parameter 'log level' was designated but did not applied."
if "%cmMaxRetryTmp%" NEQ "" if "%cmMaxRetryTmpPost%"=="%cmMaxRetryTmp%" (set /a cmMaxRetry=cmMaxRetryTmpPost) else call:err Warning 840 "Parameter 'max retry' was designated but did not applied."
goto connectionMonitor
:solargparse
if "%solArg:~-4%"==".log" ((call:SOL %1 %3) & goto:eof)
if "%solArg:~-4%"==".txt" ((call:SOL %1 %3) & goto:eof)
:default
ipmitool -I lanplus -U admin -P admin -H %hostpre%%* & goto:eof
:usage
echo;
echo  IPMI script %_version%
echo  https://github.com/lxvs/ipmi
echo;
echo  Usage:
echo;
echo    ipmi ^<IP^> arg1 [arg2 [...]]               Send IPMITool commands
echo    ipmi version ^| -v ^| /v                    Get current and latest version
echo    ipmi [? ^| help ^| usage]                   Get help on this script
call:LFN *IP* fn
echo    ipmi ^<IP^> SOL                             Collect SOL log to %fn%
echo    ipmi ^<IP^> SOL [^<FN^>.log ^| ^<FN^>.txt]       Collect SOL log to %cd%\^<FileName^>
echo    ipmi ^<IP^> [t]                             Ping
echo    ipmi ^<IP^> BIOS                            Force to enter BIOS setup on next boot
echo    ipmi ^<IP^> BR                              Force to enter BIOS setup on next boot and reset immediately
echo    ipmi ^<IP^> cm                              Connection monitor legacy
echo    ipmi ^<IP^> c [-L ^<L^>] [-M ^<M^>]             Connection monitor upgraded: also monitors if bmc web is ready.
echo                                                  ^<L^> for Log level:
echo                                                          0: Do not write any log.
echo                                                          1: Log only what shows in console.
echo                                                          2: ^(default^) Also log retries before anouncing a bad
echo                                                             connection, and http code changes.
echo                                                          3: Also log every ping and http code result.
echo                                                  ^<M^> for Max retry:  ^(default: 3^)
echo                                                          Retrying times before anouncing a bad connection.
echo    ipmi ^<IP^> fan                             ^(Need Porting^) Request current fan mode. 00: auto, 01: manual
echo    ipmi ^<IP^> fan 0^|auto                      ^(Need Porting^) Set fan mode to auto
echo    ipmi ^<IP^> fan ^<speed^>                     ^(Need Porting^) Set fan speed ^(1~100^)
pause>NUL
echo    ipmi [arg1 [arg2 [...]]]                  Get ipmitool help on specific parameter^(s^)
echo;
echo  Examples:
echo;
echo    If defaultHostPrefix was set to '100.2.76.', then
echo;
echo    'ipmi 255 arg1 arg2 arg3' stands for:
echo;
echo    ipmitool -I lanplus -U admin -P admin -H 100.2.76.255 arg1 arg2 arg3
goto:eof

:LFN
call:gettime lfnYear lfnMon lfnDay lfnHour lfnMin
set "lfnWf=%cd%\SolLogs\%lfnYear%-%lfnMon%-%lfnDay%"
if "%~3"=="1" if not exist "%lfnWf%" md "%lfnWf%"
set "%2=%lfnWf%\%1.%lfnHour%%lfnMin%.log"
goto:eof

:SOL
title %hostexec% SOL
echo;
echo ^> Deactivating previous SOL...
ipmitool -I lanplus -U admin -P admin -H %hostExec% sol deactivate
if "%~2" NEQ "" set solLfn=%cd%\%2
if not defined solLfn (call:LFN %hostExec% solLfn 1)
type nul> %solLfn% || ((call:err Fatal 510 "Cannot create log file" "please consider to change a directory or run as administrator.") & goto:eof)
echo;
echo ^> Log file saved to %solLfn%
echo ^> Activate SOL...
explorer /select,"%solLfn%"
(ipmitool -I lanplus -U admin -P admin -H %hostExec% sol activate)> %solLfn%
goto:eof

:err
echo %errPre%^> %~1^(%~2^): %~3%clrSuf%
:errshift
shift /3
if "%~3" NEQ "" (echo %errPre%-^> %~3%clrSuf%) & goto errshift
goto:eof

:connectionMonitor
title %hostExec%
set "cmWf=%cd%\ConnectionLogs"
if not exist "%cmWf%" md "%cmWf%"
set cmCurrentStatus=
set cmBmcWebStatus=
set cmLastHttpCode=
call:write "----------------------------------------------------------------"
call:write "Host:           %hostExec%"
call:write "Max retry:      %cmMaxRetry%"
if "%cmVer%"=="1" (
call:write "Log level:      %cmLogLvl%"
if %cmLogLvl% GTR 0 ^
call:write "Log folder:     %cmWf%"
) else call:write "Log folder:     %cmWf%"
call:write "----------------------------------------------------------------"
:loop
for /f "skip=2 tokens=1-8 delims= " %%a in ('ping %hostExec% -n 1') do (set TtlSeg=%%f) & goto afterfor
:afterfor
if /i "%TtlSeg:~,3%"=="TTL" (
    call:write "ping: OK." 2
    if not defined cmCurrentStatus (
        set cmCurrentStatus=g
        if "%cmver%"=="1" call:write "DEBUG: calling GHC because status is not defined." 8
        if "%cmver%"=="1" (call:gethttpcode "BMC web is not ready!" "BMC web is ready." 1) else call:write "Connection is good." g
        ping localhost -n 2 >NUL
        goto loop
    )
    if /i "%cmCurrentStatus%" EQU "b" (
        set cmCurrentStatus=g
        if "%cmver%"=="1" call:write "DEBUG: calling GHC because status turns good." 8
        if "%cmver%"=="1" (call:gethttpcode "BMC web is not ready!" "BMC web is ready.") else call:write "Became good." g
        ping localhost -n 2 >NUL
        goto loop
    )
    if /i "%cmCurrentStatus:~,1%" EQU "b" (
        set cmCurrentStatus=g
        call:write "Just jitters, ignored." 1
        if "%cmver%"=="1" call:write "DEBUG: calling GHC because of jitters." 8
        if "%cmver%"=="1" call:gethttpcode "BMC web is not ready!" "BMC web is ready."
        ping localhost -n 2 >NUL
        goto loop
    )
    if "%cmver%"=="1" call:write "DEBUG: calling GHC mandatorily." 8
    if "%cmver%"=="1" call:gethttpcode "BMC web got lost!" "BMC web is ready."
    ping localhost -n 2 >NUL
    goto loop
)
call:write "ping: bad!" 2
if not defined cmCurrentStatus goto writebad
if /i "%cmCurrentStatus%"=="b" goto loop
if /i "%cmCurrentStatus:~,1%"=="b" goto trans
if "%cmMaxRetry%" GTR "0" (
    set cmCurrentStatus=b0
    call:write "Bad? retrying." 1
    goto loop
) else goto writebad
:gethttpcode
for /f %%i in ('curl -so /dev/null -Iw %%{http_code} %hostExec%') do (
    call:write "DEBUG: HTTP code updated:   %cmLastHttpCode% to %%i" 8
    call:write "DEBUG: BMC web status:      %cmBmcWebStatus%" 8
    call:write "HTTP code: %%i" 2
    if "%%i" NEQ "%cmLastHttpCode%" (set cmLastHttpCode=%%i) & call:write "HTTP code updated: %%i" 1
    if "%%i"=="000" (
        if "%~3" NEQ "" (
            call:write "%~1" r
            set cmBmcWebStatus=b
        ) else if /i "%cmBmcWebStatus%" NEQ "b" (
            call:write "%~1" r
            set cmBmcWebStatus=b
        )
    ) else (
        if "%~3" NEQ "" (
            call:write "%~2" g
            set cmBmcWebStatus=g
        ) else if /i "%cmBmcWebStatus%" NEQ "g" (
            call:write "%~2" g
            set cmBmcWebStatus=g
        )
    )
)
goto:eof
:trans
set /a cmRetried=%cmCurrentStatus:~-1%
set /a cmRetried+=1
set cmCurrentStatus=b%cmRetried%
if "%cmBmcWebStatus%"=="b" set /a "cmRetried=cmMaxRetry"
if %cmRetried% GEQ %cmMaxRetry% goto writebad
call:write "Bad, retried = %cmRetried%." 1
goto loop
:writebad
set cmCurrentStatus=b
set cmBmcWebStatus=
set cmLastHttpCode=
call:write "Connection went bad!" r
goto loop
:write
REM %1:message
REM %2:color (0/Red/Green/Yellow/Blue/Magenta/Cyan)
REM    /MsgLvl (0-9)
set cmClr=%2
set /a cmMsgLvl=cmClr
set cmPre=
set cmSuf=
if "%cmColorEnabled%" NEQ "1" goto cmgo
if "%cmClr%"=="" goto cmgo
if "%cmClr%"=="%cmMsgLvl%" goto cmgo
if /i "%cmClr%"=="r" (set "cmPre=[91m") & (set "cmSuf=[0m") & goto cmgo
if /i "%cmClr%"=="g" (set "cmPre=[92m") & (set "cmSuf=[0m") & goto cmgo
if /i "%cmClr%"=="y" (set "cmPre=[93m") & (set "cmSuf=[0m") & goto cmgo
if /i "%cmClr%"=="b" (set "cmPre=[94m") & (set "cmSuf=[0m") & goto cmgo
if /i "%cmClr%"=="m" (set "cmPre=[95m") & (set "cmSuf=[0m") & goto cmgo
if /i "%cmClr%"=="c" (set "cmPre=[96m") & (set "cmSuf=[0m") & goto cmgo
:cmgo
if %cmMsgLvl% NEQ 0 if %cmMsgLvl% GEQ %cmLogLvl% goto:eof
call:gettime cmyear cmMon cmDay cmHour cmMin cmSec
set "cmTimeStamp=%cmyear%-%cmmon%-%cmday% %cmhour%:%cmmin%:%cmsec%"
set "cmLogMsg=%~1"
if %cmMsgLvl%==0 echo %cmpre%%cmTimeStamp% %cmLogMsg%%cmsuf%
if %cmMsgLvl% GEQ %cmLogLvl% goto:eof
if not exist "%cmWf%" md "%cmWf%"
if %cmLogLvl% LEQ 0 goto:eof
if %cmMsgLvl%==0 (echo %cmTimeStamp% %cmLogMsg%)>> "%cmWf%\%hostExec%.log"
if %cmLogLvl% LEQ 1 goto:eof
if %cmMsgLvl% LSS %cmLogLvl% (echo %cmTimeStamp% %cmLogMsg%)>> "%cmWf%\%hostExec%.verbose.log"
goto:eof

:gettime
for /f "tokens=1-6 usebackq delims=_" %%a in (`powershell -command "&{Get-Date -format 'yyyy_MM_dd_HH_mm_ss'}"`) do (
    if "%1" NEQ "" set "%1=%%a" else goto:eof
    if "%2" NEQ "" set "%2=%%b" else goto:eof
    if "%3" NEQ "" set "%3=%%c" else goto:eof
    if "%4" NEQ "" set "%4=%%d" else goto:eof
    if "%5" NEQ "" set "%5=%%e" else goto:eof
    if "%6" NEQ "" set "%6=%%f" else goto:eof
)
goto:eof

:version
echo;
echo version: %_version%
set /p=latest:  <NUL
curl "https://raw.githubusercontent.com/lxvs/ipmi/main/VERSION" 2>NUL || echo failed to get.
goto:eof
