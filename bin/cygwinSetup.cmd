@echo off

rem This script sets up Cygwin
rem We assume that setup.exe is in the path and that it is the appropriate
rem Cygwin setup

rem set packages=openssh
set packages=base-cygwin,base-files,bash,bin-utils,bzip2,coreutils,cron,
curl,cygrunsrv,cygwin,dateutils,diffutils,dos2unix,expect,file,gcc-core,gcc-g++,git,
grep,hostname,inetutils,less,make,man,man-pages-posix,
mintty,openssh,openssl,perl,python,rsync,tar,time,wget,which,xload,xterm,
xorg-server,xorg-server-common,xorg-x11-fonts-dpi75
set options=-q -l C:\CygwinPkgs -R C:\Cygwin -s http://mirrors.kernel.org 

mkdir C:\CygwinPkgs

echo setup %options% -P %packages%
setup %options% -P %packages%

if errorlevel 1 ssh-host-config -y