<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	Utils.php
// Description:	Utility funcitons
// Author:	Andrew@ClearSCm.com
// Created:	Mon Apr 28 15:20:06 MST 2008
// Modified:	
// Language:	PHP
//
// (c) Copyright 2008, General Dynamics, all rights reserved.
//
// All rights reserved except as subject to DFARS 252.227-7014 of contract
// number CP02H8901N issued under prime contract N00039-04-C-2009.
//
// Warning: This document contains technical data whose export is restricted
// by the Arms Export Control Act (Title 22, U.S.C., Sec 2751, et seq.) or the
// Export Administration Act of 1979, as amended, Title, 50, U.S.C., App. 2401
// et seq. Violations of these export laws are subject to severe criminal
// penalties. Disseminate in accordance with provisions of DoD Directive
// 5230.25.
//
////////////////////////////////////////////////////////////////////////////////
// Constants
$VERSION = "1.2.1";

$webdir	= dirname  ($_SERVER["PHP_SELF"]);

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

function Error ($msg) {
  print "<font color=red><b>ERROR:</b></font> $msg<br>";
} // Error

function banner () {
  $banner = <<<END
<table class="banner" width="100%" border="0" cellpadding="0" cellspacing="0">
  <tr>
    <td class="bannerLeft"><a href="/Rantest">
    <img src="/images/companyLogo.gif" alt="General Dynamics C4 Systems" border="0"></a></td>
    <td class="bannerRight">&nbsp;</td>
  </tr>
</table>
END;

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

function cmpStr ($a, $b, $field, $direction) {
  if ($direction == "ascending") {
    return strcmp ($a[$field], $b[$field]);
  } else {
    return strcmp ($b[$field], $a[$field]);
  } // if
} // cmpStr

function cmpNbr ($a, $b, $field, $direction) {
  if ($a[$field] == $b[$field]) {
    return 0;
  } // if

  if ($direction == "ascending") {
    return ($a[$field] < $b[$field]) ? -1 : 1;
  } else {
    return ($a[$field] < $b[$field]) ? 1 : -1;
  } // if
} // cmpNbr

function getUsername ($userid) {
  exec ("ypmatch $userid passwd | cut -f5 -d:", &$username);

  if (empty ($username)) {
    return "Unknown";
  } else {
    if ($username[0] == "SWIT account for SWIT testing") {
      return "pswit";
    } else {
      return $username[0];
    } // if
  } // if
} // getUsername

function emailUsersDropdown () {
  define (DIM, "#888");

  exec ("ypcat passwd | grep ^p|cut -f1,5 -d: | grep -v 'SWIT account'", &$userids);

  $users ["unknown"] = "&lt;Select User&gt;";

  foreach ($userids as $user) {
    list ($pnbr, $name) = explode (":", $user);

    $users [$pnbr] = $name;
  } # foreach

  asort ($users);

  $dropdown = "Email to <select name=user class=inputfield style=\"color: " . DIM . "\">";
  
  foreach ($users as $pnbr => $name) {
    $dropdown .= "<option value=\"$pnbr:$name\" style=\"color: ";

    if ($pnbr != "unknown") {
      $dropdown .= "black";
    } else {
      $dropdown .= DIM;
    } // if

    $dropdown .= "\">$name</option>";
  } // foreach

  $dropdown .= "</select>";

  return $dropdown;
} // emailUsersDropdown

function copyright () {
  global $VERSION;

  $year = date ("Y");

  $thisFile	 = "$_SERVER[DOCUMENT_ROOT]/$_SERVER[PHP_SELF]";
  $lastModified = date ("F d Y @ g:i a", filemtime ($thisFile));

  print <<<END
<div class=copyright>
Rantest Web Version: <a href="ChangeLog.php#$VERSION">$VERSION</a> - EAST Automation Team<br>
Last Modified: $lastModified<br>
Copyright $year &copy; General Dynamics, all rights reserved<br>
<a href="/"><img border=0 src="/images/HomeSmall.gif">Home</a>
&nbsp;|&nbsp;
<a href="http://ranweb/dokuwiki/doku.php">Wiki</a>
&nbsp;|&nbsp;
<a href="http://ranweb/dokuwiki/doku.php?id=ran:ran_test_automation_users_guide">Users Guide</a>
&nbsp;|&nbsp;
<a href="http://ranweb/dokuwiki/doku.php?id=ran:rantest">Usage</a>
&nbsp;|&nbsp;
<a href="/docs">Other Docs</a><br>
</div>
END;
} // copyright

function Today2SQLDatetime () {
  return date ("Y-m-d H:i:s");
} // Today2SQLDatetime

function FormatDuration ($difference) {
  $seconds_per_min  = 60;
  $seconds_per_hour = 60 * $seconds_per_min;
  $seconds_per_day  = $seconds_per_hour * 24;

  $days    = 0;
  $hours   = 0;
  $minutes = 0;
  $seconds = 0;

  if ($difference > $seconds_per_day) {
    $days       = (int) ($difference / $seconds_per_day);
    $difference = $difference % $seconds_per_day;
  } // if

  if ($difference > $seconds_per_hour) {
    $hours      = (int) ($difference / $seconds_per_hour);
    $difference = $difference % $seconds_per_hour;
  } // if

  if ($difference > $seconds_per_min) {
    $minutes    = (int) ($difference / $seconds_per_min);
    $difference = $difference % $seconds_per_min;
  } // if

  $seconds = $difference;

  $day_str  = "";
  $hour_str = "";
  $min_str  = "";
  $sec_str  = "";
  $duration = "";

  if ($days > 0) {
    $day_str  = $days == 1 ? "1 day" : "$hours days";
    $duration = $day_str;
  } // if

  if ($hours > 0) {
    $hour_str = $hours == 1 ? "1 hr" : "$hours hrs";

    if ($duration != "") {
      $duration .= " ". $hour_str;
    } else {
      $duration = $hour_str;
    } // if
  } // if

  if ($minutes > 0) {
    $min_str = $minutes == 1 ? "1 min" : "$minutes mins";

    if ($duration != "") {
      $duration .= " " . $min_str;
    } else {
      $duration = $min_str;
    } // if
  } // if

  if ($seconds > 0) {
    $sec_str = $seconds == 1 ? "1 sec" : "$seconds secs";

    if ($duration != "") {
      $duration .= " " . $sec_str;
    } else {
      $duration = $sec_str;
    } // if
  } // if

  if ($duration == "" and $seconds == 0) {
    $duration = "under 1 second";
  } // if

  return $duration;
} // FormatDuration

function Duration ($start, $end) {
  $start_timestamp = strtotime ($start);
  $end_timestamp   = strtotime ($end);

  $difference = $end_timestamp - $start_timestamp;

  return FormatDuration ($difference);
} // Duration

// Returns a string representation of a CSV file given a hash
// representing the data. If $title is supplied it is made the first
// line. Next a header row is generated based on the keys of the $data
// hash. Finally data rows are generated. Any key in the hash
// beginning with "_" is skipped.
function exportCSV ($data, $title = "") {
  if (isset ($title)) {
    $csv .= "$title\n";
  } // if

  // Create header line
  $firstTime = true;

  foreach ($data[0] as $key => $value) {
    // Skip "hidden" fields - fields beginning with "_"
    if (preg_match ("/^_/", $key) == 1) {
      continue;
    } // if

    if (!$firstTime) {
      $csv .= ",";
    } else {
      $firstTime = false;
    } // if

    $csv .= "\"$key\"";
  } // foreach

  $csv .= "\n";

  // Data lines
  foreach ($data as $entry) {
    $firstTime = true;

    foreach ($entry as $key => $value) {
      // Skip "hidden" fields - fields beginning with "_"
      if (preg_match ("/^_/", $key) == 1) {
	continue;
      } // if

      if (!$firstTime) {
	$csv .= ",";
      } else {
	$firstTime = false;
      } // if

      $csv .= "\"$value\"";
    } // foreach

    $csv .= "\n";
  } // foreach

  return $csv;
} // exportCSV

function getStyleSheets () {
  $styleSheet = "\n<style type=\"text/css\">\n";

  foreach (file ("$_SERVER[DOCUMENT_ROOT]/css/Testing.css") as $line) {
    $styleSheet .= $line;
  } // foreach

  $styleSheet .= "\n";

  foreach (file ("$_SERVER[DOCUMENT_ROOT]/css/Tables.css") as $line) {
    $styleSheet .= $line;
  } // foreach

  $styleSheet .= "\n</style>\n";

  return $styleSheet;
} // getStyleSheets

function mailReport ($pnbr, $username, $subject, $body, $filename, $attachment) {
  if ($pnbr == "unknown") {
    return "<p><span class=error>ERROR:</span> You need to select a user to email to first!</p>";
  } // if    

  $mimeSeparator = md5 (time ());

  $to       = "$username <$pnbr@gdc4s.com>";
  $toDisplay= "$username &lt;<a href=\"mailto:$pnbr@gdc4s.com\">$pnbr@gdc4s.com</a>&gt;";

  $headers  = "From: RanTestWeb@gdc4s.com\n";
  $headers .= "MIME-Version: 1.0\n";
  $headers .= "X-Mailer: PHP\n";
  $headers .= "Content-Type: multipart/mixed;\n";
  $headers .=" boundary=\"$mimeSeparator\"";

  $message  = "This is a multi-part message in MIME format.\n";
  $message .= "--$mimeSeparator\n";
  $message .= "Content-Type: text/html; charset=ISO-8859-1\n";
  $message .= "Content-Transfer-Encoding: 7bit\n\n";

  $message .= <<<END
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
END;

  $message .= getStyleSheets ();
  $message .= <<<END
</head>
<body>
<h1 align="center">$subject</h1>
END;
 
  $message .= $body;

  $message .= "\n--$mimeSeparator\n";
  $message .= "Content-Type: text/vnd.ms-excel; name=\"$filename\"\n";
  $message .= "Content-Disposition: inline; filename=\"$filename\"\n\n";
  $message .= $attachment;
  $message .= "\n\n--$mimeSeparator\n";

  if (mail ($to, $subject, $message, $headers) == false) {
    return "<p><span class=error>ERROR:</span> Unable to send email to $to</p>";
  } else {
    return "<p>Email sent to $toDisplay</p>";
  } // if
} // mailReport
?>
