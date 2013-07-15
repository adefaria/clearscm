<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <meta name="GENERATOR" content="Mozilla/4.61 [en] (Win98; U) [Netscape]">
  <title>ClearSCM Inc.</title>
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Article.css">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Menus.css">
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
  include "../php/clearscm.php";
  menu_css ();
  ?>
</head>

<body id="homepage">
<?php heading ();?>

<div id="page">
  <div id="content">
    <?php start_box ("cs3");?>
      <h2>Clearcase</h2>
    <?php end_box ();?>

    <h3>A Little History</h3>

    <p>Many of our clients utilize IBM Rational Clearcase for their
    SCM system of course. <abbr title="Often spelled as
    ClearCase">Clearcase</abbr> is the Cadillac of SCM systems. Born
    in the old Unix workstation company named Apollo and originating
    from the <abbr title="Distributed Software Engineering
    Environment">DSEE</abbr> project when HP bought out Apollo,
    engineers on DSEE project didn't want to see their beloved DSEE
    die so they started a company named <font
    class=standout>Atria</font>.</p>

    <p>Atria did well and was soon bought out by another software
    company, makers of <font class=standout>Purify</font> - a software
    product that helps developers find memory leaks in their code.</p>

    <p>Later <font class=standout>Rational</font>, purveyors of many
    software engineering environments and tools, bought <font
    class=standout>PureAtria</font> and for many years it was known
    simply as <font class=standout>Rational Clearcase</font>.

    <p>Finally IBM, seeing the wisedom in the <i>Rational Approach</i>,
    bought out Rational where Clearcase, Multisite, Clearquest and the
    rest of the Rational suite of tools reside today.</p>

    <h3>Base Clearcase</h3>

    <p>Base Clearcase is how Clearcase was originally developed. As
    such it's a full featured, large, complex and flexible SCM
    system. Many companies still use Base Clearcase and have build
    their own set of scripts around Base Clearcase to represent,
    control enforce policies and automate workflow. IBM Rational saw
    this and decided to collect the various ways that people use
    Clearcase to come up with UCM. Still developing software is about
    as varied as designing snowflakes so UCM does not always fit the
    environment. As such Base Clearcase is still available and used
    today.</p>

    <h3>Unified Change Management (UCM)</h3>

    <p>Unified Change Management is a layer built on Base
    Clearcase to provide additional Software Configuration Management
    features. These changes include integration with ClearQuest to
    enforce defect and change tracking with code development through
    the use of activities. This is part of the Rational Unified
    Process (RUP) which describes the lifecycle of change management
    for IBM Rational's software development process. It also gives
    integrators ownership of projects and streams to allow policy and
    feature management by project leaders and release engineers. UCM
    removes the ability/requirement that users manage a configuration
    specification for a view. UCM is used and configured via either
    CLIs or GUIs.

    <h3>Multisite</h3>

    <p>Multisite enables fast, reliable access to software assets
    across distributed locations.  This extends software configuration
    management across geographically distributed projects through
    repository replication. This gives you the following benefits:</p>

    <ul>
      <li>Automatic replication and synchronization of Rational
      Clearcase repositories enables access to current information,
      regardless of location</li>

      <li>Simplifies administration with an easy-to-use Web-based
      interface</li>

      <li>Maintains data integrity by resending information in the
      event of network failure and automatic recovery of repositories
      in the event of system failure</li>

      <li>Works with Clearquest&reg; Multisite for integrated workflow
      management and defect and change tracking across multiple
      locations and time zones</li>

      <li>Scales to support thousands of users, working in dozens of
      sites, managing terabytes of data<li>
    </ul>
  </div>

  <?php copyright ();?>  
</div>

<script language="JavaScript" src="/JavaScript/Menus.js" type="text/javascript"></script>

</body>
</html>
