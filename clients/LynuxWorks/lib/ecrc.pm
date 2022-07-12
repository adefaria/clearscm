#!/usr/bin/perl
################################################################################
#
# File:		ecrd.pm: ECR Daemon Client Library
# Description:  Perl Module interface to ecrd (ECR Daemon). This is used
#		by ecrc and cgi scripts to talk to ECR Daemon
# Author:       Andrew@DeFaria.com
# Created:      Tue Feb 15 09:40:57 PST 2005
# Modified:
# Language:     Perl
#
# (c) Copyright 2005, LynuxWorks, all rights reserved.
#
################################################################################
use strict;
use warnings;

use IO::Socket;

package ecrc;
  require Exporter;
  @main::ISA = qw (Exporter);

  @main::EXPORT = qw (Connect GetECRRecord Disconnect);

  my $default_server	= (!defined $ENV {ECRDSERVER}) ? "lynx12" : $ENV {ECRDSERVER};
  my $default_port	= (!defined $ENV {ECRDPORT})   ? 1500     : $ENV {ECRDPORT};
  my $verbose		= 0;
  my $debug		= 0;
  my $command;
  my $ecrserver;

  # Forwards
  sub ConnectToServer;
  sub GetServerAck;
  sub GetServerList;
  sub GetServerResponse;
  sub SendServerAck;
  sub SendServerCmd;

  BEGIN {
    my $ecrcversion = "1.1";

    # Reopen STDOUT to make sure it's clear
    open STDOUT, ">-" or die "Unable to reopen STDOUT\n";

    # Set unbuffered output
    $| = 1;
  } # BEGIN

  sub set_verbose {
    $verbose = 1;
  } # set_verbose

  sub set_debug {
    $debug = 1;
  } # set_debug

  sub verbose {
    print "@_\n" if $verbose;
  } # verbose

  sub debug {
    print "DEBUG: @_\n" if $debug;
  } # debug

  sub Connect {
    my $host = shift;
    my $port = shift;

    my $result;

    $host = $default_server if !defined $host;
    $port = $default_port   if !defined $port;

    $ecrserver = ConnectToServer $host, $port;

    if ($ecrserver) {
      verbose "Connected to $host";
      SendServerAck $ecrserver;
    } # if

    return $ecrserver;
  } # Connect

  sub Disconnect {
    my $msg;

    if ($ecrserver) {
      if ($command eq "shutdown") {
	$msg = "Disconnected from server - shutdown server";
      } else {
	$command = "quit";
	$msg     = "Disconnected from server";
      } # if
      SendServerCmd $ecrserver, $command;
      GetServerAck  $ecrserver;
      verbose "$msg";
      close $ecrserver;
      undef $ecrserver;
    } # if
  } # Disconnect

  sub GetECRRecord {
    my $ecr = shift;

    my %fields;
    my @ecrs;

    if (!$ecrserver) {
      verbose "Not connected to server yet!";
      verbose "Attempting connection to $default_server...";
      if (!Connect $default_server, $default_port) {
	print "Unable to connect to server $default_server\n";
	exit 1;
      } # if
    } # if

    SendServerCmd $ecrserver, $ecr;
    GetServerAck  $ecrserver;

    if ($ecr eq "\*") {
      @ecrs = GetServerList $ecrserver;
    } else {
      %fields = GetServerResponse $ecrserver;
    } # if

   SendServerAck $ecrserver;

    return $ecr eq "\*" ? @ecrs : %fields;
  } # GetECRRecord

  END {
    verbose "Sending disconnect command to server";
    $command = "quit";
    Disconnect;
  } # END

  sub ConnectToServer {
    my $host = shift;
    my $port = shift;

    # create a tcp connection to the specified host and port
    return IO::Socket::INET->new(Proto     => "tcp",
				 PeerAddr  => $host,
				 PeerPort  => $port);
  } # ConnectToServer

  sub SendServerAck {
    my $server = shift;

    print $server "ACK\n";
  } # SendServerAck

  sub GetServerAck {
    my $server = shift;
    my $srvresp;

    while (defined ($srvresp = <$server>)) {
      chomp $srvresp;
      if ($srvresp eq "ACK") {
	return;
      } # if
      print "Received $srvresp from server - expected ACK\n";
    } # while
  } # GetServerAck

  sub GetServerList {
    my $server = shift;

    my @ecrs;
    my $srvresp;

    while (defined ($srvresp = <$server>)) {
      chomp $srvresp;
      last if $srvresp eq "ACK";
      if ($srvresp =~ m/ECR.*was not found/) {
	return ();
      } else {
	push @ecrs, $srvresp;
      } # if
    } # while

    return @ecrs;
  } # GetServerList

  sub GetServerResponse {
    my $server = shift;

    my %fields;
    my $srvresp;

    while (defined ($srvresp = <$server>)) {
      chomp $srvresp;
      last if $srvresp eq "ACK";
      if ($srvresp =~ m/ECR.*was not found/) {
	return ();
      } else {
	$srvresp =~ /(^\w+):\s+(.*)/s;
        my $value = $2;
	if (defined $value) {
	  $value =~ s/\\n/\n/g;
	} else {
	  $value = "";
	} # if
	$fields {$1} = $value;
      } # if
    } # while

    return %fields;
  } # GetServerResponse

  sub SendServerCmd {
    my $server  = shift;
    my $command = shift;

    print $server "$command\n";
  } # SendServerCmd

1;
