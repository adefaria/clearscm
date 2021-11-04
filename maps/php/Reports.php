<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	$RCSFile$
// Revision:	$Revision: 1.1 $
// Description:	MAPS Reports
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
?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head>
  <title>MAPS: Reports</title>
  <?php MAPSHeader ()?>
</head>
<body>
<div class="heading">
<h2 class="header" align="center">Reports</h2>
</div>
<div class="content">
  <?php
    OpenDB ();
    SetContext ($userid);
    NavigationBar ($userid);
  ?>

  <h2>Reports</h2>
  <ul>
    <li><a href="/maps/php/ListDomains.php">Returned messages by domain</a></li>
    <li>Recent Activity</li>
    <li><a href="/maps/php/Space.php">Space Usage</a> (this report may take a while)</li>
  </ul>

  <?php copyright (2001);?>
</div>
</body>
</html>
