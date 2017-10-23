<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	FailureAnalysis.php
// Revision:	1.2
// Description:	Produce a report showing an analysis of failures for a day
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

$day		= $_REQUEST["day"];
$user		= $_REQUEST["user"];

$action		= (empty ($_REQUEST["action"]))    ? "Report"     : $_REQUEST["action"];
$sortBy		= (empty ($_REQUEST["sortBy"]))    ? "Date"       : $_REQUEST["sortBy"];
$direction	= (empty ($_REQUEST["direction"])) ? "ascending"  : $_REQUEST["direction"];

// Sorting functions
function sortTime ($a, $b) {
  global $direction;

  return cmpStr ($a, $b, "Time", $direction);
} // sortTime

function getData ($day) {
  global $sortBy;

  $data = getFailures ($day);

  // Sort data
  if ($sortBy == "Testcase") {
    uasort ($data, "sortTestcase");
  } else if ($sortBy == "Unit") {
    uasort ($data, "sortUnit");
  } else {
    uasort ($data, "sortTime");
  } // if

  return $data;
} // getData

function createCSV ($day) {
  $data = getData ($day);

  // Title line
  $csv  = "Failure Analysis for $day\n";

  // Create header line
  $firstTime = true;

  foreach ($data[0] as $key => $value) {
    // Skip "hidden" fields - fields beginning with "_"
    if (preg_match ("/^_/", $key) == 1) {
      continue;
    } // if

    if ($key == "Failures") {
      $csv .= "\n";
      $csv .= ",Teststep,Failure Reason";
      
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

      if ($key == "Failures") {
	$csv .= "\n";

	foreach ($value as $key => $failure) {
	  $csv .= ",$failure[Step],$failure[Reason]\n";
	} // foreach

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
} // createCSV

function exportStats ($day) {
  $filename = "Test Statistics." . $day . ".csv";

  header ("Content-Type: application/octect-stream");
  header ("Content-Disposition: attachment; filename=\"$filename\"");

  print createCSV ($day);

  exit;
} // exportStats

function createHeader ($day) {
  $header = <<<END
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Testing.css">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Tables.css">
  <title>Failure Analysis for $day</title>
<script language="javascript">
function ChangeDay (day, script) {
  window.location = script + "?day=" + day;
} // ChangeDay
</script>
<body>
END;

  $header .= banner ();

  return $header;
} // createHeader

function createPage ($day, $forEmail = false, $message = "") {
  global $direction, $sortBy, $direction, $script;

  $data		= getData ($day);
  $dateDropdown = reportDateDropdown ();
  $row_nbr	= 0;

  if (!$forEmail) {
    $page .= "<h1 align=\"center\">Failure Analysis for $dateDropdown</h1>";

    // Flip direction
    $direction = ($direction == "ascending") ? "descending" : "ascending";
    $urlParms  = "$script?day=$day&action=$action&direction=$direction&sortBy";

    if ($sortBy == "Testcase") {
      $testcaseDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png border=0>";
    } else if ($sortBy == "Unit") {
      $unitDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png border=0>";
    } else {
      $timeDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png border=0>";
    } // if

    if (isset ($message)) {
      $page .= "<div align=center>$message</div>";
    } // if
  } else {
    $page .= "<h1 align=\"center\">Failure Analysis for $day</h1>";
  } // if

  $page .= <<<END
<table align=center width=90%>
  <thead>
END;

  if (!$forEmail) {
    $page .= <<<END
    <tr>
      <th class="clear" align="left"><a href="$script?action=Export&day=$day"><input type="submit" value="Export to CSV"></a></th>
      <th class="clear" colspan="2"
 align="right"><form action="$script?action=Mail&day=$day" method="post">
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
      <th class=left><a href="$urlParms=Testcase">Testcase&nbsp;$testcaseDirection</a></th>
      <th><a href="$urlParms=Unit">Unit&nbsp;$unitDirection</a></th>
      <th class=right><a href="$urlParms=Time">Time&nbsp;$timeDirection</a></th>
    </tr>
    <tr>
      <th width="100px">&nbsp;</th>
      <th>Teststep</th>
      <th>Failure Reason</th>
    </tr>
  </thead>
  <tbody>
END;

  foreach ($data as $result) {
    $row_color = " class=other";

    $unit = ($result["Unit"]) ? $result["Unit"] : "";
    $time = ($result["Time"]) ? $result["Time"] : "";

    $page .= <<<END
    <tr $row_color>
      <td><a href="rantest.php?testName=$result[Testcase]&runid=$result[_runid]&date=$result[Date]">$result[Testcase]</a></td>
      <td align=right>$unit</td>
      <td align=right>$time</td>
    </tr>
END;

    foreach ($result["Failures"] as $failure) {
      $step	= $failure["Step"];
      $reason	= $failure["Reason"];
      $page .= <<<END
    <tr class="failure">
      <td>&nbsp;</td>
      <td>$step</td>
      <td>$reason</td>
    </tr>
END;
    } // foreach
  } // foreach

  $page .= <<<END
  </tbody>
</table>
END;

  return $page;
} // createPage

function displayReport ($day, $message = "") {
  print createHeader	($day);
  print createPage	($day, false, $message);

  copyright ();
} // displayReport

function mailFailureAnalysisReport ($day, $pnbr, $username) {
  $subject	= "Failure Analysis for $day";
  $body		= createPage ($day, true);
  $filename	= "FailureAnalysis.$day.csv";
  $attachment	= createCSV ($day);

  return mailReport ($pnbr, $username, $subject, $body, $filename, $attachment);
} // mailFailureAnalysisReport

openDB ();

switch ($action) {
  case "Export":
    exportStats ($day);
    break;

  case "Mail":
    list ($pnbr, $username) = explode (":", $user);
    displayReport ($day, mailFailureAnalysisReport ($day, $pnbr, $username));
    break;

  default:
    displayReport ($day);
    break;
} // switch  
?>
</body>
</html>
