<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
  <meta name="GENERATOR" content="Mozilla/4.61 [en] (Win98; U) [Netscape]">

  <title>ClearSCM: ECRDig</title>

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
  include "clearscm.php";
  menu_css ();
  ?>
</head>

<body id="homepage">

<?php heading ();?>

<div id="page">
  <div id="content">
    <?php start_box ("cs3");?>
      <h2>ECRDig</h2>

      <h4 style="text-align:center">by <a
      href="/people.php">Andrew DeFaria</a></h4>

      <p>ECRs, or Electronic Change Records, was a bug tracking
      systems in used at <a href="http://lynuxworks.com">LynuxWorks,
      Inc.</a>. What started as a simple quest to display an ECR as a
      web pages turned into a full blown, full text search of the
      defect/issue tracking system. Here's how it developed...</p>
    <?php end_box ();?>

    <h3>Introduction</h3>

    <p>While at LynuxWorks I decided to leverage some code that I had
    previously developed (See <a href="/clearquest/cqd">Clearquest
    Daemon</a>) that utilizes a client/server model to provide a
    service that interogates a database and returns information. Again
    this database happens to be a defect tracking database residing on
    another machine.</p>

    <h3>Daemon</h3>

    <p>The daemon opens the database then listens on a socket for
    requests, in this case a defect ID, then obtains the detail
    information about the defect and returns it to the caller in the
    form of a Perl hash. This avoids the overhead associated with
    opening and closing the database or otherwise connecting to the
    datastore. The daemon runs continually in the background listening
    for and servicing requests (<a href="ecrd.php">ecrd source
    code</a>).</p>

    <h3>Client</h3>

    <p>The caller, or client, then can process the information in
    anyway they see fit. Often the caller is a Perl or PHP script that
    outputs the information in to a nicely formatted web page but it
    can as easily be a command line tool that spits out the answer to
    a question. For example:<p>

    <div class="code"><pre>
      $ ecrc 142 owner
      adefaria
    </pre></div>
    
    <p>uses a command line client to display the owner of the defect
    142.  (<a href="ecrc.php">ecrc source code</a>).</p>

    <h3>PHP Module</h3>

    <p>As PHP is a nice language for writing dynamic web pages I then
    developed a PHP API library in order to be a client to ecrd which
    was written in Perl. This allowed me to call the daemon to get
    information about a defect then format out whatever web page I
    wanted (<a href="ecrc.php.php">ecrc.php API source code</a>).</p>

    <p>For example, here is an <a href="ecr23184.html">example</a> of
    a web page describing a specific defect. Notics that the ECR
    (LynuxWorks defect tracking system) displays the one line
    description as well as other fields such as State, Status,
    Severity and Fixed info. Additionally the long description is
    displayed as well as parsed for references to other ECRs or
    auxilary files, courtesy of PHP.</p>

    <table border=0 align=right width=300px>
      <tr>
        <td>
          <?php start_box ("cs2");?>
            <p>The link to ECR 22979 will not work unless you are
            within the LynuxWorks Intranet</p>
          <?php end_box ();?>
        </td>
      </tr>
    </table>

    <h3>Tying it into HtDig</h3>

    <p>Since ECRs and their full text descriptions are now available
    via a web link it was relatively trival to hook this up to <a
    href="http://www.htdig.org/">HtDig</a> to enable full text
    searching on all ECRs and their descriptions. All that was needed
    was to produce a web page with all ECRs listed linked to web pages
    of their descriptions. HtDig would then crawl through and index
    everything. Additionally, since the ECR descriptions were scanned
    for references to certain <i>auxilary files</i> (files not
    necessarily in the defect database but on a network accessible
    area and used to further support the ECR in question) HtDig would
    crawl through and index them too. This resulted in a very flexible
    and powerful internal search facility.</p>
  </div>

  <?php copyright ();?>  
</div>

<script language="JavaScript" src="/JavaScript/Menus.js" type="text/javascript"></script>

</body>
</html>
