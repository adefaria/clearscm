<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	VersionPerTestcase.php
// Revision:	1.2
// Description:	Produce a report of versions per testcase
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

$testcase	= $_REQUEST["testcase"];
$user		= $_REQUEST["user"];

$build		= (empty ($_REQUEST["build"]))	   ? "*"         : $_REQUEST["build"];
$level		= (empty ($_REQUEST["level"]))     ? "*"         : $_REQUEST["level"];
$DUT		= (empty ($_REQUEST["DUT"]))       ? "*"         : $_REQUEST["DUT"];
$test		= (empty ($_REQUEST["test"]))      ? "*"         : $_REQUEST["test"];

$action		= (empty ($_REQUEST["action"]))    ? "Report"     : $_REQUEST["action"];
$type		= (empty ($_REQUEST["type"]))      ? "All" 	  : $_REQUEST["type"];
$sortBy		= (empty ($_REQUEST["sortBy"]))    ? "Date"       : $_REQUEST["sortBy"];
$direction	= (empty ($_REQUEST["direction"])) ? "descending" : $_REQUEST["direction"];

$historyFor	= setTestcase ($testcase);

// Sorting functions
function sortVersion ($a, $b) {
  global $direction;

  return cmpStr ($a, $b, "Version", $direction);
} // sortUnitVersion

function getData ($testcase) {
  global $sortBy;

  $data = getTestVersions ($testcase);

  // Sort data
  if ($sortBy == "Testcase") {
    uasort ($data, "sortTestcase");
  } elseif ($sortBy == "Unit") {
    uasort ($data, "sortUnit");
  } elseif ($sortBy == "Type") {
    uasort ($data, "sortType");
  } elseif ($sortBy == "Status") {
    uasort ($data, "sortStatus");
  } elseif ($sortBy == "Duration") {
    uasort ($data, "sortDuration");
  } elseif ($sortBy == "Version") {
    uasort ($data, "sortVersion");
  } else {
    uasort ($data, "sortDate");
  } // if    

  return $data;
} // getData

function createHeader () {
  global $historyFor;

  $header = <<<END
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Testing.css">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Tables.css">
  <title>Test Versions for $historyFor</title>
</head>

<body>
END;

  $header .= banner ();
  $header .= <<<END
<h1 align="center">Test Versions for $historyFor</h1>
END;

  return $header;
} // createHeader

function createPage ($testcase, $forEmail = false, $message = "") {
  global $webdir, $direction, $sortBy, $script;
  global $build, $level, $DUT, $test;

  $data = getData ($testcase);

  // Flip direction
  $direction = ($direction == "ascending") ? "descending" : "ascending";

  if (isset ($testcase)) {
    $urlParms  = "$script?testcase=$testcase&action=$action&direction=$direction&sortBy";
  } else {
    $urlParms  = "$script?build=$build&level=$level&DUT=$DUT&test=$test&action=$action&direction=$direction&sortBy";
  } // if

  if (!$forEmail) {
    if ($sortBy == "Testcase") {
      $testcaseDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "Unit") {
      $unitDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "Type") {
      $typeDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "Status") {
      $statusDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "Duration") {
      $durationDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "Version") {
      $versionDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png border=0>";
    } else {
      $dateDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png border=0>";
    } // if
      
    if (isset ($message)) {
      $page .= "<div align=\"center\">$message</div>";
    } // if
  } // if

  $page .= <<<END
<table align="center" width="90%">
  <thead>
END;

  if (!$forEmail) {
    $page .= <<<END
    <tr>
      <th class=clear align="left" colspan="2"><a href="$script?action=Export&testcase=$testcase"><input type="submit" value="Export to CSV"></a></th>
      <th class=clear align="right" colspan="6"><form action="$script?action=Mail&testcase=$testcase" method="post">
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
      <th class=left>#</th>
      <th><a href="$urlParms=Testcase">Testcase&nbsp;$testcaseDirection</a></th>
      <th><a href="$urlParms=Date">Start Date/Time&nbsp;$dateDirection</a></th>
      <th><a href="$urlParms=Unit">Unit&nbsp;$unitDirection</a></th>
      <th><a href="$urlParms=Type">Type&nbsp;$typeDirection</a></th>
      <th><a href="$urlParms=Status">Status&nbsp;$statusDirection</a></th>
      <th><a href="$urlParms=Duration">Duration&nbsp;$durationDirection</a></th>
      <th class=right><a href="$urlParms=Version">Version&nbsp;$versionDirection</a></th>
    </tr>
  </thead>
  <tbody>
END;

  foreach ($data as $line) {
    $row_nbr++;
    $row_color		= setRowColor ($line["Status"]);
    $line["Status"]	= colorResult ($line["Status"]);
    $duration		= FormatDuration ($line["Duration"]);

    $page .= <<<END
    <tr $row_color>
      <td align="center">$row_nbr</td>
      <td><a href="rantest.php?testName=$line[Testcase]&runid=$line[_runid]&date=$reportDate">$line[Testcase]</a></td>
      <td align="center">$line[Start]</td>
      <td align="center">$line[Unit]</td>
      <td align="center">$line[Type]</td>
      <td align="center">$line[Status]</td>
      <td align="right">$duration</td>
      <td align="center">$line[Version]</td>
    </tr>
END;
  } // foreach

  $page .= <<<END
  </tbody>
</table>
END;

  return $page;
} // createPage

function exportTestVersionsCSV ($testcase) {
  global $historyFor;

  if (isset ($testcase)) {
    $title	= "Test Versions for $historyFor";
    $filename	= "Test Versions." . $testcase . ".csv";
  } else {
    $title	= "Test Versions for All Tests";
    $filename	= "Test Versions for All Tests.csv";
  } // if

  // Protect $filename from wildcards
  $filename = preg_replace ("/\*/", "%", $filename);

  header ("Content-Type: application/octect-stream");
  header ("Content-Disposition: attachment; filename=\"$filename\"");

  print exportCSV (getData ($testcase), $title);

  exit;
} // exportTestHistoryCSV

function setTestcase () {
  global $testcase, $build, $level, $DUT, $test;

  if (empty ($testcase)) {
    if (empty ($test)) {
      $test = "*";
    } // if

    if ($build == "*" and
	$level == "*" and
	$DUT   == "*" and
	$test  == "*") {
      unset ($testcase);
      return "All Tests";
    } else {
      $testcase  = "${build}_${level}_${DUT}_${test}";
    } // if
  } // if

  return $testcase;
} // setTestcase

function displayReport ($testcase, $message = "") {
  print createHeader	();
  print createPage	($testcase, false, $message);

  copyright ();
} // displayReport

function mailTestVersionsReport ($testcase, $pnbr, $username) {
  global $historyFor;

  if (isset ($testcase)) {
    $subject	= "Test Versions for $historyFor";
    $filename	= "Test Versions." . $testcase . ".csv";
  } else {
    $subject	= "Test Versions for All Tests";
    $filename	= "Test Versions for All Tests.csv";
  } // if

  // Protect $filename from wildcards
  $filename = preg_replace ("/\*/", "%", $filename);

  $body		= createPage ($testcase, true);
  $attachment	= exportCSV (getData ($testcase, true), $subject);

  return mailReport ($pnbr, $username, $subject, $body, $filename, $attachment);
} // mailTestVersionsReport

openDB ();

$historyFor = setTestcase ();

switch ($action) {
  case "Export":
    exportTestVersionsCSV ($testcase);
    break;

  case "Mail":
    list ($pnbr, $username) = explode (":", $user);
    displayReport ($testcase, mailTestVersionsReport ($testcase, $pnbr, $username));
    break;

  default:
    displayReport ($testcase);
    break;
} // switch  
?>
</body>
</html>
