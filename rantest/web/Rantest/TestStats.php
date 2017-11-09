<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	TestStats.php
// Revision:	1.2
// Description:	Produce a report or chart of the test statistics
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

$start		= $_REQUEST["start"];
$end		= $_REQUEST["end"];
$user		= $_REQUEST["user"];

$action		= (empty ($_REQUEST["action"]))    ? "Report"     : $_REQUEST["action"];
$type		= (empty ($_REQUEST["type"]))      ? "All" 	  : $_REQUEST["type"];
$sortBy		= (empty ($_REQUEST["sortBy"]))    ? "Date"       : $_REQUEST["sortBy"];
$direction	= (empty ($_REQUEST["direction"])) ? "descending" : $_REQUEST["direction"];

function getData ($start, $end) {
  global $sortBy;

  $data = getStatus ($start, $end);

  // Sort data
  if ($sortBy == "Passed") {
    uasort ($data, "sortSuccess");
  } elseif ($sortBy == "Failed") {
    uasort ($data, "sortFailure");
  } elseif ($sortBy == "Total") {
    uasort ($data, "sortTotal");
  } else {
    uasort ($data, "sortDate");
  } // if

  return $data;
} // getData

function exportStats ($start, $end) {
  $title	= "Test Statistics from $start to $end";
  $filename	= "Test Statistics." . $start . "." . $end . ".csv";

  header ("Content-Type: application/octect-stream");
  header ("Content-Disposition: attachment; filename=\"$filename\"");

  print exportCSV (getData ($start, $end), $title);

  exit;
} // exportStats

function createHeader () {
  global $start, $end;

  $header = <<<END
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Testing.css">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Tables.css">
  <title>Test Statistics from $start to $end></title>
</head>
<body>
END;

  $header .= banner ();
  $header .= <<<END
<h1 align="center">Test Statistics from $start to $end</h1>
END;

  return $header;
} // createHeader

function CreatePage ($start, $end, $forEmail = false, $message = "") {
  global $sortBy, $direction, $script;

  $data = getData ($start, $end);

  $row_nbr = 0;

  if (!$forEmail) {
    // Flip direction
    $direction = ($direction == "ascending") ? "descending" : "ascending";
    $urlParms  = "$script?start=$start&end=$end&action=$action&direction=$direction&sortBy";

    if ($sortBy == "Passed") {
      $passedDirection = ($direction == "ascending") 
	? "<img src=/images/down.png align=absmiddle border=0>"
	: "<img src=/images/up.png border=0>";
    } elseif ($sortBy == "Failed") {
      $failedDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png align=absmiddle border=0>";
    } elseif ($sortBy == "Total") {
      $totalDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png align=absmiddle border=0>";
    } else {
      $dateDirection = ($direction == "ascending") 
	? "<img src=/images/down.png border=0>"
	: "<img src=/images/up.png align=absmiddle border=0>";
    } // if

    if (isset ($message)) {
      $page .= "<div align=center>$message</div>";
    } // if
  } // if

  $page .= <<<END
<table align=center width=60%>
  <thead>
END;

  if (!$forEmail) {
    $page .= <<<END
    <tr>
      <th class=clear align="left" colspan="2"><a href="$script?action=Export&start=$start&end=$end"><input type="submit" value="Export to CSV"></a>&nbsp;<a href="$script?action=Graph&start=$start&end=$end"><input type="submit" value="Graph"></a></th>
      <th class=clear align="right" colspan="2"><form action="$script?action=Mail&start=$start&end=$end" method="post">
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
      <th class=left><a href="$urlParms=Date">Date&nbsp;$dateDirection</a></th>
      <th><a href="$urlParms=Passed">Total Passed&nbsp;$passedDirection</a></th>
      <th><a href="$urlParms=Failed">Total Failed&nbsp;$failedDirection</a></th>
      <th class=right><a href="$urlParms=Total">Total Run&nbsp;$totalDirection</a></th>
    </tr>
  </thead>
  <tbody>
END;

  foreach ($data as $result) {
    $reportDate = YMD2MDY ($result["Date"]);
    $row_color = ($row_nbr++ % 2 == 0) ? " class=other" : " class=white";

    $page .= <<<END
    <tr $row_color>
      <td align=center><a href="rantest.php?day=$reportDate">$reportDate</a></td>
      <td align=right>$result[Success]</td>
      <td align=right>$result[Failure]</td>
      <td align=right>$result[Total]</td>
    </tr>
END;
  } // foreach

  $page .= <<<END
  </tbody>
</table>
END;

  return $page;
} // CreatePage

function displayReport ($start, $end, $message = "") {
  print createHeader	($start, $end);
  print createPage	($start, $end, false, $message);

  copyright ();
} // displayReport

function displayChart ($start, $end) {
  global $testTypes, $type;

  print createHeader ($start, $end);

  $days = getdays();

  print <<<END
    <div align="center">
      <form action="TestStats.php">
      Type: <select name="type" class="inputfield">
END;

    foreach ($testTypes as $t) {
      if ($type != $t) {
	print "<option>$t</option>";
      } else {
	print "<option selected=\"selected\">$t</option>";
      } // if
    } // foreach

  print <<<END
    </select>
    From:
        <select name=start class=inputfield>
END;

  foreach ($days as $day) {
    print "<option";

    if ($day == $start) {
      print " selected=selected";
    } // if

    print ">$day</option>\n";
  } // foreach

  print <<<END
        </select> To: 
        <select name=end class=inputfield>
END;

  foreach ($days as $day) {
    print "<option";

    if ($day == $end) {
      print " selected=selected";
    } // if

    print ">$day</option>\n";
  } // foreach

  print <<<END
        </select>
          <input type=submit name="action" value="Graph">&nbsp;<a href="$script?action=Report&start=$start&end=$end"><input type="submit" value="Report"></a><br><br>
      </form>
        <img src="GraphStats.php?start=$start&end=$end&type=$type">
    </div>
END;

  copyright ();
} // displayChart

function mailTestStatsReport ($start, $end, $pnbr, $username) {
  $subject	= "Test Statistics from $start to $end";
  $filename	= "TestStats.$start-$end.csv";
  $body		= createPage ($start, $end, true);
  $attachment	= exportCSV (getData ($start, $end), $subject);

  return mailReport ($pnbr, $username, $subject, $body, $filename, $attachment);
} // mailReport

if (MDY2YMD ($start) > MDY2YMD ($end)) {
  Error ("<b>Start Date</b> must come before <b>End Date</b>");
  return;
} // if

openDB ();

switch ($action) {
  case "Graph":
    displayChart ($start, $end);
    break;

  case "Export":
    exportStats ($start, $end);
    break;

  case "Mail":
    list ($pnbr, $username) = explode (":", $user);
    displayReport ($start, $end, mailTestStatsReport ($start, $end, $pnbr, $username));
    break;

  default:
    displayReport ($start, $end);

    break;
} // switch  
?>
</body>
</html>
