<?php 
include "site-functions.php";
include "MAPS.php"
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head>
  <title>MAPS: Requirements</title>
  <?php MAPSHeader ()?>
</head>
<body>

<div class="heading">
  <h2 class="header" align="center">
  <font class="standout">MAPS</font> Requirements</h2>
</div>

<div class="content">
  <?php 
  OpenDB ();
  SetContext ($userid);
  NavigationBar ($userid);
  ?>

  <h3>Requirements</h3>

  <p>Requirements for MAPS are minimal. All you need is to do is to <a
  href="/maps/SignupForm.html">Signup</a> for a MAPS account. Other
  than that we believe that you local email client is the best way of
  reading and handling your email. Any email client that supports POP
  will work. If you use MAPS as your email server then you would
  configure your email client to POP off of defaria.com. Alternately
  you can use <a href="MAPSPop.html">MAPSPOP</a> to retrieve your
  email from any email address but filter it through MAPS.</p>

  <p>Additionally you can visit the <a href="/maps">MAPS</a> web site
  to view spam activity, manage your <i>white</i>, <i>black</i> and
  <i>null</i> lists.</p>

  <?php copyright (2001);?>

  </div>
</body>
</html>
