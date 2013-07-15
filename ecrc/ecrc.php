<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:        ecrc.php: ECR Daemon Client Library
// Description: Php Module interface to ecrd (ECR Daemon).
// Author:      Andrew@DeFaria.com
// Created:     Tue Feb 15 09:40:57 PST 2005
// Modified:
// Language:    Php
//
// (c) Copyright 2005, LynuxWorks, all rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
require_once "Net/Socket.php";

define ("SERVER", "lynx12");
define ("PORT", 1500);

$ecrserver;
$verbose  = $_REQUEST [verbose];
$debug    = $_REQUEST [debug];

function verbose ($msg) {
  global $verbose;

  if ($verbose == 1) {
    print "$msg&lt;br&gt;";
  } // if 
} // verbose

function debug ($msg) {
  global $debug;

  if ($debug == 1) {
    print "DEBUG: $msg&lt;br&gt;";
  } // if 
} // debug

function Connect ($host, $port = 1500) {
  global $ecrserver;

  debug ("Connect ($host, $port)");

  $ecrserver = ConnectToServer ($host, $port);

  if (is_object ($ecrserver)) {
    verbose ("Connected to $host");
    SendServerAck ($ecrserver);
  } // if

  return $ecrserver;
} // Connect

function Disconnect () {
  global $ecrserver;
  global $command;

  $msg;

  if ($ecrserver) {
    if ($command == "shutdown") {
      $msg = "Disconnected from server - shutdown server";
    } else {
      $command  = "quit";
      $msg      = "Disconnected from server";
    } // if
    SendServerCmd ($ecrserver, $command);
    GetServerAck  ($ecrserver);
    verbose ($msg);
    $ecrserver->disconnect ();
  } // if
} // Disconnect

function GetECRRecord ($ecr) {
  global $ecrserver;

  $fields;

  debug ("ENTER GetECRRecord ($ecr)");
  if (!$ecrserver) {
    verbose ("Not connected to server yet!");
    verbose ("Attempting connection to $default_server...");
    if (!Connect (SERVER)) {
      print "Unable to connect to server ". SERVER . "&lt;br&gt;";
      exit (1);
    } // if
  } // if

  SendServerCmd ($ecrserver, $ecr);
  GetServerAck  ($ecrserver);

  if ($ecr == "*") {
    verbose ("Getting all ECRs");
    $fields = GetServerList ($ecrserver);
  } else {
    verbose ("Getting specific ECR $ecr");
    $fields = GetServerResponse ($ecrserver);
  } // if

  SendServerAck ($ecrserver);

  return $fields;
} // GetECRRecord

function Shutdown () {
  global $command;

  verbose ("Sending disconnect command to server");
  $command = "quit";
  Disconnect ();
} // Shutdown

function ConnectToServer ($host, $port = 1500) {
  $socket = new Net_Socket ();
  
  debug ("Socket created... Attempting to connect to $host:$port");
  // create a tcp connection to the specified host and port
  if (@$socket->connect ($host, $port) == 1) {
    verbose ("Socket $socket connected");
  } else {
    print "Unable to connect to server $host:$port!&lt;br&gt;";
    exit (1);
  } // if

  return $socket;
} // ConnectToServer

function SendServerAck ($server) {
  $server->write ("ACK" . "\n");
} // SendServerAck

function GetServerAck ($server) {
  while ($srvresp = $server->readLine ()) {
    if ($srvresp == "ACK") {
      return;
    } // if
    verbose ("Received $srvresp from server - expected ACK");
  } // while
} // GetServerAck

function GetServerList ($server) {
  $ecrs = array ();

  while ($srvresp = $server->readLine ()) {
    if ($srvresp == "ACK") {
      break;
    } // if

    if (preg_match ("/ECR.*was not found/", $srvresp)) {
      return;
    } else {
      array_push ($ecrs, $srvresp);
    } // if
  } // while

  return $ecrs;
} # GetServerList

function GetServerResponse ($server) {
  $fields;

  while ($srvresp = $server->readLine ()) {
    if ($srvresp == "ACK") {
      break;
    } // if

    if (preg_match ("/ECR.*was not found/", $srvresp)) {
      return;
    } else {
      preg_match ("/(^\w+):\s+(.*)/s", $srvresp, $matches);
      $value = str_replace ("\\n", "\n", $matches [2]);
      $fields {$matches [1]} = $value;
    } // if
  } // while

  return $fields;
} // GetServerResponse

function SendServerCmd ($server, $command) {
  $server->write ($command . "\n");
} // SendServerCmd
?>