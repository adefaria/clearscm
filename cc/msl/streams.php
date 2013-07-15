<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	streams.php
// Revision:	1.1.1.1
// Description:	Library to interface to Clearcase streams
// Author:	Andrew@DeFaria.com
// Created:	Wed Jul  5 10:14:02 PDT 2006
// Modified:	2007/05/17 07:45:48
// Language:	PHP
//
// (c) Copyright 2006, Andrew@DeFaria.com, all rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
$version	= "1.0";
$pvob		= "/vobs/ilm_pvob";
$cleartool	= "/opt/rational/clearcase/bin/cleartool";

function debug ($msg) {
  print "<b><font color=red>DEBUG:</font></b> $msg<br>\n";
} // debug

function error ($msg) {
  print "<b><font color=red>ERROR:</font></b> $msg<br>\n";
  exit (1);
} // error

function get_streams () {
  global $pvob;
  global $cleartool;

  $cmd = "$cleartool lsstream -s -invob $pvob";

  exec ($cmd, $output, $status);

  if ($status != 0) {
    print "Unable to execute command \"$cmd\" (Status: $status)<br>";
    exit (1);
  } // if

  return $output;
} // get_streams

function get_usernames () {
  $cmd = "ypcat passwd";

  exec ($cmd, $lines, $status);

  if ($status != 0) {
    print "Unable to execute command \"$cmd\" (Status: $status)<br>";
    exit (1);
  } // if

  $users = array ();

  foreach ($lines as $line) {
    $fields = explode (":", $line);
    $users {$fields [0]} = $fields [4];
  } // foreach

  return $users;
} // get_usernames

function get_users () {
  $cmd = "ypcat passwd";

  exec ($cmd, $lines, $status);

  if ($status != 0) {
    print "Unable to execute command \"$cmd\" (Status: $status)<br>";
    exit (1);
  } // if

  $users = array ();

  foreach ($lines as $line) {
    $fields = explode (":", $line);
    array_push ($users, $fields [0]);
  } // foreach

  return $users;
} // get_users

function get_nusers ($stream) {
  global $cleartool;
  global $pvob;

  $cmd = "$cleartool lslock stream:$stream@$pvob";

  exec ($cmd, $output, $status);

  if ($status != 0) {
    print "Stream: $stream not found";
    exit (1);
  } else {
    if (count ($output) == 0) {
      return;
    } // if 
  } // if

  $nusers = array ();

  foreach ($output as $line) {
    if (preg_match ("/\"Locked except for users: (.*)\"/", $line, $matches)) {
      $nusers = split (" ", $matches [1]);
    } // if
  } // foreach

  return $nusers;
} // get_nusers

function is_member ($new_item, $array) {
  if (empty ($new_item) || empty ($array)) {
    return 0;
  } // if

  foreach ($array as $item) {
    if ($new_item == $item) {
      return 1;
    } // if
  } // foreach

  return 0;
} // is_member

function remove_from_array ($removed_item, $array) {
  $new_array = array ();

  foreach ($array as $item) {
    if ($removed_item != $item) {
      array_push ($new_array, $item);
    } // if
  } // foreach

  return $new_array;
} // remove_from_array

function chnusers ($stream, $users) {
  $nusers = "";

  foreach ($users as $user) {
    if (empty ($nusers)) {
      $nusers .= $user;
    } else {
      $nusers .= ",$user";
    } // if
  } // foreach

  $current_nusers = get_nusers ($stream);

  if (count ($current_nusers) == 0 || count ($users) == 0) {
    $cmd = "./chnusers $stream $nusers";
  } else {
    $cmd = "./chnusers $stream $nusers replace";
  } // if

  exec ($cmd, $output, $status);

  return $status;
} // chnusers

function copyright ($start_year	= "", $version = "") {
  $today	= getdate ();
  $current_year	= $today ["year"];

  $this_file = $_SERVER['PHP_SELF'];

  // Handle user home web pages
  if (preg_match ("/\/\~/", $this_file)) {
    $this_file= preg_replace ("/\/\~(\w+)\/(\s*)/", "/home/$1/web$2/", $this_file);
  } else {
    $this_file = "/var/devenv/tiburon/" . $this_file;
  } // if

  $mod_time  = date ("F d Y @ g:i a", filemtime ($this_file));

  print <<<END
<div class="copyright">
Last modified: $mod_time<br>
Copyright &copy; 
END;

  if ($start_year != "") {
    print "$start_year-";
  } // if

print <<<END
$current_year <a href="http://www.hp.com/go/ilm">HP/Information Lifecycle Management Solutions</a><br>
All rights reserved (
END;

print basename ($_SERVER ["PHP_SELF"], ".php");

if ($version != "") {
  print " V$version";
} // if

print ")\n</div>\n";
} // copyright
