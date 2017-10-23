<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	TestcasePerVersion.php
// Revision:	1.2
// Description:	Produce a report of the testcases per version
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

$version	= $_REQUEST["version"];
$user		= $_REQUEST["user"];

$action		= (empty ($_REQUEST["action"]))    ? "Report"     : $_REQUEST["action"];
$type		= (empty ($_REQUEST["type"]))      ? "All" 	  : $_REQUEST["type"];
$sortBy		= (empty ($_REQUEST["sortBy"]))    ? "Start"       : $_REQUEST["sortBy"];
$direction	= (empty ($_REQUEST["direction"])) ? "descending" : $_REQUEST["direction"];

function getData ($version) {
  global $sortBy;

  $data = getTestcaseVersions ($version);

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
  } else {
    uasort ($data, "sortStart");
  } // if    

  return $data;
} // getData

function createHeader () {
  global $versionFor;

  $header = <<<END
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Testing.css">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Tables.css">
  <title>Testcases for $versionFor</title>
</head>

<body>
END;

  $header .= banner ();
  $header .= <<<END
<h1 align="center">Testcases for $versionFor</h1>
END;

  return $header;
} // createHeader

function createPage ($version, $forEmail = false, $message = "") {
  global $webdir, $direction, $sortBy, $script;

  $data = getData ($version);

  // Flip direction
  $direction = ($direction == "ascending") ? "descending" : "ascending";

  $urlParms  = "$script?version=$version&action=$action&direction=$direction&sortBy";

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
    } else {
      $startDirection = ($direction == "ascending") 
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
      <th class=clear align="left" colspan="2"><a href="$script?action=Export&version=$version"><input type="submit" value="Export to CSV"></a></th>
      <th class=clear align="right" colspan="8"><form action="$script?action=Mail&version=$version" method="post">
END;

    $page .= emailUsersDropdown ();
    $page .= <<<END
        <input type="submit" value="Send"></form>
      </th>
    </tr>
END;
  } // if

  $page .= <<<END
    <tr>
      <th class=left>#</th>
      <th><a href="$urlParms=Testcase">Testcase&nbsp;$testcaseDirection</a></th>
      <th><a href="$urlParms=Start">Start Date/Time&nbsp;$startDirection</a></th>
      <th><a href="$urlParms=Unit">Unit&nbsp;$unitDirection</a></th>
      <th><a href="$urlParms=Type">Type&nbsp;$typeDirection</a></th>
      <th><a href="$urlParms=Status">Status&nbsp;$statusDirection</a></th>
      <th class=right><a href="$urlParms=Duration">Duration&nbsp;$durationDirection</a></th>
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
      <td><a href="rantest.php?testName=$line[Testcase]&runid=$line[_runid]&start=$line[Start]">$line[Testcase]</a></td>
      <td align="center">$line[Start]</td>
      <td align="center">$line[Unit]</td>
      <td align="center">$line[Type]</td>
      <td align="center">$line[Status]</td>
      <td align="right">$duration</td>
    </tr>
END;
  } // foreach

  $page .= <<<END
  </tbody>
</table>
END;

  return $page;
} // createPage

function exportTestVersionsCSV ($version) {
  if (isset ($version)) {
    $title	= "Testcases for $version";
    $filename	= "Testcases." . $version . ".csv";
  } else {
    $title	= "Testcases for All Versions";
    $filename	= "Testcases for All Versionss.csv";
  } // if

  header ("Content-Type: application/octect-stream");
  header ("Content-Disposition: attachment; filename=\"$filename\"");

  print exportCSV (getData ($version), $title);

  exit;
} // exportTestVersionsCSV

function setVersion () {
  global $version;

  return (isset ($version)) ? $version : "All Versions";
} // setVersion

function displayReport ($version, $message = "") {
  print createHeader	();
  print createPage	($version, false, $message);

  copyright ();
} // displayReport

function mailTestVersionsReport ($version, $pnbr, $username) {
  if (isset ($version)) {
    $subject	= "Testcases for $version";
    $filename	= "Testcases." . $version . ".csv";
  } else {
    $subject	= "Test Versions for All Tests";
    $filename	= "Test Versions for All Tests.csv";
  } // if

  $body		= createPage ($version, true);
  $attachment	= exportCSV (getData ($version, true), $subject);

  return mailReport ($pnbr, $username, $subject, $body, $filename, $attachment);
} // mailTestVersionsReport

openDB ();

$versionFor = setVersion ();

switch ($action) {
  case "Export":
    exportTestVersionsCSV ($version);
    break;

  case "Mail":
    list ($pnbr, $username) = explode (":", $user);
    displayReport ($version, mailTestVersionsReport ($version, $pnbr, $username));
    break;

  default:
    displayReport ($version);
    break;
} // switch  
?>
</body>
</html>
