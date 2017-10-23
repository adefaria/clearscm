#!/bin/perl
################################################################################
#
# File:		cqc: Clearquest client
# Description:  ClearQuest Client will query the ClearQuest Daemon for
#		information.
# Author:       Andrew@DeFaria.com
# Created:      Fri May 31 15:34:50  2002
# Modified:
# Language:     Perl
#
# (c) Copyright 2002, Salira Optical Network Systems, all rights reserved.
#
################################################################################
use IO::Socket;

package cqc;
  require (Exporter);
  @ISA = qw (Exporter);

  @EXPORT = qw (Connect, GetBugRecord, Disconnect %fields $command $verbose);

  my $host;
  my $port = 1500;
  my $command;
  my $default_server = "sons-clearcase";
  my $verbose;

  BEGIN {
    my $cqcversion = "1.0";

    # Reopen STDOUT. This is because cqperl screws around with STDOUT in some
    # weird fashion
    open STDOUT, ">-" or die "Unable to reopen STDOUT\n";
    # Set unbuffered output for the same reason (cqperl)
    $| = 1;
  } # BEGIN

  sub verbose {
    print "@_\n" if defined ($verbose);
  } # verbose

  sub Connect {
    my $host = shift;

    my $result;

    if (!defined ($host)) {
      $host = "localhost";
    } # if

    $cqserver = ConnectToServer ($host);

    if ($cqserver) {
      verbose "Connected to $host";
      SendServerAck ($cqserver);
    } # if

    return $cqserver;
  } # Connect

  sub Disconnect {
    my $msg;
    if ($cqserver) {
      if ($cqc::command eq "shutdown") {
	$msg = "Disconnected from server - shutdown server";
      } else {
	$cqc::command = "quit";
	$msg          = "Disconnected from server";
      } # if
      SendServerCmd ($cqserver, $cqc::command);
      GetServerAck  ($cqserver);
      verbose "$msg";
      close ($cqserver);
      undef $cqserver;
    } # if
  } # Disconnect

  sub GetBugRecord {
    my $bugid  = shift;
    %fields = @_;

    my $result;

    if (!$cqserver) { 
      verbose "Not connected to server yet!\n";
      verbose "Attempting connection to $default_server...\n";
      $result = Connect ($default_server);
      return -1 if !defined ($result);
    } # if

    SendServerCmd               ($cqserver, $bugid);
    GetServerAck                ($cqserver);
    $result = GetServerResponse ($cqserver, %fields);
    SendServerAck               ($cqserver);

    return $result;
  } # GetBugRecord

  END {
    Disconnect;
  } # END

  sub ConnectToServer {
    my $host = shift;

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

  sub GetServerResponse {
    my $server = shift;
    %fields    = @_;

    %fields = ();
    my $srvresp;
    my $result = 0;

    while (defined ($srvresp = <$server>)) {
      chomp $srvresp;
      last if $srvresp eq "ACK";
      if ($srvresp =~ m/Bug ID.*was not found/) {
	$result = 1;
      } else {
	$srvresp =~ /(^\w+):\s+(.*)/s;
	$fields {$1} = $2;
      } # if
    } # while

    return $result;
  } # GetServerResponse

  sub SendServerCmd {
    my $server  = shift;
    my $command = shift;

    print $server "$command\n";
  } # SendServerCmd

1;
