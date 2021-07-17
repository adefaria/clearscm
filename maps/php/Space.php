<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	$RCSFile$
// Revision:	$Revision: 1.1 $
// Description:	Reports user's database space usage
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
  <title>MAPS: Space Usage</title>
  <?php
    MAPSHeader ();
    $Userid = ucfirst ($userid);
  ?>
</head>
<body>
<div class="heading">
<h2 class="header" align="center">Space Usage for <?php echo $Userid?></h2>
</div>
<div class="content">
  <?php
    OpenDB();
    SetContext ($userid);
    NavigationBar ($userid);

    $space = Space();

    $one_meg = 1024 * 1024;

    if ($space > $one_meg) {
      $space = number_format ($space / $one_meg, 1);
      print "$Userid is using up $space Megabytes of space in the database";
    } elseif ($space > 0) {
      $space = number_format ($space / 1024, 0);
      print "$Userid is using up $space Kbytes of space in the database";
    } else {
      print "$Userid is using up no space in the database";
    } // if

    CloseDB();

    copyright (2001);
  ?>
</div>
</body>
</html>
