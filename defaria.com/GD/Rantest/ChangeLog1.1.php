<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	Changelog1.1.php
// Revision:	1.1
// Description:	Change log for rantest 1.1
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

<?php print banner ()?>

<h1 align=center>RANTEST 1.1 ChangeLog</h1>

<ul>
   <li><a href="#1.1.6">Version 1.1.6</a></li>

   <li><a href="#1.1.5">Version 1.1.5</a></li>

   <li><a href="#1.1.4">Version 1.1.4</a></li>

   <li><a href="#1.1.3">Version 1.1.3</a></li>

   <li><a href="#1.1.2">Version 1.1.2</a></li>

   <li><a href="#1.1.1">Version 1.1.1</a></li>

   <li><a href="#1.1.0">Version 1.1.0</a></li>
</ul>

<p>This is the ChangeLog for RANTEST for versions 1.1 and up.</p>

<p>See also:</p>

<ul>
  <li><a href="ChangeLog0.9.php">RANTEST 0.9 ChangeLog</a></li>

  <li><a href="ChangeLog1.0.php">RANTEST 1.0 ChangeLog</a></li>

  <li><a href="ChangeLog.php">RANTEST 1.2 ChangeLog</a></li>
</ul>

<h2><a name="1.1.6">Version 1.1.6</a></h2><hr>

<h3>East.pm:</h3>

<ul>
  <li>Changed to properly set TM500_VIEW and NMS_VIEW into the
  environment of the blade</li>
</ul>

<h2><a name="1.1.5">Version 1.1.5</a></h2><hr>

<h3>East.pm:</h3>

<ul>
  <li>Changed to display error where FEATURE is not set</li>
</ul>

<h2><a name="1.1.4">Version 1.1.4</a></h2><hr>

<h3>Rantest:</h3>

<ul>
  <li>Changed to not use SITE_PERLLIB anymore</li>

  <li>No longer calls fixUpLogs if rantvl has not been run</li>

  <li>Handles -regression and options to tests in suite files
  better</li>
</ul>

<h3>East:</h3>

<ul>
  <li>Rantest no longer assumes that the failed execution of the
  "shell" command has output to explain the error</li>

  <li>The shell subrouting now properly returns status</li>
</ul>

<h2><a name="1.1.3">Version 1.1.3</a></h2><hr>

<h3>Web:</h3>

<ul>
  <li>Changed to sink rantest under it's own directory</li>
</ul>

<h2><a name="1.1.2">Version 1.1.2</a></h2><hr>

<h3>Rantest:</h3>

<ul>
  <li>Changed to check and set PATH when rantest is running in suite
  mode</li>
</ul>

<h2><a name="1.1.1">Version 1.1.1</a></h2><hr>

<h3>Rantest:</h3>

<ul>
  <li>Changed to collect extended logfile even in cases where -timeout
  is defaulted</li>
</ul>

<h2><a name="1.1.0">Version 1.1.0</a></h2><hr>

<h3>Rantest:</h3>

<ul>
  <li>Changed to support new validation API described below</li>
</ul>

<h3>New Validation API</h3>

<p>It was decided to get rantest out of the business of interpreting
validation command lines and instead simply offer <i>variables</i>
which would be available for test writers to use. This is viewed as a
good thing because future validations and validators can be written
and rantest need not be modified to become aware of them. Validations
or val lines become not much different than exec shell lines.</p>

<p>Rantest therefore supports the following pseudo (and non-pseudo)
variables which can be used in val lines (or any other lines for that
matter):</p>

<ul>
  <li>Any variable in your env(1). (e.g. $USER)</li>

  <li>$logpath: Absolute path into the "testlogs" area where logfiles
  will be written.</li>

  <li>$msgdefs: Absolute path into the simdev vob/msgdefs
  directory.</li>

  <li>$validation: Absolute path into the simdev vob/validation
  directory.</li>

  <li>$view: Absolute path to your view</li>

  <LI>Others?</li>
</ul>

<p><u>This, of course, means that val lines have to be 
changed to use the above variables to specify their missing parts.</u> Thus a 
previous val line of simply:</p>

<div class=code><pre>
val:  valMsgs.pl -p MyConfig.txt
</pre></div>

<p>would need to be changed to:</p>

<div class=code><pre>
val:  valMsgs.pl -p $msgdefs/MyConfig.txt -l $logpath/Rantvl/RNCLog.txt
</pre></div>

<p>Note that now the test writer needs to have the valMsgs.pl line
specify RNCLog.txt or RBSLog.txt depending on what type of test they
are doing. IOW rantest no longer is charged with figuring this
out.</p>

<blockquote>
  Note: Rantest validations are currently not in wide use so now is a
  good time to implement this change in the API.
</blockquote>

<p>Similarly, an aal2val line may change from:</p>

<div class=code><pre>
val:  aal2val -config My.conf
</pre></div>

<p>to:</p>

<div class=code><pre>
val:  aal2val -config $validations/My.conf -f $logpath/EASTLogs/Server_Logs/rnc_aal2.log
</pre></div>

<h3>Dynamic filesets:</h3>

<p>Some validations run on a fileset which is not known to the test
writer at the time s/he is writing the test. In such cases you can
designate a fileset that rantest will expand and replace with a comma
separated list full pathnames $[<i>dynamic fileset</i>]. So, for
example, $[/tmp/*] would return a comma separated list of all files
under /tmp. If only a portion of the dynamic file is required you can
include an array reference or a slice. For example:</p>

<div class=code><pre>
val: &lt;<i>validation script</i>&gt; -f $[$logpath/foo*.log][0]
val: &lt;<i>validation script</i>&gt; -f $[$logpath/foo*.log][1..2]
</pre></div>

<p>This would tell rantest to expand $logpath first, then expand the
fileset, then take the first (0th) entry file list for the first
validation, or create a comma separated list of the second and third
pathnames from the file list second validation. So, assuming there
were logfiles with the names foo[1-3].log, rantest would expand the
above giving us:</p>

<div class=code><pre>
val: &lt;<I>validation script</I>&gt; -f /east/seast1/testlogs/testcase1/rnc5/20080917@14;38:03/foo1.log
val: &lt;<I>validation script</I>&gt; -f /east/seast1/testlogs/testcase1/rnc5/20080917@14;38:03/foo2.log,/east/seast1/testlogs/testcase1/rnc5/20080917@14;38:03/foo3.log
</pre></div>

<h3>Notes</h3>

<ol>
  <li>Validations may need to be recorded to expect multiple
  parameters. For example, -f above for &lt;<i>validation
  script</i>&gt; needs to accept multple values for -f (Getopt::Long
  handles this fairly nicely however &lt;<i>validation
  script</i>&gt;'s logic may need to change somewhat).</li>

  <li>When using filesets it's possible that empty lists will be returned. For 
  example, if $[$logpath/foo*.log] evaluates to no files you'll get back 
  nothing. Additionally $[$logpath/foo*.log][10..12] will return nothing 
  assuming there are no files in the 10..12 slice.</li>
</ol>

<p>Our final example is tmiVal, which is using multiple config files
against a dynamic fileset:</p>

<div class=code><pre>
val:  tmiVal -config config1,config2,config3 -configbase $validations \
  -logbase $logpath/TM500Logs -logfiles ${$logbase/TM500Logs/TMI.dl.*}
</pre></div>

<h3>Notes:</h3>

<ol>
  <li>tmiVal needs to be re-written to handle these new options</li>

  <li>-configbase is applied to each leaf node under -config making
  $configbase/config1, $configbase/config2 and $configbase/config3. It
  is tmiVal - not rantest - which applies this rule.</li>

  <li>Similarly $logbase applies to @logfiles like $configbase</li>

  <li>There is no guarantee that there will only be 3 TMI.dl.*
  logfiles nor is the ordering of the fileset guaranteed, save for the
  natural ordering of ls(1).</li>

  <li>The syntax of \ to indicate continue this line is <b>not</b>
  supported by rantest and is used above only to enhance
  readability.</li>
</ol>

<?php copyright();?>
</body>
</html>
