<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	Changelog0.9.php
// Revision:	1.2
// Description:	Change log for Rantest 0.9
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
  <title>RANTEST: ChangeLog 0.9</title>
</style>
</head>

<body>

<?php print banner ();?>

<h1 align=center>RANTEST 0.9 ChangeLog</h1>

<ul>
   <li><a href="#0.9.9c">Version 0.9.9c</a></li>

   <li><a href="#0.9.9b">Version 0.9.9b</a></li>

   <li><a href="#0.9.9a">Version 0.9.9a</a></li>

   <li><a href="#0.9.9">Version 0.9.9 - Code Complete</a></li>

   <li><a href="#0.9.8d">Version 0.9.8d</a></li>

   <li><a href="#0.9.8c">Version 0.9.8c</a></li>

   <li><a href="#0.9.8b">Version 0.9.8b</a></li>

   <li><a href="#0.9.8a">Version 0.9.8a</a></li>

   <li><a href="#0.9.8">Version 0.9.8</a></li>

   <li><a href="#0.9.7a">Version 0.9.7a</a></li>

   <li><a href="#0.9.7">Version 0.9.7 - "The Rantvl release"</a></li>

   <li><a href="#0.9.6">Version 0.9.6</a></li>

   <li><a href="#0.9.5">Version 0.9.5</a></li>
</ul>

<p>This is the ChangeLog for RANTEST for versions 0.9 and up.</p>

<p>See also:</p>

<ul>
  <li><a href="ChangeLog1.0.php">RANTEST 1.0 ChangeLog</a></li>

  <li><a href="ChangeLog1.1.php">RANTEST 1.1 ChangeLog</a></li>

  <li><a href="ChangeLog.php">RANTEST 1.2 ChangeLog</a></li>
</ul>

<h2><a name="0.9.9c">Version 0.9.9c</a></h2><hr>

<h3>East.pm:</h3>

<ul>
  <li>Changed MAX_ATTEMPTS to 4</li>

  <li>Moved capturing of $startTime into the do/until statement</li>

  <li>Added some LogDebug statements to trace what's happening with
  this auto-rerun stuff.</li>

  <li>Changed if statement such that the warning would come out on the
  first re-run. I suspect impatient engineers were not waiting for the
  3 iteration when the first warning would come out.</li>

  <li>Changed to use /vobs/nms_log for NMS logs. Vob's been replicated
  but not put into project yet. This should happen soon however.</li>
</ul>

<h3>domsh</h3>

<ul>
  <li>Changed to handle the situation where -pattern is not
  specified.</li>

  <li>Added [OUTPUT][/OUTPUT] and [STATUS][/STATUS] tags.</li>
</ul>

<h3>ranscrub</h3>

<ul>
  <li>Fixed bug with finding ranscrub's conf file.</li>
</ul>

<h3>Web:</h3>

<ul>
  <li>Added <i>Testcase Per Version</i> report.</li>

  <li>Added support for multiple nightly logs</li>

  <li>Added link to <i>Testcase Per Version</i> report.</li>
</ul>

<h2><a name="0.9.9b">Version 0.9.9b</a></h2><hr>

<h3>rantest:</h3>

<ul>
  <li>Added runValidation subroutine that handles running of a
  validation and also adds to the rantest database the validation test
  step.</li>

  <li>Fixed up some errors in the execution of valMsgs.pl
  validation. This included missing the testlogs component of the
  path, adding the leading "/" before Rantvl, using $_opts{type}
  instead of the missing $_opts{unitType} and adding on the ">" for
  proper redirection.</li>
</ul>

<h3>ranscrub:</h3>

<ul>
  <li>Added logging to ranscrub. It will now log to testlogs.</li>
</ul>

<h3>donightly:</h3>

<ul>
  <li>Will now accept a parameter for the DUT in question. This allows
  a poor man's way of doing parallelization by creating .suite or
  .test files that have the DUT as part of the filename and adding
  multiple lines in cron(1).</li>

  <li>Because of the above: Removed the updating or
  rantest.stats.csv.</li>
</ul>

<h3>Web:</h3>

<ul>
  <li>Added new report: Test Case Per version.</li>

  <li>Removed useless reports on many page</li>

  <li>Added average run time to Test History Report but only for when
  all tests are selected.</li>
</ul>

<h2><a name="0.9.9a">Version 0.9.9a</a></h2><hr>

<h3>East.pm:</h3>

<ul>
  <li>Changed to not spawn extra processes when -timeout -1 was
  used.</li>

  <li>At Roman and Doug's request, added code to print out all of the
  logfiles produced under logpath.</li>
</ul>

<h3>Web:</h3>

<ul>
  <li>RantestDB.php: Added new Error function</li>

  <li>RantestDB.php: Added getStatus function like
  RantestDB::getStatus function. This routine is the driver for the
  new TestStats.php page.</li>

  <li>TestHistory.php: Added total row.</li>

  <li>index.php: Activated TestStats report</li>

  <li>TestStats.php: Added TestStats report</li>
</ul>

<h3>Ranscrub:</h3>

<ul>
  <li>Added formatSize to format the size into a more human readable
  form.</li>

  <li>Added scrubbing of Rantvl</li>

  <li>Added option handling for testlogs, rantvl and rantestdb
  scrubbing as well as all - default all.</li>

  <li>Added rantvl_user to config file and updated scrub_days and
  db_scrub to 45 days.</li>
</ul>

<h3>Misc</h3>

<ul>
  <li>Changed update_view to use -x to avoid xauth problems</li>
</ul>

<h2><a name="0.9.9">Version 0.9.9 - Code Complete</a></h2><hr>

<p>Reached code complete!</p>

<h3>East.pm:</h3>

<ul>
  <li>Changed code to automatically create test case ID directories if
  they are not present for <i>Run for Record</i></li>

  <li>Changed to handle error output a little better.</li>
</ul>

<h2><a name="0.9.8d">Version 0.9.8d</a></h2><hr>

<h3>rantest:</h3>

<ul>
  <li>Added code to capture output from validation scripts into a log
  file</li>
</ul>

<h3>donightly</h3>

<ul>
  <li>Added code to put out the date, failures and successes into
  .../auto/test/nightly/rantest.stats.csv for graphing purposes.</li>
</ul>

<h3>East.pm</h3>

<ul>
  <li>Changed handling of log collection again to handle run for
  record capturing better.</li>

  <li>Checking for /^\[LOG\]/ instead of /\[LOG\]/. Sometimes [LOG]
  was appearing in ASCII dumps!</li>
</ul>

<h2><a name="0.9.8c">Version 0.9.8c</a></h2><hr>

<h3>rantest:</h3>

<ul>
  <li>Emergency fix! Changing the flow of when log files are collected
  after disconnection is fine. However when in suite mode we
  disconnect for each .test file we run. Since disconnect no logner
  automatically calls collectLogFiles we need to call it right after
  each time we disconnect. We also need to run validations at that
  time.</li>

  <li>Changed collectLogFiles to not exit rantest merely because we
  couldn't find a logfile. In suite mode there may be more to do.</li>
</ul>

<h2><a name="0.9.8b">Version 0.9.8b</a></h2><hr>

<h3>rantest:</h3>

<ul>
  <li>I believe the persistent bug regarding running in cron is
  finally fixed!</li>

  <li>Removed the wait for processes to finish. This was done only
  because GenericDesktopMonitor would be running for up to 10 seconds
  after we stopped. Before, when we used to tar up things, this was
  important. Sometimes the tar would report that the files changed
  while tarring them. Since we don't make tars anymore this should not
  be a problem. Might be a problem for Run for Record though...</li>

  <li>Added verbose output to tell the user where the log files are
  stored under testlogs. This will be helpful for manual validations
  that are still required.</li>

  <li>Fixed bug with grepping for "Simulator version is". Needed to
  put quotes around that!</li>

  <li>Changed name of rantest build logs vob to
  rantest_build2_log. There is no rantest_log_build2 vob!</li>

  <li>Changed running of validations to occur after collection of log
  files. Otherwise it doesn't make sense to validate against logfiles
  that haven't be collected.</li>
</ul>

<h3>Validation</h3>

<ul>
  <li>Renamed decode.test.FQT to aal2val</li>

  <li>Created msgdefs directory</li>
</ul>

<h3>ranscrub</h3>

<ul>
  <li>Checked in bare bones ranscrub and config/ranscrub.conf</li>
</ul>

<h2><a name="0.9.8a">Version 0.9.8a</a></h2><hr>

<h3>Web:</h3>

<ul>
  <li>Fixed borken link in copyright version</li>
</ul>

<h3>Rantest:</h3>

<ul>
  <li>Fixed bug with handling of ReadLine properly in interactive and
  cron cases.</li>

  <li>Fixed bug with errorneously calling validation routines when
  there were none specified in test</li>

  <li>Added progress indication in log collection</li>

  <li>Fixed bug with keeping track of stats - errorneously adding file
  failure count to test failure count</li>
</ul>

<h3>East.pm:</h3>

<ul>
  <li>Changed bugcatcher to only log to /tmp/rantest.debug.log</li>
</ul>

<h2><a name="0.9.8">Version 0.9.8</a></h2><hr>

<h3>Web:</h3>

<ul>
  <li>Changed copyright block to highlight and link only the current
  version</li>

  <li>Added Last Modified into copyright block</li>
</ul>

<h3>Rantest:</h3>

<ul>
  <li>Added comment about suite files</li>

  <li>Now properly returning $suiteFailures from runSuiteFile</li>

  <li>Added runValidation subrountine. Now does rudimentary
  validations for valMsgs.pl and aalval</li>

  <li>Changed to use -t STDIN to distingish if we are running with a
  tty. If not we are in cron and we have to behave differently for the
  ReadLine stuff.</li>

  <li>Now properly returning errors from runFile subroutine</li>

  <li>Now ouputs a message telling the user if it is busy terminating
  processes and collecting logfiles at the end of execution</li>
</ul>

<h3>East.pm:</h3>

<ul>
  <li>Changed bug catcher (for ls -t problem) to log all java
  processes running to /tmp</lI>

  <li>Added getCollectLogFiles method.</li>

  <li>Refixed bugs in calls to error with join in subroutines like
  _checkoutElement</li>

  <li>Totally changed the way collectLogFiles work. For one, it no
  longer creates tar files, except for run for record. The new
  ranscrub (in development) will be responsible for cleaning up space
  in testlogs and other areas. Doing this also removes the disposition
  of logfiles from rantest's concern</li>

  <li>Plus run for record runs now first store in testlogs then only
  made as a tar directly into the appropriate Clearcase vob.</li>

  <li>Based on the log type (EAST|TM500|NMS|RANTVL) the run for record
  tar image is put into simdev_log, tm500_log, rantest_log_build2. For
  that last one both NMS and RANTVL is stored into
  rantest_log_build2. Yes I don't like the 2 in build 2! :-(</li>
</ul>

<h2><a name="0.9.7a">Version 0.9.7a</a></h2><hr>

<p>Roll up fixes for <a href="#0.9.7">0.9.7</a>:</p>

<ul>
  <li>Changed handling of errors in collectLogFiles.  Since this is
  happening from when disconnecting from EAST there's no sense in
  attempting to return status or error messages, just die!  Also
  changed the internal methods that collectLogFiles calls
  (e.g. _makeTar, _checkOutElement, etc.) simply die too.</li>

  <li>Now setting umask correctly to 002 (was setting it to 022!,
  which did nothing different). With new umask setting we no longer
  need to attempt to chmod directories to 775.</li>

  <li>Removed DESTROY subroutine. Seems if we attempt to call
  disconnect from DESTROY then it doesn't work well. Not really sure
  why this happens but rantest now calls $east->disconnect
  directly. We should investigate this further because it would be
  much better if DESTROY did the right thing</li>

  <li>Implemented new testtimeout option. This option, entered into
  the .test file, will set an overall limit of how long rantest will
  wait for all test steps to complete. This is done via an alarm
  signal. So rantest sets the alarm at the start of execution of the
  test steps and a signal handler to catch the alarm signal. If caught
  then rantest disconnects from EAST. Not sure how smoothly things
  proceed from there (does rantest continue to the next .test
  file?)</li>

  <li>Created runSuiteFile as a separate subroutine. This subroutine
  will now parse off options after the .test file that override what's
  in the .test file. This will allow us to specify "mytest.test -unit
  6" so that even if mytest.test said to use unit 3, during this suite
  run it would use unit 6.</li>

  <li>Added user ID of who ran the test to the Test Step web page.</li>

  <li>Added "news" link to this page</li>

  <li>Added link to main page to the Nightly Log</li>

  <li>Added/fixed p6000c and p4781c's ssh keys to authorized_keys</li>

  <li>Added this ChangeLog</li>
</ul>

<h2><a name="0.9.7">Version 0.9.7 - "The Rantvl release"</a></h2><hr>

<h3>Rantvl</h3>

<p>A word about rantvl. This is a rantest_tools tool so it resides on
the RAN, specifically under /prj/muosran/SWIT/tools/bin/rantvl. This
Perl script contacts the DUT and sets up logging via a moshell script
(which is why it needs to run on a RAN machine since moshell doesn't
work from the Linux EAST environment). It then kicks off a number of
processes that run in the background. All of these processes are
spawned off as children of rantvl. Rantvl then wait(3)'s for either
the children to finish (bad, bad - this is an error since the logging
should never finish) or for it to be terminated.</p>

<p>Rantest will open up a channel to RANHOST as RANUSER and run rantvl
supplying it the -[rnc|rbs] [n] parameters as well as a -logpath
parameter. The -logpath parameter is a path relative to
ranray:/export/rantvl, since this filesystem seems to have space. We
probably should verify and OK that. So then rantest will supply the
logpath of &lt;testname&gt;/&lt;DUT&gt;/&lt;timestamp&gt;. (Note to
Ken, while the logfiles may grow large, rantest/rantvl is pretty
efficient in that once the test is completed these files are copied to
our testlogs areas on seast1 and removed from
ranray:/export/rantvl).</p>

<p>Rantvl then will use that logpath to write it's logfiles. When
rantest is done running tests in a .test file it collects the rantvl
logfiles by scp'ing them from
&lt;RANHOST&gt;:/export/rantvl/&lt;logpath&gt;/* to seast1's LOGBASE -
/east/seast1/testlogs/&lt;logpath&gt;/Rantvl/*.  Rantest will then
remove the logfiles from the source area
(&lt;RANHOST&gt;:/export/rantvl/&lt;logpath&gt;/*) to conserve space.
Rantvl is then added to the list of directories to tar up into a
Rantvl.tgz (i.e.  <a
href="http://rantestweb/testlogs/b2_l3_rnc_irt_001.rantvl/rnc5/20080527@14:20:59/">http://rantestweb/testlogs/b2_l3_rnc_irt_001.rantvl/rnc5/20080527@14:20:59/</a>).</p>

<h3>General:</h3>

<ul>
  <li>Replaced bash script, update_view, with Perl script. Now does
  -overwrite by default. Cronjob now calls it with -nooverwrite.</li>

  <li>Added copy of authorized_keys to config. This is the ssh
  authorized_keys file for all of the rantm50x machines as well as the
  NMS simulator machines. This allows testers to ssh as pswit onto
  these machines without needing a password. This facilitates
  automation.</li>
</ul>

<h3>East.pm:</h3>

<ul>
  <li>Added support for rantvl.</li>

  <li>Added LOGBASE</li>

  <li>Added constants for RANHOST (ranray) and RANUSER (pswit). Both
  Moshell and Rantvl need to connect remotely to a RAN machine as a
  generic user. These constants facilitate that.</li>

  <li>Changed to only attempt collection of log files if there log
  files to collected. Rantest will set the member collectLogFiles to
  true when there are log files to collect (i.e. when a test step is
  attempted). It will also turn this off if the test run is
  interrupted (Control-C) and abort is selected.</li>

  <li>Added new set/getCollectLogFiles methods for the above.</li>

  <li>Changed the logic in collectLogFiles a little bit to accommodate
  collection of Rantvl log files too. When collecting Rantvl log files
  they are scp'ed from RANHOST to the local host (in this case seast1)
  under LOGBASE and then removed from RANHOST to conserve space.</li>

  <li>Added pod documentation for new East methods.</li>
</ul>

<h3>Web:</h3>

<ul>
  <li>Put web pages formally under Clearcase control.
  cclinux:/var/www/html now points directly to
  ./pswit_auto/vobs/rantest_auto/web.</li>

  <li>php/Utils.php now puts out the version of the web pages (0.9.7)
  so that they stay in line with the version of rantest and
  friends.</li>

  <li>Added logic for new "test selectors" on the main page to
  TestHistory.php.</li>

  <li>Renamed links in the copyright section to shorter names. Also
  added in Gantry's nice User's Guide: Home | Wiki | Users Guide |
  Usage.</li>

  <li>Changed RantestDB.php to categorize "Logging started" results
  (from a rantvl log) in a similar fashion to "In progress" results as
  the running of rantvl is really a backgrounded operation...</li>
</ul>

<h3>Rantest:</h3>

<ul>
  <li>Changed $east object to a global since the INT signal handler
  now needs to set state in it and there's no other way to get to the
  object except to make it global. This required removing $east from
  all subroutines it used to be passed to.</li>

  <li>Added logic to bail out on a .test run if one could not connect
  to EAST. Rantest will now go to the next test in the case of suite
  execution (since the next case may have a different rnc, etc.)</li>

  <li>Added code to handle new rantvl type steps.</li>

  <li>Added code to treat "Logging started" like "In progress".</li>

  <li>Error out if we cannot create our "saveTo" directory.</li>

  <li>Changed to set umask to 022 for reduce the problems created by
  not creating objects as group writable.</li>

  <li>Changed to classify both Failed's and Timeout's as error and
  exit with a total of both of them. IOW only if there are no Failed's
  and no Timeout's will an exit 0 be done.</li>

  <li>Updated rantest wiki page to 0.9.7. Also includes link to
  rantestweb.</li>
</ul>

<h2><a name="0.9.6">Version 0.9.6</a></h2><hr>

<p>I'm delivering rantest 0.9.6 with the following set of features in
anticipation of working on integrating rantvl for 0.9.7.</p>

<p>New in 0.9.6:</p>

<ul>
  <li>Now properly records the full path to the log files for this run
  in the databse as testruns.eastlogs.</li>

  <li>Errors in creation of paths are reported better.</li>

  <li>New directories that are created are chmod 0775 to facilitate
  sharing. Note that not every component is chmoded - only the leaf
  node.</li>

  <li>Disposition of log directories that are tarred is set to "keep"
  now. This means that there will be a tar file and the source
  directory for easy navigation through the web. It also means that
  our testlogs directory will get fuller, faster.</li>

  <li>bin/donightly has come back with a similar purpose but different
  implementation. It now runs all of the .test and .suite files in
  ../auto/test/nightly.</li>

  <li>Changed testruns.eastlogs and testruns.cmlogs from tinytext to
  just text. These log file paths are pretty long and what's a few
  bytes between friends?</li>

  <li>Changed rantest to save original command line options and
  restore them at the start of each .test run.</li>

  <li>Changed rantest to save the testStartTime so that the start
  times reported on the web match those in the path to the
  logfiles. This allows the web loglinks to work.</li>

  <li>Reorganized a lot of the web stuff and put it firmly under
  Clearcase control.</li>

  <li>Fixed problem with drop downs in Firefox (1.0) when doing hover
  rollovers on main page.</li>

  <li>Rearranged front page and added "test selectors" to a few of the
  reports. Also made the Test History report properly respond to these
  new test selectors. if all boxes are "*" then Test History does an
  "All Tests" report, otherwise it filters the qualifying entries and
  reports on them.</li>

  <li>Added Loglinks to web site. Engineers can now drill down to the
  actual tests and then into the logs themselves to diagnois
  problems.</li>

  <li>Removed Run By from Daily Test Report.</li>

  <li>Changed Daily Test Report to report Unit and Version.</li>

  <li>Added version number to copyright block on the web page.</li>

  <li>Added getBuildNbr function to RantestDB.php.</li>

  <li>Changed DBError calls to use __FUNCTION__.</li>
</ul>

<h2><a name="0.9.5">Version 0.9.5</a></h2><hr>

<ul>
  <li>Takes two extensions for -file, .suite or .test. The .test is
  like the old .suite files (in fact, I've renamed the old .suite
  files -&gt; test). Therefore the new .suite file is different - it's
  simply a file listing a bunch of .test's to test.</li>

  <li>Now uses LOGBASE, set to $ENV{MNT_DIR}/testlogs. All logs are
  now stored under that.</li>

  <li>Now uses TESTBASE, set to "/local/server/auto/test". This is the
  base relative directory that rantest uses to look for tests and
  suites.</li>

  <li>Verbose output improved. Since rantest can run suites, which
  contain other tests, we needed to properly represent this in the
  verbose output.</li>

  <li>The -saveto has been removed. Instead logs are saved to LOGBASE
  (with appropriate subdirectory structure).</li>

  <li>Added pattern to elock subcommand. Allows you to filter out
  stuff. So "rantest elock rnc" will show only rnc's. Also, elock is a
  short circut commands such that if it is given on the command line
  as the above hints at, then elock is done and rantest exits. Note
  elock still works inside rantest in interactive mode. Finally
  colorized output.</li>

  <li>recordRun changed to announceTestRun and is used before each
  test run of a suite or individual test.</li>

  <li>Added code to support new rantest DB format. Now we call
  start[type]run and end[type]run (where type is Suite, Test, Step) to
  record to the database the starting and ending of suites, tests and
  test steps.</li>

  <li>Changed runFile to call runTestFile for tests. runFile now
  handles suite runs.</li>

  <li>Changed East.pm to disconnect from East (i.e. shutdown
  GenericDesktop and friends) after each execution of a test. This
  requires that we start another one up for the next test in a
  suite.</li>

  <li>Added methods to set TestCaseID and saveTo directory so that
  saveLogFiles can be called in the East object destructor.</li>

  <li>saveLogFiles now properly copies log files from their source
  locations to our new LOGBASE location before tarring them up.</li>

  <li>saveLogFiles now copies subdirs of EASTLogs as per Ross'
  request.</li>

  <li>saveLogFiles now removes the copied subdirs after the tar to
  conserve space.</li>
</ul>

<p>One outstanding problem remains that occasionally rantest is unable
to find the logfile. I have a bugcatcher in 0.9.5 however it see ms
like there is no logfile directory to find log files in. Let me
restate, when we are done with testing we attempt to locate the
logfile down
$MNT_DIR/$EAST_REL/DUT/&lt;dut&gt;/data/logs/regression/testcase/&lt;testcase&gt;.
At this point there should be a time stamped directory. So I'm doing
an ls -t and picking off the first entry.</p>

<p>What I've been finding is that all directories done the path to
&lt;testcase&gt; exist but the &lt;testcase&gt; directory is no there!
I can think of 3 reasons why this might be the case:</p>

<ol>
  <li>The directory just doesn't exist and rantest is right to
  complain.</li>

  <li>The directory does not exist yet because some background process
  has not yet created it. Well when I was debugging this I was sitting
  in the debugger looking around for quite some time. In that time no
  background process came along to create this directory. Besides all
  testing processing has terminated long ago.</li>

  <li>The directory used to exist and some process, thinking it was
  done with this, decided to get rid of the directory.</li>
</ol>

<p>Any ideas?</p>

<?php copyright();?>
</body>
</html>
