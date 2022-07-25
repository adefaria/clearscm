<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	Fsutils.php
// Description:	Utility funcitons
// Author:	Andrew@ClearSCM.com
// Created:	Mon Apr 28 15:20:06 MST 2008
// Modified:	
// Language:	PHP
//
// (c) Copyright 2008, ClearSCM, Inc., all rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
// Constants
define (VERSION, "1.0");

define ("BYTE",		 	     1);
define ("KBYTE",	BYTE	* 1024);
define ("MEG",		KBYTE	* 1024);
define ("GIG",		MEG	* 1024);

function debug ($msg) {
  global $debug;

  if ($debug == 1) {
    print "<font color=red>DEBUG:</font> $msg<br>";
  } // if
} // debug

function dumpObject ($object) {
  print "<pre>";
  print_r ($object);
  print "</pre>";
} // dumpObject

function error ($msg, $errno = 0) {
  print "<p><font color=\"red\">ERROR:</font> $msg";

  if ($errno != 0) {
    print " ($errno)</p>";
    exit;
  } else {
    print "</p>";
  } // if
} // error
  
function banner () {
  return $banner;
} // banner

function YMD2MDY ($date) {
  return substr ($date, 5, 2) . "/" .
         substr ($date, 8, 2) . "/" .
         substr ($date, 0, 4);
} // YMD2MDY

function MDY2YMD ($date) {
  return substr ($date, 6, 4) . "-" .
         substr ($date, 0, 2) . "-" .
         substr ($date, 3, 2);
} // MDY2YMD

function copyright () {
  $year = date ("Y");

  $thisFile	= "$_SERVER[DOCUMENT_ROOT]/$_SERVER[PHP_SELF]";
  $lastModified = date ("F d Y @ g:i a", filemtime ($thisFile));

  $copyright .= <<<END
<div class=copyright>
Fsmon Version 
END;
  $copyright .= VERSION;
  $copyright .= <<<END
<br>Last Modified: $lastModified<br>
Copyright $year &copy; <a href="http://clearscm.com">ClearSCM, Inc.</a>, all rights reserved<br>
<a href="/"><img border=0 src="/images/HomeSmall.gif">Home</a>
</div>
END;

  return $copyright;
} // copyright

function Today2SQLDatetime () {
  return date ("Y-m-d H:i:s");
} // Today2SQLDatetime

function getPeriods () {
  return array (
    "hourly",
    "daily",
    "weekly",
    "monthly"
  );
} // getPeriods

function getScales () {
  return array (
    "byte",
    "kbyte",
    "meg",
    "gig"
  );
} // getScales
?>