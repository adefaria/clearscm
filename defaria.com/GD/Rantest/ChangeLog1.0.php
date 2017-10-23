<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	Changelog1.0.php
// Revision:	1.0
// Description:	Change log for Rantest 1.0
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

<h1 align=center>RANTEST 1.0 ChangeLog</h1>

<ul>
   <li><a href="#1.0.9">Version 1.0.9</a></li>

   <li><a href="#1.0.8b">Version 1.0.8b</a></li>

   <li><a href="#1.0.8a">Version 1.0.8a</a></li>

   <li><a href="#1.0.8">Version 1.0.8</a></li>

   <li><a href="#1.0.7">Version 1.0.7</a></li>

   <li><a href="#1.0.6">Version 1.0.6</a></li>

   <li><a href="#1.0.5d">Version 1.0.5d</a></li>

   <li><a href="#1.0.5c">Version 1.0.5c</a></li>

   <li><a href="#1.0.5b">Version 1.0.5b</a></li>

   <li><a href="#1.0.5a">Version 1.0.5a</a></li>

   <li><a href="#1.0.5">Version 1.0.5</a></li>

   <li><a href="#1.0.4">Version 1.0.4</a></li>

   <li><a href="#1.0.3b">Version 1.0.3b</a></li>

   <li><a href="#1.0.3a">Version 1.0.3a</a></li>

   <li><a href="#1.0.3">Version 1.0.3</a></li>

   <li><a href="#1.0.2b">Version 1.0.2b</a></li>

   <li><a href="#1.0.2a">Version 1.0.2a</a></li>

   <li><a href="#1.0.2">Version 1.0.2</a></li>

   <li><a href="#1.0.1">Version 1.0.1</a></li>

   <li><a href="#1.0">Version 1.0 - First release!</a></li>

</ul>

<p>This is the ChangeLog for RANTEST for versions 1.0 and up.</p>

<p>See also:</p>

<ul>
  <li><a href="ChangeLog0.9.php">RANTEST 0.9 ChangeLog</a></li>

  <li><a href="ChangeLog1.1.php">RANTEST 1.1 ChangeLog</a></li>

  <li><a href="ChangeLog.php">RANTEST 1.2 ChangeLog</a></li>
</ul>

<h2><a name="1.0.9">Version 1.0.9</a></h2><hr>

<h3>East.pm:</h3>

<ul>
  <li>Fixed to properly check in CDR log files when -rfr is
  specified.</li>
</ul>

<h2><a name="1.0.8b">Version 1.0.8b</a></h2><hr>

<h3>East.pm:</h3>

<ul>
  <li>Fixed bug in handling of the case where the test case profile
  was not found but we still go to collect logfiles and fail
  badly. This is now handled better.</li>
</ul>

<h3>Web:</h3>

<ul>
  <li>Change suite report to be ordered in decending order on
  start. Also durations aren't being properly computed when suite
  crosses day boundary.</li>
</ul>

<h2><a name="1.0.8a">Version 1.0.8a</a></h2><hr>

<h3>East.pm:</h3>

<ul>
  <li>Fixed bug where there were no PC Scanner logs but we were not
  returning a proper status.</li>
</ul>

<h2><a name="1.0.8">Version 1.0.8</a></h2><hr>

<h3>East.pm:</h3>

<ul>
  <li>Changed to support creating and collecting of PC Scanner logs if
  rantvl was run and if we were running an RNC test</li>
</ul>

<h2><a name="1.0.7">Version 1.0.7</a></h2><hr>

<h3>Rantest:</h3>

<ul>
  <li>Changed to list validations as they are executed in log output</li>

  <li>Changed to fill in the path information for -config on aal2val
  and tmival validations</li>
</ul>

<h3>East.pm:</h3>

<ul>
  <li>Changed to default timeout to 180 seconds for
  mergeEAST2RNC.pl</li>
</ul>

<h2><a name="1.0.6">Version 1.0.6</a></h2><hr>

<h3>Rantest:</h3>

<ul>
  <li>Added -feature parameter</li>

  <li>Changed to enforce usage of a view context when running a .suite
  file</li>

</ul>

<h3>East.pm:</h3>

<ul>
  <li>Changed connect to accept -feature parameter</li>
</ul>

<h3>Web</h3>

<ul>
  <li>Added DUT to TestHistory</li>
</ul>

<h2><a name="1.0.5d">Version 1.0.5d</a></h2><hr>

<h3>East.pm:</h3>

<ul>
  <li>Changed to accept -timeout parameter for rantvl</li>
</ul>

<h2><a name="1.0.5c">Version 1.0.5c</a></h2><hr>

<h3>East.pm:</h3>

<ul>
  <li>Changed to set the prompt (PS1) to something more
  distinctive. This should fix the "That happened too quickly"
  problem</li>
</ul>

<h2><a name="1.0.5b">Version 1.0.5b</a></h2><hr>

<h3>Rantest:</h3>

<ul>
  <li>Now logs which view is in use for the test</li>
</ul>

<h3>East.pm:</h3>

<ul>
  <li>Added more verbose output when an scp fails</li>

  <li>Changed to retry scp command if it fails</li>

  <li>Fixed -rfr to use proper vob, nms_sim_log</li>
</ul>

<h2><a name="1.0.5a">Version 1.0.5a</a></h2><hr>

<h3>Rantest:</h3>

<ul>
  <li>Fixed bug where rantest erroneously assumes there are
  validations when there isn't.</li>
</ul>

<h3>Web:</h3>

<ul>
  <li>Fixed css image</li>
</ul>

<h2><a name="1.0.5">Version 1.0.5</a></h2><hr>

<h3>Rantest:</h3>

<ul>
  <li>Changed some coloring.</li>

  <li>Changed to report shell and rantvl to the database better.</li>

  <li>Changed to call collectExtendedLogfile after each test
  step.</li>

  <li>Changed to fully qualify validations to point into the current
  view instead of reling on the setting of PATH.</li>

  <li>Moved special casing of the elock command closer to
  GetOptions.</li>

  <li>Moved running of validations to runTestFile so that a validation
  failure will properly register that the test failed in the
  database.</li>
</ul>

<h3>East.pm:</h3>

<ul>
  <li>Moved collection of TM500/NMS and CDR logfiles to
  collectExtendedLogfile</li>

  <li>Reverted making of baselines.readme to the old method. Calling
  rebaseNonModifiables.pl, while the right way to go, kept causing
  "NFS Stale File handle" messages. Will revert back to calling
  rebaseNonModifiables.pl when Tom can change this to write to
  stdout. When that happens we can write the file locally
  (rebaseNonModifiables.pl had to run on cclinux, thus writing back to
  NFS) and then check it in remotely.</li>

  <li>Added collection of CDR log files.</li>
</ul>

<h3>Web:</h3>

<ul>
  <li>Recentered the caption on detailed test run page</li>
</ul>

<h2><a name="1.0.4">Version 1.0.4</a></h2><hr>

<h3>Rantest:</h3>

<ul>
  <li>Created an array of validValidations</li>

  <li>Added support for the following new validations</li>

  <ol>
    <li>bc_crc_parse.pl &lt;RBSLog.txt&gt;</li>

    <li>pco.pl -f &lt;PCO...log&gt;</li>

    <li>pco_mrach.pl -f &lt;PCO...log&gt;</li>
  </ol>

  <li>Fixed option processing so that extraneous parameters are now
  caught.</li>
</ul>

<h3>East.pm:</h3>

<ul>
  <li>Removed HACK, COUGH, PHEWY!</li>

  <li>Changed to report test step status correctly when there are
  multiple logs</li>

  <li>Fixed to return Success if exec shell was successful</li>

  <li>Changed to use rebaseNonModifiables.pl -save to capture baselines</li>
</ul>

<h3>Web</h3>

<ul>
  <li>Now sorting by start time the Test Step report</li>

  <li>Fixed versions line by centering and reformatting it</li>
</ul>

<h2><a name="1.0.3b">Version 1.0.3b</a></h2><hr>

<h3>East.pm:</h3>

<ul>
  <li>Changed makeBaselinesReadme to use Tom's rebaseNonModifiables.pl
  with a -save option. This allows us to later on use
  rebaseNonModifiables.pl to restore the baseline configuration
  easily.</li>
</ul>

<h3>Web:</h3>

<ul>
  <li>Added duration column to Test History report.</li>

  <li>Added link for ranscrub log to home page</li>

  <li>Reformatted and centered the versions line on Test Step Run
  report.</li>
</ul>

<h2><a name="1.0.3a">Version 1.0.3a</a></h2><hr>

<h3>East.pm:</h3>

<ul>
 <li>Changed to handle multiple logfiles</li>
</ul>

<h3>Web</h3>

<ul>
  <li>Changed select statement for VersionPerTest.php</li>
</ul>

<h2><a name="1.0.3">Version 1.0.3</a></h2><hr>

<h3>Rantest:</h3>

<ul>
  <li>Added check to insure we are running on seast1</li>

  <li>Added support for gathering of rantvl alarms</li>

  <li>Changed validations to be combined under a directory called
  Validations. rantest now creates log files under Validations and
  also displays them to stdout.</li>

  <li>Added shell option to exec to be able to do an arbitrary shell
  command.</li>
</ul>

<h3>East:</h3>

<ul>
  <li>Added setRantvlStartTime method</li>

  <li>Changed _mkDirElement to create the directory then call mkelem</li>

  <li>Added code to collectLogFiles to get any alarms generated if
  rantvl was started. East takes the setRantvlStartTime and the
  current time to compute what the minute parameter to the moshell
  command lgar needs then uses domsh to perform a lgar &lt;n&gt;m to
  get a list of all alarms generated on the DUT in &lt;n&gt;m. This
  output is redirected to the Rantvl log area named
  [RBS|RNC]Alarms.txt.</li>
</ul>

<h3>Miscellaneous</h3>

<ul>
  <li>Updated the shared pswit authorized_keys file</li>
</ul>

<h2><a name="1.0.2b">Version 1.0.2b</a></h2><hr>

<ul>
  <li>Fixed bug with error handling</li>
</ul>

<h2><a name="1.0.2a">Version 1.0.2a</a></h2><hr>

<ul>
  <li>Added hotfix to fix up log files using Erik's
  mergeEAST2RNC.pl.</li>

  <li>Fixed bug in ranscrub where it calls an unknown subroutine
  (scrub) instead of testLogsScrub. This is the first day we got to
  the 45 day period where scrubbing, as opposed to just compressing,
  has occurred.</li>

  <li>More updates to RantestDesign.php</li>

  <li>Renaming RantestDesign.php -> TestAutomationDesign.php</li>
</ul>

<h2><a name="1.0.2">Version 1.0.2</a></h2><hr>

<ul>
  <li>Fixed to check in parent directory when it was necessary to
  create a new element.</li>
</ul>

<h2><a name="1.0.1">Version 1.0.2</a></h2><hr>

<ul>
  <li>Fixed donightly to use the 1123 view</li>

  <li>Changed to check in newly created directory in _mkDirElement</li>
</ul>

<h2><a name="1.0">Version 1.0 - First release!</a></h2><hr>

<p>While this is the first official release, it doesn't contain really
ground breaking functionality. Just reaching a level of enough
functionally complete code to be considered 1.0. We will obviously
have bug patches and the like but by and large most of the
functionality envisoned is coded.</p>

<h3>Ranscrub:</h3>

<ul>
  <li>Added scrubbing for RantestDB. In the past this was stubbed
  out. Now it actually scrubs various "run" tables like suiterun,
  steprun and the testrun/testruns pair. Parameters are obtained from
  and controlled by ../config/ranscrub.conf. Space savings reporting
  is a little different for RantestDB. Instead we report the number of
  entries scrubbed. This is the total of all of the run table entries
  that were deleted. Not sure how helpful this figure really is except
  to show that we are scrubbing something!</li>
</ul>

<h3>Rantest:</h3>

<ul>
  <li>Added support for new val_groups.pl</li>

  <li>Changed to use .../simdev/test when looking for .test files
  running from a .suite file.</li>

  <li>Changed to prepend -p for valMsgs.pl with
  .../simdev/msgdefs</li>

  <li>Changed to set $_status{Failed} if a validation failed</li>
</ul>

<h3>East.pm:</h3>

<ul>
  <li>Formalized ls -t bug catching logging - for now</li>

  <li>Fixed bug where a testCaseID directory element is created but
  left checked out. We now check that in.</li>

  <li>Added functionality to capture the baselines when we are doing
  Run for Record and checking them into the testCaseID directory as
  baselines.readme.</li>
</ul>

<h3>Web:</h3>

<ul>
  <li>Removed extraneous carriage returns from Testing.css</li>

  <li>Added some additional styles for documentation</li>

  <li>Added docs directory, link in Copyright and both
  RantestDesign.php GuideToAutomatingTests.php</li>
</ul>

<?php copyright();?>
</body>
</html>
