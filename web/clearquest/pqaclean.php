<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
  <meta name="GENERATOR" content="Mozilla/4.61 [en] (Win98; U) [Netscape]">

  <title>ClearSCM: Clearquest: pqaclean</title>
  <link rel="SHORTCUT ICON" href="/clearscm/favicon.ico" type="image/png">

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
      <h2>pqaclean</h2>
        <p>Cleans up by removing all records from the destination
        database as well as removing all Dynamic Lists.</p>
    <?php end_box ();?>

    <?php display_code ("cq/pqaclean");?>
  </div>
  <?php copyright ();?>
</div>

</body>
</html>
