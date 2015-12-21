################################################################################
#
# File:         Makefile
# Revision:     $Revision: 1 $
# Description:  Makefile for Devops/Web/rmc
# Author:       Andrew@Clearscm.com
# Created:      Mon, Jun 01, 2015 12:19:02 PM
# Modified:     $Date: 2012/09/20 06:52:37 $
# Language:     Makefile
#
# (c) Copyright 2015, Audience, Inc., all rights reserved.
#
# Aside from the standard make targets, the following additional targets exist:
#
# setup:        Set up rmc web app
#
################################################################################
include ../../make.inc

WEBAPPS		:= rmc
HTTPCONF	:= /etc/httpd/conf.d
SERVER		:= $(shell hostname -s)
PORT            := 8000
TEMPFILE        := $(shell mktemp --tmpdir $(TMP) -u rmc.conf.XXXX)

define helpText
Aside from the standard make targets, the following additional targets exist:\n\\n\
install:      Set up rmc web app\n\
uninstall:    Remove rmc web app\n
endef

all:
	install

help:
	@echo -e "$(helpText)"

test:
	@read -p "Enter SERVER:" SERVER;\
	echo "SERVER = $$SERVER";\
	exit 1;

install:
	@read -p "Enter server name for this instance (Default: $(SERVER)):" SERVER; \
	read -p "Enter port number for this instance (Default: $(PORT)):" PORT; \
	$(SUDO) $(RMF) $(HTTPCONF)/rmc.conf; \
	$(SED) "s/<SERVER>/$$SERVER/" rmc.conf > $(TEMPFILE); \
	$(SED) "s/<PORT>/$$PORT/" $(TEMPFILE) > /tmp/rmc.conf; \
	$(SUDO) $(RMF) $(TEMPFILE); \
	$(SUDO) chown root.root /tmp/rmc.conf; \
	$(SUDO) $(MV) /tmp/rmc.conf $(HTTPCONF)/rmc.conf; \
	$(SUDO) $(SERVICE) httpd reload

uninstall:
	$(SUDO) $(RMF) $(HTTPCONF)/rmc.conf
	$(SUDO) $(SERVICE) httpd reload
