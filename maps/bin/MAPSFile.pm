#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: MAPSFile.pm,v $
# Revision:	$Revision: 1.1 $
# Description:  File manipulation routines for MAPS.
# Author:       Andrew@DeFaria.com
# Created:      Fri Nov 29 14:17:21  2002
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     perl
#
# (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
package MAPSFile;

use strict;
use vars qw (@ISA @EXPORT);

use Fcntl ':flock'; # import LOCK_* constants

use Exporter;
@ISA = qw (Exporter);

@EXPORT = qw (
  Lock
  Unlock
);

sub Lock {
  my $file = shift;

  flock ($file, LOCK_EX);
  # and, in case someone appended while we were waiting...
  seek ($file, 0, 2);
} # lock

sub Unlock {
  my $file = shift;
  flock ($file,LOCK_UN);
} # unlock

1;
