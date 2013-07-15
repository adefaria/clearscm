################################################################################
#
# File:         $RCSfile: Makefile,v $
# Revision:     $Revision: 1.8 $
# Description:  Makefile for Clearscm
# Author:       Andrew@Clearscm.com
# Created:      Mon Nov 13 16:14:30 1995
# Modified:     $Date: 2012/09/20 06:52:37 $
# Language:     Makefile
#
# (c) Copyright 2010, ClearSCM, Inc., all rights reserved.
#
################################################################################
CLEARLIB                = etc/mail.conf\
                          lib/CmdLine.pm\
                          lib/BinMerge.pm\
                          lib/DateUtils.pm\
                          lib/Display.pm\
                          lib/GetConfig.pm\
                          lib/Logger.pm\
                          lib/Machines.pm\
                          lib/Mail.pm\
                          lib/OSDep.pm\
                          lib/Rexec.pm\
                          lib/TimeUtils.pm\
                          lib/Utils.pm
CLEARCC                 = lib/Clearcase.pm\
                          lib/Clearcase
CLEARCQ                 = etc/cq.conf\
                          lib/Clearquest.pm\
                          lib/Clearquest
CLEARADM                = clearadm
CLEARENV                = rc
CLEARAGENT              = lib/Display.pm\
                          lib/OSDep.pm\
                          lib/DateUtils.pm\
                          lib/GetConfig.pm\
                          lib/Utils.pm\
                          clearadm/lib/Clearexec.pm\
                          clearadm/clearagent.pl\
                          clearadm/clearexec.pl\
                          clearadm/etc/clearexec.conf\
                          clearadm/etc/conf.d/clearadm\
                          clearadm/etc/init.d/clearagent\
                          clearadm/etc/init.d/cleartasks\
                          clearadm/load.vbs\
                          clearadm/log\
                          clearadm/setup.pl\
                          clearadm/var
TARGETS	                = clearlib.tar.gz\
                          clearcc.tar.gz\
                          clearcq.tar.gz\
                          clearadm.tar.gz\
                          clearenv.tar.gz\
                          clearagent.tar.gz

all:			$(TARGETS)

clean:
			@rm -f $(TARGETS)

clearlib.tar.gz:        $(CLEARLIB)
			@tar --exclude CVS -zcf $@ $(CLEARLIB)

clearcc.tar.gz:         $(CLEARCC)
			@tar --exclude CVS -zcf $@ $(CLEARCC)

clearcq.tar.gz:         $(CLEARCQ)
			@tar --exclude CVS -zcf $@ $(CLEARCQ)

clearadm.tar.gz:        $(CLEARADM)
			@tar --exclude CVS -zcf $@ $(CLEARADM)

clearenv.tar.gz:        $(CLEARENV)
			@tar --exclude CVS -zcf $@ $(CLEARENV)

clearagent.tar.gz:      $(CLEARAGENT)
			@tar --exclude CVS -zcf $@ $(CLEARAGENT)
