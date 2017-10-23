<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	TestHistory.php
// Revision:	1.2
// Description:	Produce a historical report about a testcase
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
function sortDUT ($a, $b) {
  global $direction;

  return cmpStr ($a, $b, "DUT", $direction);
} // sortDUT

function sortAvgRunTime ($a, $b) {
  global $direction;

  return cmpNbr ($a, $b, "AvgRunTime", $direction);
} // sortAvgRunTime

function getData ($testcase) {
  global $sortBy;

  $data = getTestHistory ($testcase);

  // Sort data
  if ($sortBy == "Passed") {
    uasort ($data, "sortPassed");
  } elseif ($sortBy == "Failed") {
    uasort ($data, "sortFailed");
  } elseif ($sortBy == "Total") {
    uasort ($data, "sortTotal");
  } elseif ($sortBy == "AvgRunTime") {
    uasort ($data, "sortAvgRunTime");
  } elseif ($sortBy == "DUT") {
    uasort ($data, "sortDUT");
  } elseif ($sortBy == "Type") {
    uasort ($data, "sortType");
  } elseif ($sortBy == "Start") {
    uasort ($data, "sortStart");
  } elseif ($sortBy == "End") {
    uasort ($data, "sortEnd");
  } elseif ($sortBy == "Duration") {
    uasort ($data, "sortDuration");
  } elseif ($sortBy == "Status") {
    uasort ($data, "sortStatus");
  } else {
    uasort ($data, "sortTestcase");
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
  <title>Test history for $historyFor</title>
</head>

<body>
END;

  $header .= banner ();
  $header .= <<<END
<h1 align="center">Test history for $historyFor</h1>
END;

  return $header;
} // createHeader

function createPage ($testcase, $forEmail = false, $message = "") {
  global $webdir, $direction, $sortBy, $script;

  $data = getData ($testcase);

  if (!$forEmail) {
    // Flip direction
    $direction = ($direction == "ascending") ? "descending" : "ascending";

    if ($sortBy == "DUT") {
      $DUTDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "Type") {
      $typeDirection = ($direction == "ascending") 
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
    } elseif ($sortBy == "Status") {
      $statusDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "Passed") {
      $passedDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "Failed") {
      $failedDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "Total") {
      $totalDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "AvgRunTime") {
      $avgRunTimeDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png border=0>";
    } else {
      $testcaseDirection = ($direction == "ascending") 
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
    if (isset ($testcase)) {
      $page .= <<<END
    <tr>
      <th class=clear align="left" colspan="2"><a href="$script?action=Export&testcase=$testcase"><input type="submit" value="Export to CSV"></a></th>
      <th class=clear align="right" colspan="7"><form action="$script?action=Mail&testcase=$testcase" method="post">
END;
    } else {
      $page .= <<<END
    <tr>
      <th class=clear align="left" colspan="2"><a href="$script?action=Export&testcase=$testcase"><input type="submit" value="Export to CSV"></a></th>
      <th class=clear align="right" colspan="4"><form action="$script?action=Mail&testcase=$testcase" method="post">
END;
    } // if

    $page .= emailUsersDropdown ();
    $page .= <<<END
        </select>
        <input type="submit" value="Send"></form>
      </th>
    </tr>
END;
  } // if

  if (isset ($testcase)) {
    $urlParms  = "$script?testcase=$testcase&action=$action&direction=$direction&sortBy";
    $page .= <<<END
    <tr>
      <th class=left>#</th>
      <th><a href=$urlParms=Testcase>Testcase&nbsp;$testcaseDirection</a></th>
      <th><a href=$urlParms=DUT>DUT&nbsp;$DUTDirection</a></th>
      <th><a href=$urlParms=Type>Type&nbsp;$typeDirection</a></th>
      <th><a href=$urlParms=Start>Start&nbsp;$startDirection</a></th>
      <th><a href=$urlParms=End>End&nbsp;$endDirection</a></th>
      <th><a href=$urlParms=Duration>Duration&nbsp;$durationDirection</a></th>
      <th>Logs</th>
      <th class=right><a href=$urlParms=Status>Status&nbsp;$statusDirection</a></th> 
END;
  } else {
    $urlParms  = "$script?build=$build&level=$level&DUT=$DUT&test=$test&action=$action&direction=$direction&sortBy";
    $page .= <<<END
    <tr>
      <th class=left>#</th>
      <th><a href=$urlParms=Testcase>Testcase&nbsp;$testcaseDirection</a></th>
      <th><a href=$urlParms=Passed>Passed&nbsp;$passedDirection</a></th>
      <th><a href=$urlParms=Failed>Failed&nbsp;$failedDirection</a></th>
      <th><a href=$urlParms=Total>Total&nbsp;$totalDirection</a></th>
      <th class=right><a href=$urlParms=AvgRunTime>Avg Run Time&nbsp;$avgRunTimeDirection</a></th>
END;
  } // if

  $page .= <<<END
    </tr>
  </thead>
  <tbody>
END;

  $total_passed =
  $total_failed =
  $total_total	= 0;

  foreach ($data as $line) {
    $row_nbr++;

    if (isset ($testcase)) {
      $class	= SetRowColor ($line["Status"]);
      $status	= colorResult ($line["Status"]);
      $date	= YMD2MDY (substr ($line["Start"], 0, 10));
      $duration	= FormatDuration ($line["Duration"]);
      $logs	= logs ($line["_eastlogs"]);

      $page .= <<<END
      <tr $class>
        <td align=center>$row_nbr</td>
        <td><a href="$webdir/rantest.php?testName=$line[Testcase]&runid=$line[_runid]&date=$date">$line[Testcase]</a></td>
        <td align=center>$line[DUT]</td>
        <td align=center>$line[Type]</td>
        <td align=center>$line[Start]</td>
        <td align=center>$line[End]</td>
        <td>$duration</td>
        <td align=center>$logs</td>
        <td>$status</td>
      </tr>
END;
    } else {
      $row_color = ($row_nbr % 2 == 0) ? " class=other" : " class=white";

      $page .= <<<END
        <tr $row_color>
          <td align=center>$row_nbr</td>
          <td><a href="$script?testcase=$line[Testcase]">$line[Testcase]</a></td>
          <td align=right>$line[Passed]</td>
          <td align=right>$line[Failed]</td>
          <td align=right>$line[Total]</td>
	  <td align=right>
END;
      $page .= FormatDuration ($line[AvgRunTime]);
      $page .= "</td></tr>";
      $total_passed	+= $line["Passed"];
      $total_failed	+= $line["Failed"];
      $total_total	+= $line["Total"];
    } // if
  } // foreach  

  // Print total
  if (empty ($testcase)) {
    $page .= <<<END
  <tfoot>
    <tr $row_color>
      <th colspan=2>Total</th>
      <th align=right>$total_passed</th>
      <th align=right>$total_failed</th>
      <th align=right>$total_total</th>
      <th>&nbsp;</th>
    </tr>
  </tfoot>
END;
  } // if

  $page .= <<<END
  </tbody>
</table>
END;

  return $page;
} // createPage

function exportTestHistoryCSV ($testcase) {
  global $historyFor;

  if (isset ($testcase)) {
    $title	= "Test History for $historyFor";
    $filename	= "Test History." . $testcase . ".csv";
  } else {
    $title	= "Test History for All Tests";
    $filename	= "Test History.All Tests.csv";
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
  print createHeader ();
  print createPage   ($testcase, false, $message);

  copyright ();
} // displayReport

function mailTestHistoryReport ($testcase, $pnbr, $username) {
  global $historyFor;

  if (isset ($testcase)) {
    $subject	= "Test History for $historyFor";
    $filename	= "Test History." . $testcase . ".csv";
  } else {
    $subject	= "Test History for All Tests";
    $filename	= "Test History.All Tests.csv";
  } // if

  // Protect $filename from wildcards
  $filename = preg_replace ("/\*/", "%", $filename);

  $body		= createPage ($testcase, true);
  $attachment	= exportCSV (getData ($testcase, true), $subject);

  return mailReport ($pnbr, $username, $subject, $body, $filename, $attachment);
} // mailTestHistoryReport

openDB ();

$historyFor = setTestcase ();

switch ($action) {
  case "Export":
    exportTestHistoryCSV ($testcase);
    break;

   case "Mail":
     list ($pnbr, $username) = explode (":", $user);
     displayReport ($testcase, mailTestHistoryReport ($testcase, $pnbr, $username));
     break;

  default:
    displayReport ($testcase);
    break;
} // switch  
?>
</body>
</html>
