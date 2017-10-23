<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	rantest.php
// Revision:	1.2
// Description:	Produce Daily Test Report, Test Suite Report and Test Steps
//		report.
// Author:	Andrew@ClearSCM.com
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
$script = basename ($_SERVER["PHP_SELF"]);

include_once "$_SERVER[DOCUMENT_ROOT]/php/Utils.php";
include_once "$_SERVER[DOCUMENT_ROOT]/php/RantestDB.php";

$testName	= $_REQUEST["testName"];
$runid    	= $_REQUEST["runid"];
$date     	= $_REQUEST["date"];
$suiteid  	= $_REQUEST["suiteid"];
$user		= $_REQUEST["user"];

$type		= (empty ($_REQUEST["type"]))	   ? "All"	  : $_REQUEST["type"];
$action		= (empty ($_REQUEST["action"]))    ? "Report"     : $_REQUEST["action"];
$sortBy		= (empty ($_REQUEST["sortBy"]))    ? "Start"      : $_REQUEST["sortBy"];
$direction	= (empty ($_REQUEST["direction"])) ? "descending" : $_REQUEST["direction"];

function createTestStepsHeader ($testcase) {
  $header = <<<END
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Testing.css">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Tables.css">
<title>Test Steps for $testcase</title>
</head>

<body>
END;

  $header .= banner ();
  $header .= <<<END
<h1 align="center">Test Steps for $testcase</h1>
END;

  return $header;
} // createTestStepsHeader

function createTestRunsHeader ($day) {
  global $dateDropdown;

  $header = <<<END
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Testing.css">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Tables.css">
<title>Daily Test Report for $day</title>
<script language="javascript">
function ChangeDay (day, script) {
  window.location = script + "?day=" + day;
} // ChangeDay
function ChangeType (day, type, script) {
  window.location = script + "?day=" + day + "&type=" + type;
} // ChangeType
</script>
</head>
END;

 $header .= banner ();
 $header .= <<<END
<body>
<h1 align="center">Daily Test Report for $dateDropdown</h1>
END;

  return $header;
} // createTestRunsHeader

function createSuiteRunsHeader ($id) {
  $suite = getName ("suite", $id);
  
  $header = <<<END
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Testing.css">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Tables.css">
<title>Suite Report for $suite</title>
</head>

<body>
END;

  $header .= banner ();

  return $header;
} // createSuiteRunsHeader

function createTestStepsPage ($testName, $forEmail = false, $message = "") {
  global $runid, $date, $script;

  $data = getTestSteps ($runid);

  if (!$forEmail) {
    if (isset ($message)) {
      $page .= "<div align=center>$message</div>";
    } // if
  } // if

  $page .= <<<END
<table align=center width=90%>
  <caption><center>
DUT: <font class="standout">{$data[_header][DUTVersion]}</font>
EAST: <font class="standout">{$data[_header][EASTVersion]}</font>
TM500: <font class="standout">{$data[_header][TM500Version]}</font>
NMS: <font class="standout">{$data[_header][NMSVersion]}</font>
RANTEST: <font class="standout">{$data[_header][RANTESTVersion]}</font>
Date: <font class="standout">$date</font>
  </center></caption>
  <thead>
END;

  if (!$forEmail) {
    $page .= <<<END
    <tr>
      <th class="clear" align="left"><a href="$script?action=Export&testName=$testName&runid=$runid&date=$date"><input type="submit" value="Export to CSV"></a>&nbsp;<a href="TestHistory.php?testcase=$testName"><input type="submit" value="History"></a></th>
      <th class=clear colspan="4" align="right"><form action="$script?action=Mail&date=$date&testName=$testName&runid=$runid" method="post">
END;

    $page .= emailUsersDropdown ();
    $page .= <<<END
    </select>
    <input type="submit" value="Send"></form>
    </th>
    </tr>
END;
  } // if

  $page .= <<<END
    <tr>
      <th class=left>Step</th>
      <th>Status</th>
      <th>Start</th>
      <th>End</th>
      <th class=right>Duration</th>
    </tr>
  </thead>
  <tbody>
END;

  foreach ($data["_steps"] as $line) {
    $steps++;
    $row_color		= setRowColor ($line["Status"]);
    $line["Status"]	= colorResult ($line["Status"]);
    $total_time	       += $line[Duration];
    $startTime		= substr ($line["Start"], 11, 8);
    $endTime		= substr ($line["End"],   11, 8);

    $page .= <<<END
      <tr $row_color>
        <td>$line[Step]</td>
        <td>$line[Status]</td>
        <td align="center">$startTime</td>
        <td align="center">$endTime</td>
        <td align="right">
END;
    $page .= FormatDuration ($line[Duration]);
    $page .= "</tr>";
  } // foreach

  $total_duration = FormatDuration ($total_time);

  $logs = logs ($data["_header"]["_eastlogs"], $forEmail);

  $username = getUserName ($data["_header"]["userid"]);

  $page .= <<<END
  <tfoot>
    <tr>
      <th align="left">Total steps run in $testName: $steps</th>
      <th align="right" colspan="2">Run by: <a href="mailto:{$data[_header][userid]}@gdc4s.com" class="tablelink">$username</a></th>
      <th align="center">$logs</th>
      <th align="right">$total_duration</th>
    </tr>
  </tfoot>
  </tbody>
</table>
END;

  return $page;
} // createTestStepsPage

function createTestRunsPage ($day, $forEmail = false, $message = "") {
  global $sortBy, $direction, $day, $type, $script, $testTypes;

  if (!$forEmail) {
    if ($sortBy == "Suite") {
      $suiteDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
        : "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "Testcase") {
      $testcaseDirection = ($direction == "ascending") 
        ? "<img src=/images/down.png border=0>"
        : "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "Type") {
      $typeDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
        : "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "Unit") {
      $unitDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
        : "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "Status") {
      $statusDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
        : "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "Start") {
      $startDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
        : "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "End") {
      $endDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
        : "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "Duration") {
      $durationDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png border=0>";
    } // if

    if (isset ($message)) {
      $page .= "<div align=center>$message</div>";
    } // if
  } // if

  $page .= <<<END
<table align=center>
  <thead>
END;

  if (!$forEmail) {
    $page .= <<<END
    <tr>
      <th class="clear" align="left" colspan="5">
<a href="$script?action=Export&day=$day"><input type="submit"
 value="Export to CSV"></a>&nbsp;<a href="FailureAnalysis.php?day=$day">
<input type="submit" value="Analyze Failures"></a>
&nbsp;Type: <select name="type" class="inputfield" onChange="ChangeType('$day',this.value,'$script');">
END;

    foreach ($testTypes as $t) {
      if ($type != $t) {
	$page .= "<option>$t</option>";
      } else {
	$page .= "<option selected=\"selected\">$t</option>";
      } // if
    } // foreach

    $page .= <<<END
      </th>
      <th class=clear colspan="5" align="right"><form action="$script?action=Mail&day=$day&type=$type" method="post">
END;

    $page .= emailUsersDropdown ();
    $page .= <<<END
    </select>
    <input type="submit" value="Send"></form>
    </th>
    </tr>
END;
  } else {
    $page .= "<th class=\"clear\" colspan=\"10\">Type: $type Sorted by: $sortBy ($direction)</th>";
  } // if

  $direction = ($direction == "ascending") ? "descending" : "ascending";
  $urlParms  = "$script?day=$day&&direction=$direction&type=$type&sortBy";

  $page .= <<<END
    <tr>
      <th class="left">#</th>
      <th><a href="$urlParms=Suite">Suite&nbsp;$suiteDirection</a></th>
      <th><a href="$urlParms=Testcase">Testcase&nbsp;$testcaseDirection</a></th>
      <th><a href="$urlParms=Type">Type&nbsp;$typeDirection</a></th>
      <th><a href="$urlParms=Unit">Unit/Version&nbsp;$unitDirection</a></th>
      <th>Logs</th>
      <th><a href="$urlParms=Status">Status&nbsp;$statusDirection</a></th>
      <th><a href="$urlParms=Start">Start&nbsp;$startDirection</a></th>
      <th><a href="$urlParms=End">End&nbsp;$endDirection</a></th>
      <th class="right"><a href="$urlParms=Duration">Duration&nbsp;$durationDirection</</th>
    </tr>
  </thead>
  <tbody>
END;

  $page .= <<<END
END;

  $data = getTestRuns (MDY2YMD ($day), $type);

  $total_time = 0;

  foreach ($data as $line) {
    // WARNING: This is odd! $line["Suite"] should be empty if there
    // was no suite associated with it (thereby suiteid=0) but for
    // some odd reason due to the complex select statement used
    // suiteid ends up being 1 which is associated with the suite name
    // of "nightly".
    if ($line["Suite"] == "nightly") {
      $line["Suite"] = "<font color=#999999>Standalone</font>";
    } else {
      $line["Suite"] = "<a href=\"$me?suiteid=$line[_suiteid]\">$line[Suite]</a>";
    } // if 

    $row_color   = setRowColor ($line["Status"]);
    $testResult  = colorResult ($line["Status"]);
    $total_time += $line["Duration"];
    $me		 = ($script == "index.php") ? "" : $script;
    $logs	 = logs ($line["_eastlogs"], $forEmail);
    $tests++;

    $page .= <<<END
    <tr $row_color>
      <td align=center>$tests</td>
      <td>$line[Suite]</td>
      <td><a href=$me?testName=
END;
    $page .= $line["Testcase"];
    $page .= "&runid=$line[_runid]&date=$day>";
    $page .= $line["Testcase"];
    $page .= <<<END
</a></td>
      <td align="center">$line[Type]</td>
      <td align="center">
END;
    $page .= $line["Unit/Version"];
    $page .= <<<END
</td>
      <td align="center">$logs</td>
      <td align="center">$testResult</td>
      <td align="center">$line[Start]</td>
      <td align="center">$line[End]</td>
      <td align="right">
END;

    $page .= FormatDuration ($line["Duration"]);
    $page .= "</td></tr>";
  } // while

  $total_duration = FormatDuration ($total_time);

  $page .= <<<END
  <tfoot>
    <tr>
      <th align="left" colspan="9">$tests Run&nbsp;
END;
  $page .= stats ($day, $type);
  $page .= <<<END
</th>
      <th align="right">$total_duration</th>
    </tr>
  </tfoot>
  </tbody>
</table>
END;
  return $page;
} // createTestRunsPage

function createSuiteRunsPage ($suiteid, $forEmail = false, $message = "") {
  global $sortBy, $direction, $day;

  $name = getName ("suite", $suiteid);
  $page = "<h1 align=center>Test Suite Report for $name</h1>";

  if (!$forEmail) {
    if ($sortBy == "Status") {
      $statusDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
        : "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "Start") {
      $startDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
        : "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "End") {
      $endDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
        : "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "Duration") {
      $durationDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
        : "<img src=/images/up.png border=0>";
    } // if

    if (isset ($message)) {
      $page .= "<div align=center>$message</div>";
    } // if
  } // if

  $page .= <<<END
<table align=center width="75%">
  <thead>
END;

  if (!$forEmail) {
    $page .= <<<END
    <tr>
      <th class="clear" align="left" colspan="2"><a href="$script?action=Export&suiteid=$suiteid"><input type="submit" value="Export to CSV"></a>
END;

    $page .= <<<END
      </th>
      <th class=clear colspan="2" align="right"><form action="$script?action=Mail&suiteid=$suiteid" method="post">
END;

    $page .= emailUsersDropdown ();
    $page .= <<<END
    </select>
    <input type="submit" value="Send"></form>
    </th>
    </tr>
END;
  } // if

  $direction = ($direction == "ascending") ? "descending" : "ascending";
  $urlParms  = "$script?suiteid=$suiteid&direction=$direction&&sortBy";

  $data = getSuiteRuns ($suiteid);

  $page .= <<<END
    <tr>
      <th class=left><a href="$urlParms=Status">Status&nbsp;$statusDirection</a></th>
      <th><a href="$urlParms=Start">Start&nbsp;$startDirection</a></th>
      <th><a href="$urlParms=End">End&nbsp;$endDirection</a></th>
      <th class=right><a href="$urlParms=Duration">Duration&nbsp;$durationDirection</a></th>
    </tr>
  </thead>
  <tbody>
END;

  foreach ($data as $line) {
    $row_color	= setRowColor ($line["Status"]);
    $status	= colorResult ($line["Status"]);
    $duration	= FormatDuration ($line["Duration"]);

    $suiteruns++;
    $total_time += $line["Duration"];

    $page .= <<<END
      <tr $row_color>
        <td>$status</td>
        <td align="center">$line[Start]</td>
        <td align="center">$line[End]</td>
        <td align="right">$duration</td>
      </tr>
END;
  } // while

  $total_duration = FormatDuration ($total_time);

  $page .= <<<END
  <tfoot>
    <tr>
      <th align="left" colspan="3">Total sutie runs for $name: $suiteruns</th>
      <th align="right">$total_duration</th>
    </tr>
  </tfoot>
  </tbody>
</table>
END;

  return $page;
} // createSuiteRunsPage

function displayStepRun ($testName, $message = "") {
  print createTestStepsHeader ($testName);
  print createTestStepsPage ($testName, false, $message);

  copyright ();
} // displayStepRun

function displayTestRuns ($day, $message = "") {
  print createTestRunsHeader ($day);
  print createTestRunsPage ($day, false, $message);

  copyright ();
} // displayTestRuns

function displaySuiteRun ($suiteid, $message = "") {
  print createSuiteRunsHeader ($suiteid);
  print createSuiteRunsPage ($suiteid, false, $message);

  copyright ();
} // displaySuiteRun

// The $data structure for test steps is unique so handle exportion
// here.
function exportStepRunCSV ($data, $title) {
  global $na;

  $csv .= "$title\n";

  // Put out header information
  $csv .= "DUT, EAST, TM500, NMS, RANTEST, USER, DATE, LOGS\n";

  $versions = array (
    "DUTVersion",
    "EASTVersion",
    "TM500Version",
    "NMSVersion",
    "RANTESTVersion"
  );

  foreach ($versions as $version) {
    if ($data["_header"][$version] == $na) {
      $csv .= "N/A,";
    } else {
      $csv .= $data["_header"][$version] . ",";
    } // if
  } // foreach

  $csv .= $data["_header"]["userid"]			. ",";
  $csv .= YMD2MDY ($data["_header"]["Date"])		. ",";
  $csv .= logs ($data["_header"]["_eastlogs"], true)	. "\n\n";

  // Create header line
  $firstTime = true;

  foreach ($data["_steps"][0] as $key => $value) {
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

  foreach ($data["_steps"] as $entry) {
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
} // exportStepRunCSV
  
function exportStepRun ($testcase, $runid, $date) {
  $timestamp	= getTestRunTimestamp ($runid);
  $filename = "Step Report." . $timestamp . ".csv";

  header ("Content-Type: application/octect-stream");
  header ("Content-Disposition: attachment; filename=\"$filename\"");

  print exportStepRunCSV (getTestSteps ($runid), "Step Report for $testcase");

  exit;
} // exportStepRun

function exportTestRuns ($day) {
  global $type;

  $filename = "Daily Test Report." . $day . ".csv";

  header ("Content-Type: application/octect-stream");
  header ("Content-Disposition: attachment; filename=\"$filename\"");

  print exportCSV (getTestRuns (MDY2YMD ($day), $type, true), "Daily Test Report for $day");

  exit;
} // exportTestRuns

function exportSuiteRun ($suiteid) {
  $suite	= getName ("suite", $suiteid);
  $filename	= "Suite Report." . $suite . ".csv";

  header ("Content-Type: application/octect-stream");
  header ("Content-Disposition: attachment; filename=\"$filename\"");

  print exportCSV (getSuiteRuns ($suiteid), "Suite Report for $suite");

  exit;
} // exportSuiteRun

function mailStepRunReport ($testName, $pnbr, $username) {
  global $runid;

  $subject	= "Step Report for $testName";
  $body		= createTestStepsPage ($testName, true);
  $timestamp	= getTestRunTimestamp ($runid);
  $filename	= "Step Report." . $timestamp . ".csv";
  $attachment	= exportStepRunCSV (getTestSteps ($runid), $subject);

  return mailReport ($pnbr, $username, $subject, $body, $filename, $attachment);
} // mailStepReport

function mailTestRunsReport ($day, $pnbr, $username) {
  global $type;

  $subject	= "Daily Test Report for $day";
  $body		= createTestRunsPage ($day, true);
  $filename	= "TestRuns.$day.csv";
  $attachment	= exportCSV (getTestRuns (MDY2YMD ($day), $type, true), $subject);

  return mailReport ($pnbr, $username, $subject, $body, $filename, $attachment);
} // mailTestRunsReport

function mailSuiteRunReport ($suiteid, $pnbr, $username) {
  $subject	= "Suite Report for $suitid";
  $body		= createSuiteRunsPage ($suiteid, true);
  $filename	= "Suite Runs.$suiteid.csv";

  $attachment	= exportCSV (getSuiteRuns ($suiteid, true), $subject);

  return mailReport ($pnbr, $username, $subject, $body, $filename, $attachment);
} // mailSuiteRunReport

openDB ();

$dateDropdown = reportDateDropdown ();

switch ($action) {
  case "Export":
    if ($suiteid != 0) {
      exportSuiteRun ($suiteid);
    } elseif (isset ($testName)) {
      exportStepRun ($testName, $runid, $date);
    } else {
      exportTestRuns ($day);
    } // if

    break;

  case "Mail":
    list ($pnbr, $username) = explode (":", $user);

    if (isset ($suiteid)) {
      $message = mailSuiteRunReport ($suiteid, $pnbr, $username);
      displaySuiteRun ($suiteid, $message);
    } elseif (isset ($testName)) {
      $message = mailStepRunReport ($testName, $pnbr, $username);
      displayStepRun ($testName, $message);
    } else {
      $message = mailTestRunsReport ($day, $pnbr, $username);

      displayTestRuns ($day, $message);
    } // if

    break;

  default:
    if (isset ($suiteid)) {
      displaySuiteRun ($suiteid);
    } elseif (isset ($testName)) {
      displayStepRun ($testName);
    } else {
      displayTestRuns ($day);
    } // if

    break;
} // switch  
