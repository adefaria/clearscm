<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	FsmonDB.php
// Description:	PHP Module to access the fsmon database
// Author:	Andrew@ClearSCm.com
// Created:	Mon Apr 28 15:20:06 MST 2008
// Modified:	
// Language:	PHP
//
// (c) Copyright 2008, ClearSCM Inc., all rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
include_once ("Fsutils.php");

// DEBUG Flag
$debug = 1;

// Read only access
$userid		= "fsmon";
$password	= "fsmon";
$dbserver	= "seast1";
$dbname		= "fsmon";

// N/A
$na = "<font color=#999999>N/A</font>";

function dbError ($msg, $statement) {
  $errno  = mysql_errno ();
  $errmsg = mysql_error ();

  print <<<END
<h2><font color="red">ERROR:</font> $msg</h2>
<b>Error #$errno:</b><br>
<blockquote>$errmsg</blockquote>
<b>SQL Statement:</b><br>
<blockquote>$statement</blockquote>
END;

  exit ($errno);
} // dbError

function openDB () {
  global $dbserver, $userid, $password, $dbname;

  $db = mysql_connect ($dbserver, $userid, $password)
    or dbError (__FUNCTION__ . ": Unable to connect to database server $dbserver", "Connect");

  mysql_select_db ($dbname)
    or dbError (__FUNCTION__ . ": Unable to select the $dbname database", "$dbname");
} // openDB

function getFSInfo ($system = "", $mount = "", $period = "daily") {
  $sysCondition		= (isset ($system)) ? "where sysname = \"$system\"" : "";
  $mountCondition	= (isset ($mount))  ? "  and mount   = \"$mount\""  : "";

  if (!($period == "hourly"	or 
	$period == "daily"	or
	$period == "weekly"	or
	$period == "monthly")) {
    error ("Invalid period - $period - specified", 1);
  } // if

  $statement = <<<END
select
  sysname,
  mount,
  timestamp,
  size,
  used,
  free,
  reserve
from
  fs
  $sysCondition
  $mountCondition
order by
  timestamp
END;

  $result = mysql_query ($statement)
    or DBError ("Unable to execute query: ", $statement);

  $data = array ();

  $lastPeriod	= "";
  $maxUsed	= 0;

  while ($row = mysql_fetch_array ($result)) {
    $line["sysname"]	= $row["sysname"];
    $line["mount"]	= $row["mount"];
    $line["timestamp"]	= $row["timestamp"];

    // Snapshot's finest granularity is 1 hour intervals. If hourly
    // therefore just capture the data an move on.
    if ($period == "hourly") {
      $line["size"]	= $row["size"];
      $line["used"]	= $row["used"];
      $line["free"]	= $row["free"];
      $line["reserve"]	= $row["reserve"];
    } elseif ($period == "daily") {
      $thisPeriod = substr ($row["timestamp"], 0, 10);

      if ($lastPeriod == "") {
	$lastPeriod = $thisPeriod;
      } elseif ($lastPeriod == $thisPeriod) {
	continue;
      } // if
      
      $lastPeriod = $thisPeriod;

      if ($row["used"] > $maxUsed) {
	$maxUsed		= $row["used"];
	$line["size"]		= $row["size"];
	$line["used"]		= $row["used"];
	$line["free"]		= $row["free"];
	$line["reserve"]	= $row["reserve"];
      } else {
	continue;
      } // if
    } elseif ($period == "weekly") {
      error ("Weekly not handled yet", 1);
    } elseif ($period == "monthly") {
      $thisPeriod = substr ($row["timestamp"], 0, 7);
      if ($lastPeriod == "") {
	$lastPeriod = $thisPeriod;
      } elseif ($lastPeriod == $thisPeriod) {
	continue;
      } // if

      if ($row["used"] > $maxUsed) {
	$maxUsed		= $row["used"];
	$line["size"]		= $row["size"];
	$line["used"]		= $row["used"];
	$line["free"]		= $row["free"];
	$line["reserve"]	= $row["reserve"];
      } else {
	continue;
      } // if
    } // if

    array_push ($data, $line);
  } // while

  return $data;
} // getFSInfo

function getSystem ($system = "") {
  $statement = "select * from system";

  if (isset ($system) and $system != "") {
    $statement .= " where name = \"$system\"";
  } // if

  $result = mysql_query ($statement)
    or DBError ("Unable to execute query: ", $statement);

  $data = array ();

  while ($row = mysql_fetch_array ($result, MYSQL_ASSOC)) {
    array_push ($data, $row);
  } // while

  return $data;
} // getSystem

function getMounts ($system) {
  $statement = "select mount from filesystems where sysname = \"$system\" order by mount";

  $result = mysql_query ($statement)
    or DBError ("Unable to execute query: ", $statement);

  $data = array ();

  while ($row = mysql_fetch_array ($result)) {
    array_push ($data, $row["mount"]);
  } // while

  return $data;
} // getMounts
?>
