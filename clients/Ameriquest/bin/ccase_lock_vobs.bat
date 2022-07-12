@echo off

set view_server=rtnlprod02
set view_share=viewstore
set view=PMO
set vob=CM_TOOLS
set bin_path=\\%view_server%\%view_share%\%view%\%vob%\bin

"%CLEARCASEHOME%\bin\ccperl.exe" "%bin_path%\lockvobs.pl"
