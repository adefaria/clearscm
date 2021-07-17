<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	$RCSFile$
// Revision:	$Revision: 1.1 $
// Description:	Lists domains
// Author:	Andrew@DeFaria.com
// Created:	Fri Nov 29 14:17:21  2002
// Modified:	$Date: 2013/06/12 14:05:48 $
// Language:	PHP
//
// (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
include "site-functions.php";
include "MAPS.php";

$top = $_REQUEST ["top"];

if (!$top) {
  $top = 20;
} // if
?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head>
  <title>MAPS: Returned Messages by Domain</title>
  <?php MAPSHeader ()?>
  <script src="/maps/JavaScript/ListActions.js" type="text/javascript"></script>
</head>
<body>
<div class="heading">
<h2 class="header" align="center">Returned Messages by Domain</h2>
</div>
<div class="content">
  <?php
    OpenDB ();
    SetContext ($userid);
    NavigationBar ($userid);
  ?>
<form method="post" action="/maps/bin/processaction.cgi" enctype="application/x-www-form-urlencoded" name="domains">
<?php ListDomains ($top);?>
</form>
<?php copyright (2001);?>
</div>
</body>
</html>
