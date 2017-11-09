<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	AverageRunTime.php
// Revision:	1.2
// Description:	Produce a report of the average run time
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

$build	= $_REQUEST["build"];
$level	= $_REQUEST["level"];
$DUT	= $_REQUEST["DUT"];
$test	= $_REQUEST["test"];

if (!isset ($test) or ($test == "")) {
  $test = "%";
} // if

// Replace "*"'s with "%"'s
$build	= preg_replace ("/\*/", "%", $build);
$level	= preg_replace ("/\*/", "%", $level);
$DUT	= preg_replace ("/\*/", "%", $DUT);
$test	= preg_replace ("/\*/", "%", $test);

if ($build == "%" and
    $level == "%" and
    $DUT   == "%" and
    $test  == "%") {
  $testcase = "<All Tests>";
} else {
  $testcase  = "${build}_${level}_${DUT}_${test}";
} // if

$testname2 = preg_replace ("/%/", "*", $testcase);
?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Testing.css">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Tables.css">
  <title>Test history for <?php print ($testcase == "<All Tests>") ? "All Tests" : $testname2;?></title>

<body>

<h1 align="center">Test history for <?php print ($testcase == "<All Tests>") ? "All Tests" : $testname2;?></h1>

<?php
  if ($testcase == "<All Tests>") {
    print <<<END
<table align=center width=40%>
  <thead>
    <tr>
      <th class=left>#</th>
      <th>Test case</th>
      <th>Passed</th>
      <th>Failed</th>
      <th class=right>Total</th>
END;
  } else {
    print <<<END
<table align=center>
  <thead>
    <tr>
      <th class=left>#</th>
      <th>Test case</th>
      <th>Start</th>
      <th>End</th>
      <th>Logs</th>
      <th class=right>Result</th> 
END;
  } // if
?>
    </tr>
  </thead>
  <tbody>

<?php
OpenDB ();

$row_nbr = 0;

if ($testcase == "<All Tests>") {
  $statement = <<<END
select
  test.name 		as testname,
  count(*)		as count,
  status.name		as status
from
  testruns,
  status,
  test
where
  test.id = testruns.tcid	and 
  testruns.statusid = status.id
group by
  testname,
  status
END;

  $result = mysql_query ($statement)
    or DBError ("Unable to execute query: ", $statement);

  $lastTestcase = "unknown";

  $passed  = 0;
  $failed  = 0;

  while ($row = mysql_fetch_array ($result)) {
    $logs = logs ($row["eastlogs"]);

    if ($row["testcase"] == $lastTestcase) {
      if ($row["status"] == "Success") {
         $passed = $row["count"];
      } else {
         $failed = $row["count"];
      } // if

      $row_color = ($row_nbr++ % 2 == 0) ? " class=other" : "";

      $total = $passed + $failed;

      print <<<END
        <tr $row_color>
          <td align=center>$row_nbr</td>
          <td><a href="$script?testcase=$row[testname]">$row[testname]</a></td>
          <td align=right>$passed</td>
          <td align=right>$failed</td>
          <td align=right>$total</td>
      </tr>
END;
      $lastTestcase = "unknown";

      $passed = 0;
      $failed = 0;
    } else {
      $lastTestcase = $row["testcase"];

      if ($row["status"] == "Success") {
         $passed = $row["count"];
      } else {
         $failed = $row["count"];
      } // if
    } // if
  } // while
} else {
  $statement = <<<END
select
  testruns.runid	as runid,
  testrun.start		as start,
  testruns.end		as end,
  test.name		as testname,
  status.name		as status,
  testruns.eastlogs	as eastlogs
from
  testrun,
  testruns,
  status,
  test
where
  test.name 		like "$testcase"	and
  test.id		= testruns.tcid		and
  testrun.id		= testruns.runid	and
  testruns.statusid	= status.id
order by
  left(start,10) desc,
  testname
END;

  $result = mysql_query ($statement)
    or DBError ("Unable to execute query: ", $statement);

  while ($row = mysql_fetch_array ($result)) {
    $class  = SetRowColor ($row["status"]);
    $status = colorResult ($row["status"]);
    $date   = YMD2MDY (substr ($row["start"], 0, 10));

    $row_nbr++;
    $logs = logs ($row["eastlogs"]);

    print <<<END
      <tr $class>
        <td align=center>$row_nbr</td>
        <td><a href="/rantest.php?testName=$row[testname]&runID=$row[runid]&date=$date">$row[testname]</a></td>
        <td align=center>$row[start]</td>
        <td align=center>$row[end]</td>
        <td>$logs</td>
        <td>$status</td>
      </tr>
END;
   } // while
}// if

print <<<END
  </tbody>
</table>
END;

copyright ();
?>
</body>
</html>

