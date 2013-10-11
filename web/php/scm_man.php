<?php
$file = $_REQUEST["file"];
?>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
  <title>ClearSCM: <?php echo $file?></title>
  <link rel="stylesheet" type="text/css" media="screen" href="/css/ManPage.css">
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

<div id="homepage">
<?php heading ();?>

<div id="page">
  <div id="content">
    <?php scm_man ($file);?>
  </div>
</div>

<script language="JavaScript" src="/JavaScript/Menus.js" type="text/javascript"></script>

</body>
</html>
