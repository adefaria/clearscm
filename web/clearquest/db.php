<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <meta name="GENERATOR" content="Mozilla/4.61 [en] (Win98; U) [Netscape]">

  <title>ClearSCM: Clearquest</title>

  <link rel="stylesheet" type="text/css" media="screen" href="/css/Article.css">
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
      <h2>Clearquest</h2>
    <?php end_box ();?>

    <p>There are many times when we have written custom code to
    interact with Clearquest databases. Below are links to some of the
    code we have developed over the years.</p>

    <p>At one client, we had written a <a
    href="/clearquest/cqd">Clearquest Daemon</a>, a daemon process
    that maintained a connection to a Clearquest database and serviced
    requests for information about Clearquest defects.</p>

    <p>Other Perl scripts had been developed for a client to merge
    together two similar, yet different, Clearquest databases into a
    new combined database. This script, <a
    href="pqamerge.php">pqamerge</a> does just that. Obviously such
    conversions and merges are very specific to the customer at
    hand. Still this script serves to show how to interact with the
    Clearquest API to perform such actions.</p>

    <p>The pqamerge script, while it did perform the merge in general,
    also had a few side scripts that were useful when performing this
    merge:</p>

    <ul>
      <li><a href="PQA.pm.php">PQA.pm</a>: Perl Module to hold common
      routines</li>

      <li><a href="pqamerge.php">pqamerge</a>: Main script - performs
      the merge</li>

      <li><a href="pqaclean.php">pqaclean</a>: Cleans up by removing
      all records from the destination database as well as removing
      all Dynamic Lists.</li>

      <li><a href="CheckCodePage.php">CheckCodePage.pl</a>: Checks to
      see if there are any non US ASCII characters in the database
      fields</li>

      <li><a href="check_attachments.php">check_attachments</a>:
      Checks to make sure that the size of the attachments added up
      after the merge</li>

      <li><a href="listdynlists.php">listdynlist</a>: Lists Dynamic
      Lists present in the database</li>

      <li><a href="enable_ldap.php">enable_ldap</a>: Prompts for the
      data necessary to enable LDAP Authentication in Clearquest and
      issues the necessary installutil commands to enable LDAP. Reads
      data from a config file.</li>
    </ul>
  </div>

  <?php copyright ();?>  
</div>

<script language="JavaScript" src="/JavaScript/Menus.js" type="text/javascript"></script>

</body>
</html>
