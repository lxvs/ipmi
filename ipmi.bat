@echo off
@setlocal enableExtensions enableDelayedExpansion

set "precd=%cd%"
if "%precd:~-1%" == "\" set "precd=%precd:~0,-1%"
@pushd "%~dp0"

@if not defined defaultHostPrefix set "defaultHostPrefix=100.2.76"
@if not defined bmcUsername set "bmcUsername=admin"
@if not defined bmcPassword set "bmcPassword=admin"
@if not defined ipmiInterface set "ipmiInterface=lanplus"
@if not defined jviewerPath set "jviewerPath=%USERPROFILE%\Programs\JViewer\JViewer.jar"

@if not defined globalColorEnabled set /a "globalColorEnabled=1"

@if not defined cmPingRetry set /a "cmPingRetry=3"
@if not defined cmEwsRetry set /a "cmEwsRetry=2"
@if not defined cmLogLvl set /a "cmLogLvl=2"
@if not defined cmColorEnabled set /a "cmColorEnabled=1"
@if not defined cmEwsTimeOut_s set /a "cmEwsTimeout_s=1"
@if not defined cmPingTimeout_ms set /a "cmPingTimeout_ms=100"

@if not defined loopShowTimeStamps set /a "loopShowTimeStamps=1"
@if not defined monitorShowTimeStamps set /a "monitorShowTimeStamps=1"
@if not defined loopInterval_s set /a "loopInterval_s=30"
@if not defined monitorInterval_s set /a "monitorInterval_s=30"

@if not defined solWorkFolder set "solWorkFolder=%cd%\log\sol"
@if not defined cmWorkFolder set "cmWorkFolder=%cd%\log\cm"

@if "%globalColorEnabled%" == "1" (
    @set "redPre=[91m"
    @set "greenPre=[92m"
    @set "yellowPre=[93m"
    @set "bluePre=[94m"
    @set "magentaPre=[95m"
    @set "cyanPre=[96m"
    @set "clrSuf=[0m"
) else (
    set "redPre="
    set "greenPre="
    set "yellowPre="
    set "bluePre="
    set "magentaPre="
    set "cyanPre="
    set "clrSuf="
)
@set "_ver=5.4.0"
@title IPMI %_ver%
if "%~1"=="" goto usage
@set "cmLogLvlTmp="
@set "cmPingRetryTmp="
@if /i "%~1"=="/?" goto usage
@echo %1 | findstr /i "? help usage" >NUL && goto usage
if /i "%~1"=="-v" goto version
if /i "%~1"=="/v" goto version
@echo %1 | findstr /i "version" >NUL && goto version

:paramParse
@echo %1 | findstr "\-I \-U \-P" >NUL && (
    if "%~1"=="-I" (
        if "%~2" NEQ "" set "ipmiInterface=%~2"
        shift
        shift
        goto paramParse
    ) else if "%~1"=="-U" (
        if "%~2" NEQ "" set "bmcUsername=%~2"
        shift
        shift
        goto paramParse
    ) else if "%~1"=="-P" (
        if "%~2" NEQ "" set "bmcPassword=%~2"
        shift
        shift
        goto paramParse
    )
)

if "%bmcUsername%" NEQ "" (set "paraU= -U %bmcUsername%") else set "paraU="
if "%bmcPassword%" NEQ "" (set "paraP= -P %bmcPassword%") else set "paraP="
if "%ipmiInterface%" NEQ "" (set "paraI= -I %ipmiInterface%") else set "paraI="

if "%cmColorEnabled%"=="1" (
    @set "errPre=%redPre%"
    @set "cmSuf=%clrSuf%"
) else (
    set "errPre="
    set "cmSuf="
)
call:hostparse %1 hostpre
if %errorlevel% EQU 670 (
    ipmitool %*
    exit /b
)
if %errorlevel% NEQ 0 exit /b
goto exec

:hostparse
set /a "host=%~1" 2>NUL || goto hostparsestart
if "%host%" NEQ "%~1" exit /b 670
@REM integer without dot.
:hostparsestart
for /f "delims=. tokens=1-3" %%a in ("%defaultHostPrefix%") do (
    if "%%a" NEQ "" set "prea=%%a" else goto hostparsemid
    if "%%b" NEQ "" set "preb=%%b" else goto hostparsemid
    if "%%c" NEQ "" set "prec=%%c" else goto hostparsemid
)
:hostparsemid
for /f "delims=. tokens=1-4,*" %%a in ("%~1") do (
    if "%%a" NEQ "" set "seca=%%a" else goto afterhostparse
    if "%%b" NEQ "" set "secb=%%b" else goto afterhostparse
    if "%%c" NEQ "" set "secc=%%c" else goto afterhostparse
    if "%%d" NEQ "" set "secd=%%d" else goto afterhostparse
    if "%%e" NEQ "" set "sece=%%e" else goto afterhostparse
)
:afterhostparse
if defined sece (
    call:err Error 230 "IP input has more than 4 sections."
    exit /b
)
if defined secd (
    set "%2="
    exit /b 0
)
if defined secc if defined prea (
    set "%2=%prea%."
    exit /b 0
)
if defined secb if defined preb (
    set "%2=%prea%.%preb%."
    exit /b 0
)
if defined seca if defined prec (
    set "%2=%prea%.%preb%.%prec%."
    exit /b 0
)
call:err Error 240 "Parsed IP has less than 4 sections." ^
         "Check either input or variable 'defaultHostPrefix'."
exit /b

:exec
set "hostExec=%hostpre%%~1"
if "%~2"=="" (
    ping %hostExec% -n 2
    exit /b
)
pushd %~dp0
set "customCmd="
set "customFound="
if exist "custom\%~2.txt" for /f "usebackq eol=# delims=" %%i in ("custom\%~2.txt") do (
    if not defined customFound set "customFound=yes"
    ipmitool%paraI%%paraU%%paraP% -H %hostExec% %%~i
)
popd
if defined customFound exit /b
if /i "%~2"=="t" if "%~3"=="" (
    ping -t %hostExec%
    exit /b
)
if /i "%~2"=="-t" if "%~3"=="" (
    ping -t %hostExec%
    exit /b
)
if /i "%~2"=="cm" if "%~3"=="" (
    set "cmVer=0"
    goto connectionMonitor
)
if /i "%~2"=="c" (
    set "cmVer=1"
    if "%~3"=="" goto connectionMonitor
    goto preCmParse
)
if /i "%~2"=="sol" (
    if "%~3"=="" (
        call:SOL %1
        exit /b
    )
    if "%~4"=="" (
        set "solArg=%~3"
        goto solargparse
    )
    goto default
)
if /i "%~2"=="fan" (
    if "%~3"=="" (
        ipmitool%paraI%%paraU%%paraP% -H %hostExec% raw 0x3c 0x2f
        exit /b
    )
    if "%~3"=="0" (
        ipmitool%paraI%%paraU%%paraP% -H %hostExec% raw 0x3c 0x2e 0
        exit /b
    )
    if "%~3"=="auto" (
        ipmitool%paraI%%paraU%%paraP% -H %hostExec% raw 0x3c 0x2e 0
        exit /b
    )
    ipmitool%paraI%%paraU%%paraP% -H %hostExec% raw 0x3c 0x2e 1
    ipmitool%paraI%%paraU%%paraP% -H %hostExec% raw 0x3c 0x2c 0xff %3
    exit /b
)
if /i "%~2"=="bios" (
    ipmitool%paraI%%paraU%%paraP% -H %hostExec% chassis bootdev bios
    exit /b
)
if /i "%~2"=="pxe" (
    set "efi="
    if /i "%~3"=="efi" set "efi=1"
    if /i "%~3"=="uefi" set "efi=1"
    if /i "%~3"=="efiboot" set "efi=1"
    if defined efi (
        ipmitool%paraI%%paraU%%paraP% -H %hostExec% chassis bootdev pxe options=efiboot
    ) else (
        ipmitool%paraI%%paraU%%paraP% -H %hostExec% chassis bootdev pxe
    )
    exit /b
)
if /i "%~2"=="disk" (
    set "efi="
    if /i "%~3"=="efi" set "efi=1"
    if /i "%~3"=="uefi" set "efi=1"
    if /i "%~3"=="efiboot" set "efi=1"
    if defined efi (
        ipmitool%paraI%%paraU%%paraP% -H %hostExec% chassis bootdev disk options=efiboot
    ) else (
        ipmitool%paraI%%paraU%%paraP% -H %hostExec% chassis bootdev disk
    )
    exit /b
)
if /i "%~2"=="cdrom" (
    set "efi="
    if /i "%~3"=="efi" set "efi=1"
    if /i "%~3"=="uefi" set "efi=1"
    if /i "%~3"=="efiboot" set "efi=1"
    if defined efi (
        ipmitool%paraI%%paraU%%paraP% -H %hostExec% chassis bootdev cdrom options=efiboot
    ) else (
        ipmitool%paraI%%paraU%%paraP% -H %hostExec% chassis bootdev cdrom
    )
    exit /b
)
if /i "%~2"=="br" (
    ipmitool%paraI%%paraU%%paraP% -H %hostExec% chassis bootdev bios
    if !errorlevel! NEQ 0 exit /b
    2>NUL ipmitool%paraI%%paraU%%paraP% -H %hostExec% chassis power reset
    if !errorlevel! EQU 0 exit /b
    ipmitool%paraI%%paraU%%paraP% -H %hostExec% chassis power on
    exit /b
)
if /i "%~2"=="loop" (
    if not "%~3"=="" (
        set /a "loopInterval_s_tmp=%~3" 2>nul && (
            if "!loopInterval_s_tmp!" == "%~3" (
                set /a "loopInterval_s=!loopInterval_s_tmp!+1"
                shift
            )
        ) || (
            call:err Fatal 2510 "Invalid interval value: %~3"
            exit /b
        )
        shift
        shift
        set "loopArgs="
        goto loopCmdPre
    ) else (
        call:err Fatal 2560 "No command provided!"
        exit /b
    )
)
if /i "%~2"=="monitor" (
    if not "%~3"=="" (
        set "loopmode=monitor"
        set /a "monitorInterval_s_tmp=%~3" 2>nul && (
            if "!monitorInterval_s_tmp!" == "%~3" (
                set /a "monitorInterval_s=!monitorInterval_s_tmp!+1"
                shift
            )
        ) || (
            call:err Fatal 2720 "Invalid interval value: %~3"
            exit /b
        )
        shift
        shift
        set "loopArgs="
        goto loopCmdPre
    ) else (
        call:err Fatal 2740 "No command provided!"
        exit /b
    )
)
if /i "%~2" == "kvm" if "%~3" == "" (
    if not exist "%jviewerPath%" (
        call:err Fatal 2910 "Could not find JViewer.jar in %jviewerPath%" "Please defined the path ti JViewer.jar in variable 'jviewerPath'."
        exit /b
    )
    start "" "%jviewerPath%" -hostname "%hostExec%" -u "%bmcUsername%" -p "%bmcPassword%" -webport 443
    exit /b
)
goto default

:loopCmdPre
if "%~1"=="" (
    if /I "%loopmode%" == "monitor" (
        set "monLast=%TEMP%\ipmi-mon-last"
        set "monCurr=%TEMP%\ipmi-mon-current"
        if "%monitorShowTimeStamps%" == "1" (
            call:GetTime lpYear lpMon lpDay lpHour lpMin lpSec
            @echo %yellowPre%!lpYear!-!lpMon!-!lpDay! !lpHour!:!lpMin!:!lpSec!%clrSuf%
        )
        1>!monLast! 2>&1 ipmitool%paraI%%paraU%%paraP% -H %hostExec%%loopArgs%
        type !monLast!
        goto monCmd
    )
    goto loopCmd
)
set "loopArgs=%loopArgs% %~1"
shift
goto loopCmdPre

:loopCmd
if "%loopShowTimeStamps%" == "1" (
    call:GetTime lpYear lpMon lpDay lpHour lpMin lpSec
    @echo %yellowPre%!lpYear!-!lpMon!-!lpDay! !lpHour!:!lpMin!:!lpSec!%clrSuf%
)
ipmitool%paraI%%paraU%%paraP% -H %hostExec%%loopArgs%
1>nul 2>&1 ping localhost -n %loopInterval_s% -w 500
goto loopCmd

:monCmd
1>%monCurr% 2>&1 ipmitool%paraI%%paraU%%paraP% -H %hostExec%%loopArgs%
1>NUL 2>&1 fc "%monCurr%" "%monLast%"
if %ERRORLEVEL% EQU 1 (
    if "%monitorShowTimeStamps%" == "1" (
        call:GetTime lpYear lpMon lpDay lpHour lpMin lpSec
        @echo %yellowPre%!lpYear!-!lpMon!-!lpDay! !lpHour!:!lpMin!:!lpSec!%clrSuf%
    )
    type "%monCurr%"
    1>NUL 2>&1 move /Y "%monCurr%" "%monLast%"
) else if %ERRORLEVEL% NEQ 0 @echo ipmi-script: warning %ERRORLEVEL%
>nul 2>&1 ping localhost -n %monitorInterval_s% -w 500
goto monCmd

:preCmParse
if /i "%~3"=="" goto postCmParse
if /i "%~3"=="-L" (
    if "%~4"=="" goto postCmParse
    set "cmLogLvlTmp=%~4"
    shift /3
    shift /3
    goto preCmParse
)
if /i "%~3"=="-P" (
    if "%~4"=="" goto postCmParse
    set "cmPingRetryTmp=%~4"
    shift /3
    shift /3
    goto preCmParse
)
if /i "%~3"=="-E" (
    if "%~4"=="" goto postCmParse
    set "cmEwsRetryTmp=%~4"
    shift /3
    shift /3
    goto preCmParse
)
call:err Warning 760 "Unsupported CM parameter(s) met!"
:postCmParse
set /a "cmLogLvlTmpPost=cmLogLvlTmp"
set /a "cmPingRetryTmpPost=cmPingRetryTmp"
set /a "cmEwsRetryTmpPost=cmEwsRetryTmp"
if "%cmLogLvlTmp%" NEQ "" if "%cmLogLvlTmpPost%"=="%cmLogLvlTmp%" (
    set /a "cmLogLvl=cmLogLvlTmpPost"
) else (
    call:err Warning 800 "Parameter 'log level' was designated but did not applied."
)
if "%cmPingRetryTmp%" NEQ "" if "%cmPingRetryTmpPost%"=="%cmPingRetryTmp%" (
    set /a "cmPingRetry=cmPingRetryTmpPost"
) else (
    call:err Warning 840 "Parameter 'ping retry' was designated but did not applied."
)
if "%cmEwsRetryTmp%" NEQ "" if "%cmEwsRetryTmpPost%"=="%cmEwsRetryTmp%" (
    set /a "cmEwsRetry=cmEwsRetryTmpPost"
) else (
    call:err Warning 840 "Parameter 'EWS retry' was designated but did not applied."
)
goto connectionMonitor

:solargparse
if "%solArg:~-4%"==".log" (
    call:SOL %1 %3
    exit /b
)
if "%solArg:~-4%"==".txt" (
    call:SOL %1 %3
    exit /b
)

:default
set "all_args=%hostpre%%~1"
shift
:set_all_arg
set "all_args=%all_args% %~1"
shift
if "%~1" NEQ "" goto set_all_arg
ipmitool%paraI%%paraU%%paraP% -H %all_args%
exit /b

:usage
set "usageTempFile=%TEMP%\ipmi-usage.tmp"
@echo Loading help ...
@>"%usageTempFile%" (
echo;
echo IPMI script %_ver%
echo https://lxvs.net/ipmi
echo;
echo;
echo Run INSTALL.bat before first use.
echo;
echo Usage:
echo;
echo ipmi ^<IP^> ^<arg1^> [^<arg2^> [...]]
echo     Send IPMI commands
echo;
echo ipmi ^<IP^> loop ^<arg1^> [^<arg2^> [...]]
echo     Send IPMI commands repeatedly with an interval of about 1 second.
echo;
echo ipmi ^<IP^> monitor ^<arg1^> [^<arg2^> [...]]
echo     Similar to LOOP, but only shows update instead of every output.
echo;
echo ipmi version ^| -v ^| /v
echo     Get current and latest version
echo;
echo ipmi [? ^| help ^| usage]
echo     Get help on this script
echo;
echo ipmi -h
echo     Get help of ipmitool
echo;
call:LFN *IP* fn
echo ipmi ^<IP^> SOL
echo     Collect SOL log to !fn!
echo;
echo ipmi ^<IP^> SOL [^<FN^>.log ^| ^<FN^>.txt]
echo     Collect SOL log to ^<FileName^>
echo;
echo ipmi ^<IP^> [t]
echo     Ping
echo;
echo ipmi ^<IP^> BIOS
echo     Force to enter BIOS setup on next boot only
echo;
echo ipmi ^<IP^> PXE [efi]
echo     Force PXE boot for next one only
echo     If 'efi' is specified, append options=efiboot
echo;
echo ipmi ^<IP^> disk [efi]
echo     Force to boot from disk for next boot only
echo     If 'efi' is specified, append options=efiboot
echo;
echo ipmi ^<IP^> cdrom [efi]
echo     Force to boot from cdrom for next boot only
echo     If 'efi' is specified, append options=efiboot
echo;
echo ipmi ^<IP^> BR
echo     Force to enter BIOS setup on next boot and reset immediately
echo;
echo ipmi ^<IP^> CM
echo     Connection monitor legacy
echo;
echo ipmi ^<IP^> C [-L ^<L^>] [-P ^<P^>] [-E ^<E^>]
echo     Connection monitor upgraded: also monitors if bmc web is ready.
echo;
echo     ^<L^> for Log level:
echo         0: Do not write any log.
echo         1: Log only what shows in console.
echo         2: ^(default^) Also log retries before anouncing a bad
echo            connection, and http code changes.
echo         3: Also log every ping and http code result.
echo;
echo     ^<P^> for Ping retry:  ^(default: 3^)
echo         Trying times before anouncing a ping failure.
echo;
echo     ^<E^> for EWS retry:  ^(default: 2^)
echo         Trying times before anouncing a BMC web down.
echo;
echo ipmi ^<IP^> fan
echo     ^(Need Porting^) Request current fan mode.
echo         00: auto, 01: manual
echo;
echo ipmi ^<IP^> fan 0^|auto
echo     ^(Need Porting^) Set fan mode to auto
echo;
echo ipmi ^<IP^> fan ^<speed^>
echo     ^(Need Porting^) Set fan speed ^(%%^)
echo         1~100
echo;
echo ipmi [arg1 [arg2 [...]]]
echo     Get ipmitool help on specific parameter^(s^)
echo;
echo ^<IP^> can be 1~4 segment^(s^), but the number of segments of ^<IP^>
echo and ^<defaultHostPrefix^> ^(set in the first lines of ipmi.bat^) must
echo add up to great or equal than 4.
echo;
echo    ^<IP^>   ^<dHPrefix^>  OK?  Actual-IP
echo        7  192.168.0   Yes  192.168.0.7
echo      7.7  192.168.0   Yes  192.168.7.7
echo  7.7.7.7  192.168.0   Yes  7.7.7.7
echo        7  192         No   -
echo;
echo BMC username/password can also be set there. Default: admin/admin.
echo;
echo Example:
echo;
echo If defaultHostPrefix was set to '100.2.76.', then
echo;
echo ipmi 255 arg1 arg2 arg3
echo     stands for:
echo;
echo ipmitool%paraI%%paraU%%paraP% -H 100.2.76.255 arg1 arg2 arg3
echo;
echo;
echo Custom commands
echo;
echo     Write ipmi command to custom\^<command^>.txt, one command per line.
echo     Lines starting with # will be treated as comments.
echo
echo     Custom commands have higher priorities, and can only contain
echo     original ipmitool commands ^(i.e. cannot contain commands provided
echo     by this script or other custom commands^).
echo;
echo Example:
echo;
echo     write 'raw 0x0 0x9 0x5 0x0 0x0' ^(without quotes^) to file
echo     custom\getbootorder.txt, and then you can use command:
echo        ipmi ^<IP^> getbootorder
echo     as a shortcut to command:
echo        ipmi ^<IP^> raw 0x0 0x9 0x5 0x0 0x0
echo;
echo;
echo;
echo;
)
more /e "%usageTempFile%"
del "%usageTempFile%"
exit /b

:LFN
call:GetTime lfnYear lfnMon lfnDay lfnHour lfnMin
set "lfnWf=%solWorkFolder%\%lfnYear%-%lfnMon%-%lfnDay%"
if "%~3"=="1" if not exist "%lfnWf%" md "%lfnWf%"
set "%2=%lfnWf%\%1-%lfnHour%.%lfnMin%.log"
exit /b

:SOL
@title %hostexec% SOL
set "solLfn="
if "%~2" NEQ "" set "solLfn=%precd%\%~2"
if not defined solLfn goto sol_continue
if not exist "%solLfn%" goto sol_continue
set "solow="
set /p "solow=%solLfn% exists, overwrite it? (Y/n): "
if /i "%solow%" == "y" (
    del /f "%solLfn%" || (
        call:err Fatal 4880 "SOL: Failed to delete file %solLfn%"
        exit /b
    )
) else (
    call:err Fatal 4920 "SOL: User aborted."
    exit /b
)
:sol_continue
@echo ^> Deactivating previous SOL...
2>NUL ipmitool%paraI%%paraU%%paraP% -H %hostExec% sol deactivate
if not defined solLfn (call:LFN %hostExec% solLfn 1)
@type nul>"%solLfn%" || (
    call:err Fatal 510 "SOL: Cannot create log file" "please consider to change a directory or run as administrator."
    exit /b
)
@echo ^> Activated SOL, saving to %SolLfn%
explorer /select,"%solLfn%"
if exist tee.exe (
    ipmitool%paraI%%paraU%%paraP% -H %hostExec% sol activate 2>&1 | tee.exe "%solLfn%"
) else (
    1>"%solLfn%" 2>&1 ipmitool%paraI%%paraU%%paraP% -H %hostExec% sol activate
)
if %errorlevel% NEQ 0 (
    call:err fatal 4190 "SOL: failed to activate SOL" "See %SolLfn% for details"
    exit /b
)
exit /b

:err
>&2 echo %errPre%^> %~1^(%~2^): %~3%clrSuf%
:errshift
shift /3
if "%~3" NEQ "" (
    >&2 echo %errPre%-^> %~3%clrSuf%
    goto errshift
)
exit /b %2

:connectionMonitor
@title %hostExec%
if not exist "%cmWorkFolder%" md "%cmWorkFolder%"
set "cmCurrentStatus="
set "cmEwsStatus="
set "cmLastHttpCode="
set "cmEwsOrgG=BMC web is accessible."
set "cmEwsOrgB=BMC web is not ready."
set "cmEwsTrnG=BMC web is accessible."
set "cmEwsTrnB=BMC web is down."
set "cmPingB=Ping got no response."
set "cmPingOrgG=Ping is OK."
set "cmPingTrnG=Ping is OK."
call:write "------------------------------------------------------" 0 0
call:write "Host:          %hostExec%" 0 0
call:write "Version:       %_ver%" 0 0
call:write "Ping retry:    %cmPingRetry%" 0 0
call:write "Ping timeout:  %cmPingTimeout_ms% ms" 0 0
if "%cmVer%"=="1" (
    call:write "EWS retry:     %cmEwsRetry%" 0 0
    call:write "EWS timeout:   %cmEwsTimeout_s% s" 0 0
    call:write "Log level:     %cmLogLvl%" 0 0
    if %cmLogLvl% GTR 0 call:write "Log folder:    %cmWorkFolder%" 0 0
) else call:write "Log folder:    %cmWorkFolder%" 0 0
call:write "------------------------------------------------------" 0 0

:loop
ping %hostExec% -n 1 -w %cmPingTimeout_ms% 1>NUL 2>&1
if %ErrorLevel% EQU 0 (
    call:write "ping: OK." 2
    if not defined cmCurrentStatus (
        set "cmCurrentStatus=g"
        if "%cmver%"=="1" call:write "DEBUG: calling GHC because status is not defined." 8
        if "%cmver%"=="1" (call:gethttpcode) else call:write "%cmPingOrgG%" g
        1>nul 2>&1 ping localhost -n 2 -w 500
        goto loop
    )
    if /i "%cmCurrentStatus%"=="b" (
        set "cmCurrentStatus=g"
        if "%cmver%"=="1" call:write "DEBUG: calling GHC because status turns good." 8
        if "%cmver%"=="1" (call:gethttpcode) else call:write "%cmPingTrnG%" g
        1>nul 2>&1 ping localhost -n 2 -w 500
        goto loop
    )
    if /i "%cmCurrentStatus:~0,1%"=="b" (
        set "cmCurrentStatus=g"
        call:write "Just jitters, ignored." 1
        if "%cmver%"=="1" call:write "DEBUG: calling GHC because of jitters." 8
        if "%cmver%"=="1" call:gethttpcode
        1>nul 2>&1 ping localhost -n 2 -w 500
        goto loop
    )
    if "%cmver%"=="1" call:write "DEBUG: calling GHC mandatorily." 8
    if "%cmver%"=="1" call:gethttpcode
    1>nul 2>&1 ping localhost -n 2 -w 500
    goto loop
)
call:write "ping: failed!" 2
if not defined cmCurrentStatus goto writebad
if /i "%cmCurrentStatus%"=="b" goto loop
if /i "%cmCurrentStatus:~0,1%"=="b" goto PingTrans
if %cmPingRetry% GTR 0 (
    set "cmCurrentStatus=b0"
    call:write "Ping failed, retrying." 1
    goto loop
) else goto writebad

:gethttpcode
for /f %%i in ('curl -m %cmEwsTimeout_s% -so /dev/null -Iw %%{http_code} %hostExec%') do (
    call:write "DEBUG: HTTP code updated:   %cmLastHttpCode% to %%i" 8
    call:write "DEBUG: BMC web status:      %cmEwsStatus%" 8
    call:write "HTTP code: %%i" 2
    if "%%i" NEQ "%cmLastHttpCode%" (
        set "cmLastHttpCode=%%i"
        call:write "HTTP code updated: %%i" 1
    )
    if "%%i"=="000" (
        if "%cmEwsStatus%"=="" (
            call:write "%cmEwsOrgB%" y
            set "cmEwsStatus=b"
        ) else if /i "%cmEwsStatus%" NEQ "b" (
            if /i "%cmEwsStatus:~0,1%"=="b" (
                call:EwsTrans
                exit /b
            )
            if %cmEwsRetry% GTR 0 (
                set "cmEwsStatus=b0"
                call:write "EWS seems down, retrying." 1
                exit /b
            ) else (
                call:write "%cmEwsTrnB%" y
                set "cmEwsStatus=b"
            )
        )
    ) else (
        if "%cmEwsStatus%"=="" (
            call:write "%cmEwsOrgG%" g
        ) else if /i "%cmEwsStatus%"=="b" (
            call:write "%cmEwsTrnG%" g
        )
        set "cmEwsStatus=g"
    )
)
exit /b

:PingTrans
set /a "cmPingRetried=%cmCurrentStatus:~-1%"
set /a "cmPingRetried+=1"
set "cmCurrentStatus=b%cmPingRetried%"
if /i "%cmEwsStatus%"=="b" set /a "cmPingRetried=cmPingRetry"
call:write "Ping failed, retried = %cmPingRetried%." 1
if %cmPingRetried% GEQ %cmPingRetry% (
    set "cmPingRetried="
    goto writebad
)
goto loop

:writebad
set "cmCurrentStatus=b"
set "cmEwsStatus="
set "cmLastHttpCode="
call:write "%cmPingB%" r
goto loop

:EwsTrans
set /a "cmEwsRetried=%cmEwsStatus:~-1%"
set /a "cmEwsRetried+=1"
set "cmEwsStatus=b%cmEwsRetried%"
call:write "EWS seems down, retried = %cmEwsRetried%." 1
if %cmEwsRetried% GEQ %cmEwsRetry% (
    set "cmEwsRetried="
    call:write "%cmEwsTrnB%" y
    set "cmEwsStatus=b"
)
exit /b

:write
@REM %1: message
@REM %2: color (0/Red/Green/Yellow/Blue/Magenta/Cyan)
@REM     -OR- MsgLvl (0-9)
@REM %3: iftimestamp (0/1) default 1
set "cmClr=%~2"
set "cmIfts=%~3"
if "%cmIfts%" == "" set "cmIfts=1"
set /a "cmMsgLvl=cmClr"
set "cmPre="
set "cmSuf="
if %cmColorEnabled% NEQ 1 goto cmgo
if "%cmClr%"=="" goto cmgo
if "%cmClr%"=="%cmMsgLvl%" goto cmgo
if /i "%cmClr%"=="r" (
    @set "cmPre=%redPre%"
    goto cmgo
)
if /i "%cmClr%"=="g" (
    @set "cmPre=%greenPre%"
    goto cmgo
)
if /i "%cmClr%"=="y" (
    @set "cmPre=%yellowPre%"
    goto cmgo
)
if /i "%cmClr%"=="b" (
    @set "cmPre=%bluePre%"
    goto cmgo
)
if /i "%cmClr%"=="m" (
    @set "cmPre=%magentaPre%"
    goto cmgo
)
if /i "%cmClr%"=="c" (
    @set "cmPre=%cyanPre%"
    goto cmgo
)
:cmgo
@if not "%cmPre%" == "" set "cmSuf=%clrSuf%"
if %cmMsgLvl% NEQ 0 if %cmMsgLvl% GEQ %cmLogLvl% exit /b 0
if "%cmIfts%" == "1" call:GetTime cmYear cmMon cmDay cmHour cmMin cmSec
if "%cmIfts%" == "1" (
    set "cmTimeStamp=%cmyear%-%cmmon%-%cmday% %cmhour%:%cmmin%:%cmsec%"
) else set "cmTimeStamp="
set "cmLogMsg=%~1"
if %cmMsgLvl% EQU 0 @echo %cmpre%%cmTimeStamp% %cmLogMsg%%cmsuf%
if %cmMsgLvl% GEQ %cmLogLvl% exit /b 0
if not exist "%cmWorkFolder%" md "%cmWorkFolder%"
if %cmMsgLvl% EQU 0 >>"%cmWorkFolder%\%hostExec%.log" echo %cmTimeStamp% %cmLogMsg%
if %cmLogLvl% LEQ 1 exit /b 0
if %cmMsgLvl% LSS %cmLogLvl% >>"%cmWorkFolder%\%hostExec%.verbose.log" echo %cmTimeStamp% %cmLogMsg%
exit /b 0

:GetTime
for /f "tokens=1-6 usebackq delims=_" %%a in (`powershell -command "&{Get-Date -format 'yyyy_MM_dd_HH_mm_ss'}"`) do (
    if "%1" NEQ "" set "%1=%%a" else exit /b
    if "%2" NEQ "" set "%2=%%b" else exit /b
    if "%3" NEQ "" set "%3=%%c" else exit /b
    if "%4" NEQ "" set "%4=%%d" else exit /b
    if "%5" NEQ "" set "%5=%%e" else exit /b
    if "%6" NEQ "" set "%6=%%f" else exit /b
)
exit /b

:version
@echo;
@echo version: %_ver%
set /p=latest:  <NUL
curl -m 5 "https://raw.githubusercontent.com/lxvs/ipmi/main/VERSION" 2>NUL || echo Timed out getting latest version. Please try again later.
exit /b
