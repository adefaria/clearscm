<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
  <meta name="GENERATOR" content="Mozilla/4.61 [en] (Win98; U) [Netscape]">
  <title>ClearSCM: Triggers</title>
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
    <?php start_box ("cs5")?>
      <h2>Clearcase Triggers and Utilities</h2>
    <?php end_box ();?>

     <p>Many of our consultants have served as Clearcase
     administrators. Along the way we have often developed scripts for
     out clients. It doesn't take long to realize that often you're
     doing the same thing over and over again. This page is a way of
     pulling together and documenting these scripts.</p>

    <h3><a name="triggers"></a>Triggers</h3>

    <p>Clearcase has triggers which are scripts that are executed when
    certain Clearcase operations happen. There are some comon ones and
    some not to common ones. Here are some of them.</p>

    <ul>
      <li><a href="EvilTwin.php">Evil Twin Trigger</a>: Prevents the
      creation of <i>Evil Twins</i>.

      <li><a href="RemoveEmptyBranch.php">Remove Empty Branch</a>:
      Removes empty branches.</p>

      <li><a name="mktriggers"></a><a
      href="/php/scm_man.php?file=cc/mktriggers.pl">mktriggers.pl</a>: Make triggers.</li>
    </ul>
  </div>

  <?php copyright ();?>  
</div>

<script language="JavaScript" src="/JavaScript/Menus.js" type="text/javascript"></script>

</body>
</html>
