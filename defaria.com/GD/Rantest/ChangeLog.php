<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	ChangeLog.php
// Revision:	1.2
// Description:	Change log for 1.2
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
?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Testing.css">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Tables.nohover.css">
  <title>RANTEST: ChangeLog</title>
</style>
</head>

<body>

<?php print banner ();?>

<h1 align=center>RANTEST 1.2 ChangeLog</h1>

<ul>
   <li><a href="#1.2.1">Version 1.2.1</a></li>

   <li><a href="#1.2">Version 1.2</a></li>
</ul>

<p>This is the ChangeLog for RANTEST for versions 1.2 and up.</p>

<p>See also:</p>

<ul>
  <li><a href="ChangeLog0.9.php">RANTEST 0.9 ChangeLog</a></li>

  <li><a href="ChangeLog1.0.php">RANTEST 1.0 ChangeLog</a></li>

  <li><a href="ChangeLog1.1.php">RANTEST 1.1 ChangeLog</a></li>
</ul>

<h2><a name="1.2.1">Version 1.2.1</a></h2><hr>

<h3>Web:</h3>

<ul>
  <li>Fixed a bug with TestHistory.php where it fails to sort by
  column. The real problem was how it was passing the testcase
  parameter in the URL. It was using the MySQL wildcard of "%", which
  is an escape character in URLs. The fix involves only ever using and
  showing the user "*" instead of "%". Then, internally, converting
  "*"'s -> "%"'s.</li>

  <li>Fixed change logs to have the banner.</li>

  <li>Fixed GraphStats.php to no longer use the hard coding to my view.</li>

  <li>Added protection to exported CSV filenames so that they don't
  contain "*"'s.</li>

  <li>
</ul>

<h2><a name="1.2">Version 1.2</a></h2><hr>

<h3>Web:</h3>

<ul>
  <li>General redesign of web pages. New color scheme, etc. In general for all pages:</li>

  <ul>
    <li>Added General Dynamics banner to all pages. Note that General
    Dynamics in the banner is also a link to "home" (clicking on it
    gets to to the main page).</li>

    <li>Added <input type="submit" value="Export to CSV">
    functionality to all pages. Now you can export the current web
    page to a CSV file for use with Excel/Open Office.</li>

    <li>Added <b>Email to</b> functionality to pages. To use select a
    user in the dropdown (dynamically created list of users from NIS)
    and click <input type="submit" value="Send">. An email will be
    sent to that user with the contents of the web page rendered into
    HTML in their Outlook inbox! Also a .csv file of the page will be
    attached!</li>

    <li>Added sorting by column headers. Click on a column to
    sort. Click on the same column to sort in reverse order.</li>
  </ul>

  <li>New report: <i>Failure Analysis</i>. This report shows you the
  test steps that failured for a particular day.</li>

  <li>Moved date dropdowns into the report headings. For example the
  <i>Daily Test Report</i> and <i>Failure Analysis</i> reports now have the
  date dropdown in the heading itself.</li>

  <li>Added <input type="submit" value="Analyze Failures"> button to
  <i>Daily Test Report</i></li>

  <li>Added graph to <i>Test Statistics</i> report! This graph shows
  the daily testing over time with pass/fail. You can also select a
  date range and test type and regenerate the graph. Also added <input
  type="submit" value="Report"> button on graph to switch to the
  report and a <input type="submit" value="Graph"> button on report to
  switch to the graph.</li>

  <li>Filled out <i>Testcase per Version</i> and <i>Version per
  Testcase</i> reports.</li>

  <li>Added <input type="submit" value="History"> button to <i>Test
  Steps</i> report. This allows you to easily see the history for a
  test.</li>

  <li>Changed <b>Run by</b> to use the actual person's name and to
  make it a mailto link in the <i>Test Steps</i> report.</li>

  <li>Added the ability to filter based on <b>Type</b> (All, Normal,
  Regression) on <i>Daily Test Report</i>.</li>

  <li>Moved <b>Nightly Logs</b> to bottom of the main page and
  arranged the links to at maximum 5 per row.</li>
</ul>

<h3>Rantest DB</h3>

<ul>
  <li>Added indexes to database to speed up retrieval of certain
  queries</li>
</ul>

<?php copyright();?>
</body>
</html>
