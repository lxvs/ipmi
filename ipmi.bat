@echo off
rem > IPMI script by Johnny Appleseed <lllxvs@gmail.com>
rem > Updated on 20201111
rem > Usage:
rem >   Put it together with ipmitool.
rem >   In CMD, execute 
rem >      ipmi 255 arg1 arg2 arg3
rem >   which stands for
rem >      ipmitool -I lanplus -U admin -P admin -H 100.2.76.255 arg1 arg2 arg3
if "%1" EQU "" (goto:eof)
if "%2" EQU "" (goto:eof)
@echo on
ipmitool -I lanplus -U admin -P admin -H 100.2.76.%*
