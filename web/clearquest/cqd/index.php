<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
  <meta name="GENERATOR" content="Mozilla/4.61 [en] (Win98; U) [Netscape]">

   <title>ClearSCM: Clearquest: Daemon</title>

  <link rel="stylesheet" type="text/css" media="screen" href="/css/Article.css">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Code.css">
  <link rel="stylesheet" type="text/css" media="print"  href="/css/Print.css">
  <link rel="SHORTCUT ICON" href="http://clearscm.com/favicon.ico" type="image/png">

  <!-- Google Analytics
  <script src="http://www.google-analytics.com/urchin.js" type="text/javascript">
  </script>
  <script type="text/javascript">
    _uacct = "UA-89317-1";
    urchinTracker ();
  </script>
  Google Analytics -->

  <?php
  include "../../php/clearscm.php";
  menu_css ();
  ?>
</head>

<body id="homepage">
<?php heading ();?>

<div id="page">
  <div id="content">
    <?php start_box ("cs3");?>
      <h2>Clearquest Daemon</h2>
    <?php end_box ();?>

  <h3>Overview</h3>

  <p>At a previous company I was asked to provide a mechanism for
  <i>controlled checkins</i> of code into release branches. It was
  decided not to use <font class="standout">Rational's UCM
  Model</font> since the company was small and it's needs were
  simple. Additionally the company wanted to be able to produce
  <i>Release Notes</i> depicting which bugs were fixed in the release
  in an automated fashion. They did not want to incur significant
  overhead when checking in code and wanted to tightly control which
  bugs went into which release branch.</p>

  <?php start_box ("cs2");?>
    <b>Problem Statement:</b> Provide a mechanism for <u>controlled
    checkins</u> and a way to automate Release Notes for releases.
  <?php end_box ();?>

  <h3>Environment</h3>

  <p>The environment of this company was as follows:</p>

  <ul>
    <li>Small company - ~30 Engineers in Santa Clara, USA and ~20 in
    Shanghai, China</li>

    <li>All Windows shop</li>

    <li>Rational Clearcase LT</li>

    <li>Rational Clearquest</li>

    <li>Rational Multisite</li>

    <li>One main server serving both Clearcase and Clearquest</li>

    <li>Slow VPN WAN to Shanghai</li>
  </ul>

  <p>Multisite and the Shanhai office were not initially rolled out
  but the design considered them nonetheless. Unfortunately
  Multisiting of the Clearquest database was ruled out as too
  expensive for our little startup company.</p>

  <h3>Requirements</h3>

  <p>The requirements for this Clearcase/Clearquest integration were as follows:

  <ul>
    <li>Verify that all elements checked into a release branch were associated with
    a Clearquest defect intended for that release.</li>

    <li>Verify the defect was:

    <ul>
      <li>Owned</li>

      <li>Only in certain states (Must be in <font class="standout">Assigned</font>
      or <font class="standout">Resolved</font>).</li>

      <li>On <i>the list</i> of defects for this release.</li>

      <li>Different release branches will have different <i>lists</i>.</li>
    </ul>

    <li>Allow for some branches to not require a defect number while
    those releases were in a state of "development".</li>

    <li>Defect numbers will be entered by the engineers as part of the
    comment. This process should allow multiple defect numbers per
    checkin.</li>

    <li>Provide a way to lock out checkins of defects for building.</li>

    <li>Provide a way to generate Release Notes for a release based on
    the defects fixed.</li>

  </ul>

  <h3>Assumptions</h3>

  <p>There were certain assumptions and other processes already put into place
  that assisted in the solution.</p>

  <ul>
    <li>All checkins that required a bug ID would have a label applied to them
    that consisted of the bug ID.</li>

    <li>When engineers were done checking in these labels would be locked so
    that further checkins for this bug were stopped.</li>

    <li>Engineers would be allowed to continue to work on the release branch
    while the release was building</li>
  </ul>

  <h3>Check In Trigger</h3>

  <ul>
    <li><i>Controlled checkins</i> would be done through a check in
    trigger that would make sure that the conditions were right to
    allow checkin to proceed.</li>

    <li>In order to retrieve data from Clearquest CQPerl was used.</li>

    <li>Initial testing of this trigger showed that it took a very
    long time to connect to the Clearquest database only to retrieve a
    bit of information. If many elements were to be checked in the
    opening and closing of the database made the checkins take
    a long time!

    <li>Our sister lab in Shanghai, China would also participate in
    this process therefore the trigger must also must minimize wait
    time over the WAN.</li>

  </ul>

  <p>A better method was needed<blink>...</blink></p>

  <img src="BeforeCQD.jpg" border=0>

  <h3>Daemon</h3>

  <ul>
    <li>In order to minimize database open/close times a daemon was
    developed that would hold the Clearquest database open and respond
    to requests for information through a socket.</li>

    <li>The daemon would return information about a bug ID to the
    caller. This drastically sped up the process for the Checkin
    Trigger.</li>

    <li>Additionally this general purpose daemon could be used in
    other ways (e.g. Web Page Based Release Notes).</li>
  </ul>

  <img src="CQD.jpg" border=0>

  <h3>CQPerl Problems</h3>

  <p>A good daemon process:</p>

  <ul>
    <li>Puts itself into <i>Daemon mode</i></li>

    <li>Is <font class="standout">Multithreaded</font>. This means
    that it responds to a request and forks a child process off to
    handle the request so that the parent process can accept the next
    client.</li>
  </ul>

  <p>Since, at the time, CQPerl was the only supported way to
  interface with Clearquest it had to be used. Because CQPerl is based
  off of ActiveState Perl a number of problems arose:</p>

  <ol> 
    <li>ActiveState Perl does <b>not</b> support calling <font
    class="standout">setsid</font> which is required to enter
    <i>Daemon mode</i>.</li>

    <li>ActiveState Perl does not reliably handle signals. This mean
    that the parent process could not reliably catch <font
    class="standout">SIGCLD</font> deaths</li>
  </ol>

  <p>As a result the Clearquest Daemon Process is <font
  class="standout">not</font> multithreaded. Since the company
  is small and requests relatively infrequent this was an acceptable
  limitation. Still when processing large lists of Release Notes and
  over the WAN the service would, at times, be unavailable.</p>

  <h3>SetSID</h3>

  <p>The question remained then, <b>How does one go into daemon mode?</b></p>

  <p>Here I resorted to using something that the company was already
  using - <a href="http://cygwin.com">Cygwin</a>.</p>

  <p>Cygwin is a Linux emulation running under Windows. It is one of
  the most complete emulations I have found. We used it to build
  (gnumake) as well as many other things.</p>

  <p>Cygwin has a program called cygrunsrv which allows you to
  daemonize any other process.</p>

  <h3>Multithreading</h3>

  <p>The problem with making the server multithreaded was harder to
  resolve. Code was written to perform multithreading but the
  unreliability of signal handling proved to be a problem that could
  not be easily overcome.</p>

  <p>Options for a multithreading included:</p>

  <ul>
    <li>Figure out how to handle signals properly under ActiveState
    Perl. Research was done on ActiveState's forums and eventually the
    engineer for ActiveState Perl said that signals just can't be
    reliably done under Windows.</li>

    <li>Rewrite code into another language. The client/server could
    have been rewritten into another language that supported
    multithreading however much work had already been done on the
    daemon and a few clients, also written in Perl, would need to also
    be rewritten or interfaced to this other language</li>
  </ul>


  <p>In the end it was decided since the demand on the server would not
  be that great, that a single threaded server would suffice.</p>

  <h3>Client/Server</h3>

  <?php start_box ("cs3");?>
    <b>In depth:</b> Code listings for <a href="cqd.php">CQD
    Daemon</a>, <a href="cqc.php">CQC Client</a> and <a
    href="cqc.pm.php">cqc.pm</a>
  <?php end_box ();?>

  <p>Since this is a client server application the <a href="cqd.php">CQD Daemon</a>
   was written as well as a <a href="cqc.php">CQC Client</a>. A Perl module named 
   <a href="cqc.pm.php">cqc.pm</a> was made to define the API for CDQ.</p>

  <p>The test client, CQC, ended up being a useful command line tool
  to get information about a bug from Clearquest. A user could, for
  example, obtain the owner of a bug by simply doing:</p>

  <div class="code"><pre>
    $ cqc 1234 owner
    swang
    $ cqc 1322 owner headline
    owner: jliu
    headline: Unable to modify ACLS that are created (observed during ACL tests)
    $
  </pre></div>

  <h3>Trigger</h3>

  <?php start_box ("cs3");?>
    <b>In depth:</b> Code listing for <a href="CheckinPreop.php">Check
    in Trigger</a>.
  <?php end_box ();?>

  <p>A preop <i>Checkin Trigger</i> was created to:</p>

  <ul>
    <li>Make sure that a comment was specified</li>

    <li>Extract all bug IDs from the comment</li>

    <li>If the check in was on a release branch requiring bug ID checkin then
    the trigger would make sure:</li>

      <ul>
        <li>The bug ID existed in Clearquest, was owned and in the
        proper state.</li>

        <li>The bug ID label was not locked.</li>

        <li>The bug ID was listed in a file for that release branch
        (i.e. &lt;release branch&gt;.lst)</li>
      </ul>
    </ul>

  <p>A postop <i>Checkin Trigger</i> would then create labels for the
  bug IDs and apply those labels to the checked in elements.</p>

  <h3>Release Notes</h3>

  <?php start_box ("cs3");?>
    <b>In depth:</b> Code listing for <a href="rn.php">Releasenote CGI
    Script</a>.
  <?php end_box ();?>
  
  <p>With the Clearquest Daemon satisifying requests and with the
  Checkin Trigger already relying on a flat file of bug IDs for a
  release, generating a web page of release notes merely involved some
  ordinary formatting of a web page and a calling of the daemon to
  supply Clearquest information in a tabular format.</p>

  <p>Additionally web pages were created to allow addition of bug IDs
  to the release list</p>

  <p>Since CQD returns all fields in the defect record a web page
  showing all details of a defect was also developed</p>

  <p>And example of Release notes is shown <a
  href="Releasenotes.html">here</a>.</p>

</div>

  <?php copyright ();?>  
</div>

<script language="JavaScript" src="/JavaScript/Menus.js" type="text/javascript"></script>

</body>
</html>
