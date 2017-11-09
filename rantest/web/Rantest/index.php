<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	index.php
// Revision:	1.2
// Description:	Main index page for Rantest
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
OpenDB();

$testNames		= getTestNames();
$days			= getdays();
$ran_versions		= getVersions ("ran_version");
$latestDate		= YMD2MDY (getLatestDate ());
$earliestDate		= YMD2MDY (getEarliestDate ());
?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Testing.css">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Tables.nohover.css">
  <title>RANTEST: RAN Tool for Execution of System Tests</title>
</head>

<body>

<?php
  print banner ();
?>

  <h1 align=center><font class="standout">RAN T</font>ool for <font class="standout">E</font>xecution of <font class="standout">S</font>ystem <font class="standout">T</font>ests</h1>

  <table width="95%" align="center">
    <thead>
      <tr>
        <th colspan=2 class="top"><big>Execution Reports</big><br>
<?php
print "Status for $latestDate: ";
print stats();
?>
</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="shaded" width=50%>
    	  <b>Test History</b><br>
  	  <small>How often a test case has run, with pass/fail status<br><br>
          <form action="TestHistory.php">
  	  <table class="shaded" align="center">
   	    <thead>
              <tr>
                <th class="left">Build</th>
                <th>Level</th>
                <th>DUT</th>
                <th class="right">Test</th>
              </tr>
            </thead>
            <tbody>
  	      <tr class="white">
                <td>
                  <select name=build class=inputfield>
  		    <option selected=selected>*</option>
  		    <option>b1</option>
  		    <option>b2</option>
  		    <option>b3</option>
                  </select>
                </td>
                <td>
                  <select name=level class=inputfield>
		    <option selected=selected>*</option>
		    <option>l3</option>
		    <option>l4</option>
		    <option>fqt</option>
                  </select>
                </td>
                <td>
	          <select name=DUT class=inputfield>
  		    <option selected=selected>*</option>
		    <option>ran</option>
		    <option>rnc</option>
		    <option>rbs</option>
		    <option>rcg</option>
                  </select>
                </td>
                <td><input type=text name=test size=10 class=inputfield value="*"></input></td>
              </tr>
              <tr class="white">
                <td colspan=4 align=center>
                  <input type=submit value="Report">
                </td>
              </tr>
            </tbody>
          </table>
          </form>
        </td>
        <td class="shaded">
  	  <b>Version per Testcase</b><br>
          <small>For a given test case, what was the test environment (software version of each of the test equipment and RBS/RNC)</small><br><br>
          <form action="VersionPerTestcase.php">
  	  <table class="shaded" align="center">
   	    <thead>
              <tr>
                <th class=left>Build</th>
                <th>Level</th>
                <th>DUT</th>
                <th class=right>Test</th>
              </tr>
            </thead>
            <tbody>
  	      <tr class="white">
                <td>
                  <select name=build class=inputfield>
  		    <option selected=selected>*</option>
  		    <option>b1</option>
  		    <option>b2</option>
  		    <option>b3</option>
                  </select>
                </td>
                <td>
                  <select name=level class=inputfield>
		    <option selected=selected>*</option>
		    <option>l3</option>
		    <option>l4</option>
		    <option>fqt</option>
                  </select>
                </td>
                <td>
	          <select name=DUT class=inputfield>
  		    <option selected=selected>*</option>
		    <option>ran</option>
		    <option>rnc</option>
		    <option>rbs</option>
		    <option>rcg</option>
                  </select>
                </td>
                <td><input type=text name=test size=10 class=inputfield value="*"></input></td>
              </tr>
              <tr class="white">
                <td colspan=4 align=center>
                  <input type=submit value="Report">
                </td>
              </tr>
            </tbody>
          </table>
          </form>
        </td>
      </tr>
      <tr class="white">
        <td>
	  <b>Testcase per Version</b><br>
	  <small>What test cases have run against a given RBS/RNC/RAN software version<br><br>
          <form action="TestcasePerVersion.php">
            RAN Version:
            <select name=version class=inputfield>
<?php
  foreach ($ran_versions as $version) {
    print "<option>$version</option>\n";
  } // foreach
?>
            </select>
            <input type=submit value="Report">
          </form>
          </small>
        </td>
        <td width=50%>
          <b>Test Statistics</b><br>
          <small>Number of test cases run over a given period with pass/fail status<br><br>
          <form action="TestStats.php">
            From: 
            <select name=start class=inputfield>
<?php
  foreach ($days as $day) {
    print "<option";

    if ($day == $earliestDate) {
      print " selected=selected";
    } // if

    print ">$day</option>\n";
  } // foreach
?>
            </select>
            To: 
            <select name=end class=inputfield>
<?php
  foreach ($days as $day) {
    print "<option";

    if ($day == $latestDate) {
      print " selected=selected";
    } // if

    print ">$day</option>\n";
  } // foreach
?>          </select>
            <input type=submit name="action" value="Report">&nbsp;
            <input type=submit name="action" value="Graph">
            </small>
          </form>
        </td>
      </tr>
      <tr>
        <td class="shaded" width=50%>
          <b>Failure Analysis</b><br>
          <small>Show the reasons for failure<br><br>
          <form action="FailureAnalysis.php">
            <select name=day class=inputfield>
<?php
  foreach ($days as $day) {
    print "<option";

    if ($day == $latestDate) {
      print " selected=selected";
    } // if

    print ">$day</option>\n";
  } // foreach
?>          </select>
            <input type=submit name="action" value="Report">
            </small>
          </form>
        </td>
        <td class="shaded">
          <b>Daily Test Report</b><br>
          <form action="rantest.php">
          <small>What test automation ran on:<br><br>
            <select name=day class=inputfield>
<?php
  foreach ($days as $day) {
    print "<option>$day</option>\n";
  } // foreach
?>	
            </select>
            <input type=submit value="Report">
          </form>
        </td>
      </tr>
      <tr class="white" align="center">
        <td colspan="2">
<?php
exec ("ls /east/seast1/testlogs/nightly*log /east/seast1/testlogs/ranscrub.log", &$nightly_logs, &$status);

if ($status != 0) {
  print "Unable to do ls /east/seast1/testlogs/nightly*log (Status: $status)";
} else {
  $count = count ($nightly_logs);
  $nbr = 1;

  if ($count > 0) {
    print "<h3>Nightly logs</h3>";
    foreach ($nightly_logs as $nightly_log) {
      preg_match ("/\/east\/seast1\/testlogs\/(.*)\.log/", $nightly_log, &$matches);

      print "<a href=\"/testlogs/$matches[1].log\">$matches[1]</a>";

      if (--$count > 0) {
	if ($nbr++ % 5 == 0) {
	  print "|<br>";
	} else {
	  print "&nbsp;|&nbsp;";
	} // if
      } // if
    } // foreach
  } // if
} // if
?>
        </td>
      </tr>
    </tbody>
  </table>

<?php copyright();?>
</body>
</html>