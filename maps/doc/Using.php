<?php
include "site-functions.php";
include "MAPS.php"
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head>
  <title>MAPS: Using</title>
  <?php MAPSHeader ()?>
</head>
<body>

<div class="heading">
  <h2 class="header" align="center">Using</h2>
</div>

<div class="content">
  <?php
  OpenDB ();
  SetContext ($userid);
  NavigationBar ($userid);
  ?>

  <h3>Using MAPS</h3>

  <p>To be completed...</p>

  <?php copyright (2001);?>

  </div>
</body>
</html>
