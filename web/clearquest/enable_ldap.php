<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
  <meta name="GENERATOR" content="Mozilla/4.61 [en] (Win98; U) [Netscape]">

  <title>ClearSCM: Clearquest: Enable LDAP</title>

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

<body>

<?php heading ();?>

<div id="page">
  <div id="content">
    <?php start_box ("cs5");?>
      <h2>enable_ldap</h2>
        <p>This script prompts for the data necessary to enable LDAP
        authentication in Clearquest and issue the necessary
        installutil commands to enable LDAP. Reads data from a config
        file.</p>
    <?php end_box ();?>

    <?php display_code ("cq/enable_ldap");?>
  </div>
  <?php copyright ();?>
</div>

<script language="JavaScript" src="/JavaScript/Menus.js" type="text/javascript"></script>

</body>
</html>
