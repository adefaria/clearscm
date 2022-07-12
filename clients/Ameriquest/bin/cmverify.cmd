@echo off
rem -------------------------------------------------------------------------
rem -
rem - File:             verify.cmd
rem - Description:      This command verifies the installation of Rational
rem -			tools.
rem - Author:           Andrew@DeFaria.com
rem - Created:          Mon Mar 28 14:52:00 PST 2004
rem - Language:         Dumb CMD stuff! :-(
rem - Parameters:	There is only one parameter that is taken and that is
rem -			the number of seconds that cqverify should wait 
rem -			before starting. This is only needed if this cmvery
rem -			command is run from the various install scripts.
rem -
rem -------------------------------------------------------------------------
set ccperl=C:\Program Files\Rational\Clearcase\bin\ccperl.exe
set cqperl=C:\Program Files\Rational\Common\cqperl.exe
set ccverify=\\rtnlprod02\viewstore\PMO\CM_TOOLS\bin\ccverify.pl
set cqverify=\\rtnlprod02\viewstore\PMO\CM_TOOLS\bin\cqverify.pl
set wait=\\rtnlprod02\viewstore\PMO\CM_TOOLS\bin\wait.pl
set logfile=\\rtnlprod02\viewstore\PMO\CM_TOOLS\log\%COMPUTERNAME%.log

rem Clear out logfile
if exist %logfile% del /q /f %logfile%

rem Check for necessary tools
set msg=
if not exist "%ccperl%"   set msg=Clearcase is not installed
if not exist "%ccverify%" set msg=Unable to find ccverify script (%ccverify%)!

if not "%msg%" == "" goto Error

rem Since we found ccperl assume that the installation was done so now
rem we'll check the configuration
"%ccperl%" %ccverify%

rem Wait for Clearquest/TUP install to finish
if not "%1" == "" echo Waitng for Clearquest/TUP installation to finish&& "%ccperl%" %wait% %1

rem Now check cq
if not exist "%cqperl%"   set msg=Clearquest/TUP is not installed
if not exist "%cqverify%" set msg=Unable to find cqverify script (%cqverify%)!

if not "%msg%" == "" goto Error

"%cqperl%" %cqverify%
goto EXIT

:Error
echo %msg%
echo %msg% >> %logfile%

:EXIT