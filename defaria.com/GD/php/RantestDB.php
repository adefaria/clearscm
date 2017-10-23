<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	RantestDB.php
// Revision:	1.0
// Description:	PHP Module to access the rantest database
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
include_once ("Utils.php");

// DEBUG Flag
$debug = 1;

// Read only access
$userid		= "pswitreader";
$password	= "reader";
$dbserver	= "seast1";
$dbname		= "rantest";

$sortBy		= (empty ($_REQUEST["sortBy"]))    ? "Start"        : $_REQUEST["sortBy"];
$direction	= (empty ($_REQUEST["direction"])) ? "descending"   : $_REQUEST["direction"];
$day		= (empty ($_REQUEST["day"]))	   ? date ("m/d/Y") : $_REQUEST["day"];

// N/A
$na = "<font color=#999999>N/A</font>";

$failureTypes = array (
  "Aborted",
  "Exit",
  "Incomplete",
  "Other",
  "p2pDataVal",
  "Parsing",
  "Timed out",
  "valMsgs.pl"
);

$nonFailures = array (
  "Success",
  "In progress",
  "Logging started"
);

$testTypes = array (
  "All",
  "Normal",
  "Regression",
  "Run for Record"
);

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
  global $dbserver;
  global $userid;
  global $password;
  global $dbname;

  $db = mysql_connect ($dbserver, $userid, $password)
    or dbError (__FUNCTION__ . ": Unable to connect to database server $dbserver", "Connect");

  mysql_select_db ($dbname)
    or dbError (__FUNCTION__ . ": Unable to select the $dbname database", "$dbname");
} // openDB

function getDays () {
  $days = array ();

  $statement = "select start from testrun group by left (start, 10) order by start desc";

  $result = mysql_query ($statement)
    or dbError (__FUNCTION__ . ": Unable to execute query: ", $statement);

  while ($row = mysql_fetch_array ($result)) {
    array_push ($days, YMD2MDY ($row["start"]));
  } // while

  return $days;
} // getDays

function setRowColor ($result) {
  if ($result == "Success") {
    return " class=success";
  } elseif ($result == "Failure") {
    return " class=failure";
  } elseif ($result == "Timed out") {
    return " class=timed_out";
  } elseif ($result == "In progress" ||
             $result == "Logging started") {
    return " class=in_progress";
  } else {
    return " class=white";
  } // if
} // setRowColor

function colorResult ($result) {
  if ($result == "Success") {
    return "<b><font color=green>$result</b></font>";
  } elseif ($result == "Failure") {
    return "<b><font color=red>$result</b></font>";
  } else {
    return $result;
  } // if
} // colorResult

function sortPassed ($a, $b) {
  global $direction;

  return cmpNbr ($a, $b, "Passed", $direction);
} // sortPassed

function sortFailed ($a, $b) {
  global $direction;

  return cmpNbr ($a, $b, "Failed", $direction);
} // sortFailed

function sortSuccess ($a, $b) {
  global $direction;

  return cmpNbr ($a, $b, "Success", $direction);
} // sortSuccess

function sortFailure ($a, $b) {
  global $direction;

  return cmpNbr ($a, $b, "Failure", $direction);
} // sortFailure

function sortTotal ($a, $b) {
  global $direction;

  return cmpNbr ($a, $b, "Total", $direction);
} // sortTotal

function sortSuite ($a, $b) {
  global $direction;

  return cmpStr ($a, $b, "Suite", $direction);
} // sortSuite

function sortStart ($a, $b) {
  global $direction;

  return cmpStr ($a, $b, "Start", $direction);
} // sortStart

function sortDate ($a, $b) {
  global $direction;

  return cmpStr ($a, $b, "Date", $direction);
} // sortDate

function sortEnd ($a, $b) {
  global $direction;

  return cmpStr ($a, $b, "End", $direction);
} // sortEnd

function sortTestcase ($a, $b) {
  global $direction;

  return cmpStr ($a, $b, "Testcase", $direction);
} // sortTestcase

function sortType ($a, $b) {
  global $direction;

  return cmpStr ($a, $b, "Type", $direction);
} // sortType

function sortUnitVersion ($a, $b) {
  global $direction;

  return cmpStr ($a, $b, "Unit/Version", $direction);
} // sortUnitVersion

function sortUnit ($a, $b) {
  global $direction;

  return cmpStr ($a, $b, "Unit", $direction);
} // sortUnit

function sortStatus ($a, $b) {
  global $direction;

  return cmpStr ($a, $b, "Status", $direction);
} // sortStatus

function sortDuration ($a, $b) {
  global $direction;

  return cmpNbr ($a, $b, "Duration", $direction);
} // sortDuration

function getName ($table, $id) {
  $statement = "select name from $table where id=$id";

  $result = mysql_query ($statement)
    or dbError (__FUNCTION__ . ": Unable to execute query: ", $statement);

  $row = mysql_fetch_array ($result);

  return $row["name"];
} // getName

function getTestNames () {
  $statement = "select name from test order by name";

  $result = mysql_query ($statement)
    or dbError (__FUNCTION__ . ": Unable to execute query: ", $statement);

  $names = array ("&lt;All Tests&gt;");

  while ($row = mysql_fetch_array ($result)) {
    array_push ($names, $row["name"]);
  } // while

  return $names;
} // getTestNames

function getBuildNbr ($runid) {
  global $na;

  $statement = "select name from version where type=\"ran_version\" and runid=$runid";

  $result = mysql_query ($statement)
    or dbError (__FUNCTION__ . ": Unable to execute query: ", $statement);

  $row = mysql_fetch_array ($result);

  if (isset ($row["name"])) {
    $buildNbr = preg_replace ("/.*\-(\w+)/", "$1", $row["name"]);
    return $buildNbr;
  } else {
    return $na;
  } // if
} // getBuildNbr

function getVersion ($type, $runid) {
  global $na;

  $statement = "select name from version where type=\"$type\" and runid=$runid";

  $result = mysql_query ($statement)
    or dbError (__FUNCTION__ . ": Unable to execute query: ", $statement);

  $row = mysql_fetch_array ($result);

  if (isset ($row["name"])) {
    return $row["name"];
  } else {
    return $na;
  } // if
} // getVersion

function getVersions ($type) {
  $statement = "select name from version where type=\"$type\" group by name";

  $result = mysql_query ($statement)
    or dbError (__FUNCTION__ . ": Unable to execute query: ", $statement);

//  $names = array ("&lt;All Versions&gt;");
  $names = array ();

  while ($row = mysql_fetch_array ($result)) {
    array_push ($names, $row["name"]);
  } // while

  return $names;
} // getVersions

function getTestVersions ($testcase) {
  if (isset ($testcase)) {
    $testcase = preg_replace ("/\*/", "%", $testcase);
    $condition = "and test.name like \"$testcase\"";
  } else {
    $condition = "";
  } // if

  $statement = <<<END
select
  testruns.runid	as runid,
  testrun.start		as start,
  testruns.end		as end,
  testruns.unit		as unit,
  testruns.exectype	as type,
  test.name		as testcase,
  status.name		as status,
  testruns.eastlogs	as eastlogs,
  version.name		as version
from
  testrun,
  testruns,
  status,
  test,
  version
where
  version.runid		= testruns.runid	and
  test.id		= testruns.tcid		and
  testrun.id		= testruns.runid	and
  testruns.statusid	= status.id		and
  version.type		= "ran_version"
$condition
END;

  $result = mysql_query ($statement)
    or DBError ("Unable to execute query: ", $statement);

  $data = array ();

  while ($row = mysql_fetch_array ($result)) {
    $line["Testcase"]	= $row["testcase"];
    $line["Start"]	= $row["start"];
    $line["Version"]	= $row["version"];
    $line["End"]	= $row["end"];
    $line["Unit"]	= $row["unit"];
    $line["Type"]	= $row["type"];
    $line["Status"]	= $row["status"];
    $line["Duration"]	= strtotime ($row["end"]) - strtotime ($row["start"]);
    $line["Version"]	= $row["version"];
    $line["_eastlogs"]	= $row["eastlogs"];
    $line["_runid"]	= $row["runid"];

    array_push ($data, $line);
  } // while

  return $data;
} // getTestVersions

function getLatestDate () {
  $statement = "select left (start,10) as start from testrun order by start desc limit 0,1";

  $result = mysql_query ($statement)
    or dbError (__FUNCTION__ . ": Unable to execute query: ", $statement);

  $row = mysql_fetch_array ($result);

  return $row["start"];
} // getLastestDate

function getEarliestDate () {
  $statement = "select left (start,10) as start from testrun order by start limit 0,1";

  $result = mysql_query ($statement)
    or dbError (__FUNCTION__ . ": Unable to execute query: ", $statement);

  $row = mysql_fetch_array ($result);

  return $row["start"];
} // getLastestDate

function reportDateDropdown () {
  global $script, $day;

  $days = getDays ();

  $dateDropdown .= "<select name=day class=inputfield onChange=\"ChangeDay(this.value,'$script');\">";

  if (count ($days) < 2) {
    $day = $days[0];
  } elseif (!isset ($day)) {
    $day = date ("m/d/Y");
  } // if

  foreach ($days as $d) {
    $dateDropdown .= "<option";

    if ($d == $day) {
      $dateDropdown .= " selected=\"selected\"";
    } // if

    $dateDropdown .= ">$d</option>";
  } // foreach

  $dateDropdown .= "</select>";

  return $dateDropdown;
} // reportDateDropdown

function stats ($date = "", $type = "") {
  if (empty ($date)) {
    $date = getLatestDate ();
  } else {
    $date = MDY2YMD ($date);
  } // if

  if (empty ($type)) {
    $type = "All";
  } // if

  $typecond	= ($type == "All") ? "" : "exectype = \"$type\" and";

  $statement = <<<END
select
  count(*)	as count,
  status.name	as result
from 
  testrun,
  testruns,
  status
where
  left (start,10)	= "$date"		and
  $typecond
  testrun.id		= testruns.runid	and
  testruns.statusid	= status.id
group by
  statusid
END;

  $result = mysql_query ($statement)
    or dbError (__FUNCTION__ . ": Unable to execute query: ", $statement);

  while ($row = mysql_fetch_array ($result)) {
    if ($row["count"] == 0) {
       $stats .= "No $row[result] ";
    } elseif ($row["count"] == 1) {
       $stats .= "1 $row[result] ";
    } else {
      if ($row["result"] == "Failure") {
       $stats .= "$row[count] Failures ";
      } else {
        $stats .= "$row[count] Successes ";
      } // if
    } // if
  } // while

  return $stats;
} // stats

function logs ($logs, $forEmail = false) {
  global $na;

  if (file_exists ($logs)) {
    if ($forEmail) {
      return "Yes";
    } else {
      // Chop off "/east/seast1"
      $logs = substr ($logs, 12);
      return "<a href=\"$logs\"><img border=0 src=\"/images/log.png\" height=20 title=\"Browse to logfiles\"></a>";
    } // if
  } else {
    if ($forEmail) {
      return "No";
    } else {
      return "<img border=0 src=\"/icons/broken.png\" height=20 title=\"Unable to find log file for this test execution - Perhaps the logfiles have aged away\">";
      return $na;
    } // if
  } // if
} # logs

function getStatus ($startDate, $endDate, $type = "") {
  $dateCond = "";

  if (isset ($startDate)) {
    $startDate	= MDY2YMD ($startDate);
  } // if

  if (isset ($endDate)) {
    $endDate	= MDY2YMD ($endDate);
  } // if

  if (isset ($startDate) and isset ($endDate)) {
    $dateCond = "and left (testrun.start, 10) >= \"$startDate\" " .
                "and left (testruns.end,  10) <= \"$endDate\"" ;
  } elseif ($startDate) {
    $dateCond = "and left (testrun.start, 10) >= \"$startDate\"";
  } elseif ($endDate) {
    $dateCond = "and left (testruns.end,  10) <= \"$endDate\"";
  } # if

  $exectypeCond = "";

  if ($type != "" and $type != "All") {
    $exectypeCond = "and testruns.exectype = \"$type\"";
  } // if

  $statement = <<<END
select
  status.name			as status,
  left (testrun.start,10)	as date
from
  test,
  status,
  testrun,
  testruns
where
  test.id			= testruns.tcid		and
  testrun.id			= testruns.runid	and
  testruns.statusid		= status.id
  $dateCond
  $exectypeCond
END;

  $result = mysql_query ($statement)
    or dbError (__FUNCTION__ . ": Unable to execute query: ", $statement);

  while ($row = mysql_fetch_array ($result)) {
    if (empty ($status{$row["date"]}["Success"])) {
      $status{$row["date"]}["Success"] = 0;
    } // if
    if (empty ($status{$row["date"]}["Failure"])) {
      $status{$row["date"]}["Failure"] = 0;
    } // if
    $status{$row["date"]}{$row["status"]}++;
    $status{$row["date"]}{Total}++;
  } // while

  // We used $row["date"] as the key so that we could do the totalling
  // above but return an array with date inside it.
  $stats = array ();

  foreach ($status as $key => $value) {
    $data["Date"]	= $key;
    $data["Success"]	= $value["Success"];
    $data["Failure"]	= $value["Failure"];
    $data["Total"]	= $value["Total"];
    
    array_push ($stats, $data);
  } // foreach

  return $stats;
} // getStatus

function getStepFailures ($runid) {
  global $failureTypes, $nonFailures;

  $statement = <<<END
select
  step.name		as step,
  status.name		as status
from
  steprun,
  step,
  status
where
  steprun.stepid	= step.id	and
  steprun.statusid	= status.id	and
  runid			= $runid
order by
  step.name
END;

  $result = mysql_query ($statement)
    or dbError (__FUNCTION__ . ": Unable to execute query: ", $statement);

  $stepFailures = array ();

  while ($row = mysql_fetch_array ($result)) {
    // We only care about failures...
    if (array_search ($row["status"], $nonFailures) !== false) {
      continue;
    } // if

    $stepFailure["Step"]	= $row["step"];
    $stepFailure["Reason"]	= $row["status"];
    $stepFailure["Count"]	= $row["count"];

    array_push ($stepFailures, $stepFailure);
  } // while

  return $stepFailures;
} // getStepFailures

function getFailures ($day) {
  global $failureTypes;

  $dateCond = "and left (testrun.start, 10) = \"" . MDY2YMD ($day) . "\"";

  $statement = <<<END
select
  test.name		as testcase,
  testruns.unit		as unit,
  status.name		as status,
  testrun.start		as timestamp,
  testruns.runid	as runid
from
  test,
  status,
  testrun,
  testruns
where
  test.id		= testruns.tcid		and
  testrun.id		= testruns.runid	and
  testruns.statusid	= status.id
  $dateCond
order by
  test.name
END;

  $result = mysql_query ($statement)
    or dbError (__FUNCTION__ . ": Unable to execute query: ", $statement);

  $data = array ();

  while ($row = mysql_fetch_array ($result)) {
    // We only care about failures...
    if ($row["status"] == "Success") {
      continue;
    } // if

    $record = array ();

    $record["Testcase"]	= $row["testcase"];
    $record["Unit"]	= $row["unit"];
    $record["Time"]	= substr ($row["timestamp"], 11, 8);
    $record["_runid"]	= $row["runid"];
    $record["Failures"] = getStepFailures ($row["runid"]);

    array_push ($data, $record);
  } // while

  return $data;
} // getFailures

function getTestHistory ($testcase) {
  if (empty ($testcase)) {
    $testcase = "%";
  } else {
    $testcase = preg_replace ("/\*/", "%", $testcase);
  } // if

  if ($testcase != "%") {
    $statement = <<<END
select
  testruns.runid	as runid,
  testrun.start		as start,
  testruns.end		as end,
  testruns.unit		as unit,
  testruns.exectype	as type,
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
END;
  } else {
    $statement = <<<END
select
  test.name 					as testname,
  status.name					as status,
  count(if(status.name="Success",1,NULL))	as passed,
  count(if(status.name="Failure",1,NULL))	as failed,
  count(*)					as total
from
  testruns,
  status,
  test
where
  test.id		= testruns.tcid	and 
  testruns.statusid	= status.id
group by
  testname
END;
  } // if

  $result = mysql_query ($statement)
    or DBError ("Unable to execute query: ", $statement);

  $data = array ();

  while ($row = mysql_fetch_array ($result)) {
    $line["Testcase"]	= $row["testname"];

    if ($testcase != "%") {
      $line["DUT"]		= $row["unit"];
      $line["Type"]		= $row["type"];
      $line["Start"]		= $row["start"];
      $line["End"]		= $row["end"];
      $line["Duration"]		= strtotime ($row["end"]) - strtotime ($row["start"]);
      $line["_eastlogs"]	= $row["eastlogs"];
      $line["Status"]		= $row["status"];
      $line["_runid"]		= $row["runid"];

      array_push ($data, $line);
    } else {
      $line["Passed"]		= $row["passed"];
      $line["Failed"]		= $row["failed"];
      $line["Total"]		= $row["total"];
      $line["AvgRunTime"]	= averageRunTime ($row["testname"]);

      array_push ($data, $line);
    } // if
  } // while

  return $data;
} // getTestHistory

function getTestcaseVersions ($version) {
  if ($version == "<All Versions>") {
    unset ($version);
  } // if

  if (isset ($version)) {
    $condition = "and version.name = \"$version\"";
  } else {
    $condition = "";
  } // if

  $statement = <<<END
select
  testruns.runid	as runid,
  testrun.start		as start,
  testruns.end		as end,
  testruns.unit		as unit,
  testruns.exectype	as type,
  test.name		as testcase,
  status.name		as status,
  version.name		as version
from
  testrun,
  testruns,
  status,
  test,
  version
where
  version.runid		= testruns.runid	and
  test.id		= testruns.tcid		and
  testrun.id		= testruns.runid	and
  testruns.statusid	= status.id
$condition
END;

  $result = mysql_query ($statement)
    or DBError ("Unable to execute query: ", $statement);

  $data = array ();

  while ($row = mysql_fetch_array ($result)) {
    $line["Testcase"]	= $row["testcase"];
    $line["Start"]	= $row["start"];
    $line["End"]	= $row["end"];
    $line["Unit"]	= $row["unit"];
    $line["Type"]	= $row["type"];
    $line["Status"]	= $row["status"];
    $line["Duration"]	= strtotime ($row["end"]) - strtotime ($row["start"]);
    $line["Version"]	= $row["version"];
    $line["_runid"]	= $row["runid"];

    array_push ($data, $line);
  } // while

  return $data;
} // getTestcaseVersions

function averageRunTime ($name) {
  $statement = <<<END
select
  testrun.start		as start,
  testruns.end		as end
from
  test,
  testrun,
  testruns
where
  test.id	= testruns.tcid		and
  testrun.id	= testruns.runid	and
  test.name	= "$name"
END;

  $result = mysql_query ($statement)
    or dbError (__FUNCTION__ . ": Unable to execute query: ", $statement);

  $i = 0;

  while ($row = mysql_fetch_array ($result)) {
    $duration = (strtotime ($row["end"]) - strtotime ($row["start"]));

    $total += $duration;
    $i++;
  } // while

  return round ($total / $i);
} // averageRunTime

function getSuiteruns ($id) {
  global $sortBy, $direction;

  $statement = <<<END
select
  status.name as Status,
  Start,
  End
from
  suiterun,
  status
where
  suiteid	= $id and
  statusid	= status.id
END;

  $result = mysql_query ($statement)
    or dbError (__FUNCTION__ . ": Unable to execute query: ", $statement);

  $data = array ();

  while ($row = mysql_fetch_array ($result)) {
    $line["Status"]	= $row["Status"];
    $line["Start"]	= $row["Start"];
    $line["End"]	= $row["End"];
    $line[Duration]	= strtotime ($row["End"]) - strtotime ($row["Start"]);

    array_push ($data, $line);
  } // while

  // Sort data
  if ($sortBy == "Status") {
    uasort ($data, "sortStatus");
  } elseif ($sortBy == "End") {
    uasort ($data, "sortEnd");
  } elseif ($sortBy == "Duration") {
    uasort ($data, "sortDuration");
  } else {
    uasort ($data, "sortStart");
  } // if

  return $data;
} // getSuiteruns

function getTestSteps ($runid) {
  $data["_header"]["DUTVersion"]	= getVersion ("ran_version",		$runid);
  $data["_header"]["EASTVersion"]	= getVersion ("east_version",		$runid);
  $data["_header"]["TM500Version"]	= getVersion ("tm500_version",		$runid);
  $data["_header"]["NMSVersion"]	= getVersion ("nms_version",		$runid);
  $data["_header"]["RANTESTVersion"]	= getVersion ("rantest_version",	$runid);

  $statement = <<<END
select
  steprun.runid		as _runid,
  step.name		as step,
  left (start, 10)	as date,
  start,
  steprun.end		as end,
  status.name		as status,
  eastlogs		as _eastlogs,
  userid
from
  steprun,
  step,
  testruns,
  status
where
  steprun.runid	= $runid		and
  steprun.runid	= testruns.runid	and
  step.id	= steprun.stepid	and
  status.id	= steprun.statusid
order by
  start
END;

  $result = mysql_query ($statement)
    or dbError (__FUNCTION__ . ": Unable to execute query: ", $statement);

  $data["_header"]["userid"]	= "Unknown";
  $data["_steps"]		= array ();

  while ($row = mysql_fetch_array ($result)) {
    $line["Step"]			= $row["step"];
    $line["Status"]			= $row["status"];
    $data["_header"]["Date"]		= $row["date"];
    $line["Start"]			= $row["start"];
    $line["End"]			= $row["end"];
    $line["Duration"]			= strtotime ($row["end"]) - strtotime ($row["start"]);
    $data["_header"]["userid"]		= $row["userid"];
    $data["_header"]["_eastlogs"] 	= $row["_eastlogs"];

    array_push ($data[_steps], $line);
  } // while

  return $data;
} // getTestSteps

function getTestRunTimestamp ($runid) {
  $statement = <<<END
select
  left (start, 10)	as startDate,
  right (start, 8)	as startTime
from
  steprun
where
  runid = $runid
END;

  $result = mysql_query ($statement)
    or dbError (__FUNCTION__ . ": Unable to execute query: ", $statement);

  $row = mysql_fetch_array ($result);

  return $row["startDate"] . "." . $row["startTime"];
} // getTestRunTimestamp

function getTestRuns ($day, $type, $export = false) {
  global $sortBy, $direction;

  $typecond = ($type == "All") ? "" : "exectype = \"$type\" and";

  $statement = <<<END
select
  test.name		as testcase,
  status.name		as status,
  suite.name		as suite,
  testrun.start		as start,
  testruns.runid	as _runid,
  testruns.end		as end,
  testruns.unit		as unit,
  testruns.exectype	as exectype,
  testruns.eastlogs	as _eastlogs,
  testruns.suiteid	as _suiteid
from
  testruns,
  testrun,
  test,
  status,
  suite
where
  left (start, 10)	= "$day"	and
  $typecond
  testruns.runid	= testrun.id	and
  testruns.tcid		= test.id	and
  statusid		= status.id	and
  (suiteid		= suite.id	or
   suiteid		= 0)
group by
concat(tcid, start)
END;

  $result = mysql_query ($statement)
    or dbError (__FUNCTION__ . ": Unable to execute query: ", $statement);

  $data = array ();
  $i	= 1;

  while ($row = mysql_fetch_array ($result)) {
    if (!$export) {
      $line["#"] = $i++;
    } // if

    $line["Suite"]		= $row["suite"];
    $line["Testcase"]		= $row["testcase"];
    $line["Type"]		= $row["exectype"];
    $line["Unit/Version"]	= "$row[unit]-" . getBuildNbr ($row["_runid"]);
    $line["Logs"]		= (file_exists ($row["eastlogs"])) ? "yes" : "no";
    $line["Status"]		= $row["status"];
    $line["Start"]		= substr ($row["start"], 11);
    $line["End"]		= substr ($row["end"], 11);
    $line["Duration"]		= strtotime ($row["end"]) - strtotime ($row["start"]);

    $line["_runid"]		= $row["_runid"];
    $line["_eastlogs"]		= $row["_eastlogs"];
    $line["_suiteid"]		= $row["_suiteid"];

    array_push ($data, $line);
  } // while

  // Sort data
  if ($sortBy == "Suite") {
    uasort ($data, "sortSuite");
  } elseif ($sortBy == "Testcase") {
    uasort ($data, "sortTestcase");
  } elseif ($sortBy == "Type") {
    uasort ($data, "sortType");
  } elseif ($sortBy == "Unit") {
    uasort ($data, "sortUnitVersion");
  } elseif ($sortBy == "Status") {
    uasort ($data, "sortStatus");
  } elseif ($sortBy == "End") {
    uasort ($data, "sortEnd");
  } elseif ($sortBy == "Duration") {
    uasort ($data, "sortDuration");
  } else {
    uasort ($data, "sortStart");
  } // if

  return $data;
} // getTestRuns
?>
