<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	$RCSFile$
// Revision:	$Revision: 1.1 $
// Description:	Email's password to user who forgot
// Author:	Andrew@DeFaria.com
// Created:	Fri Nov 29 14:17:21  2002
// Modified:	$Date: 2013/06/12 14:05:48 $
// Language:	PHP
//
// (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
include "site-functions.php";
include "MAPS.php"
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head>
  <title>MAPS: Forgot Password</title>
  <?php MAPSHeader ()?>
</head>
<body>

<div class="heading">
  <h2 class="header" align="center">Password Retrieval</h2>
</div>

<div class="content">
  <?php
    OpenDB ();
    $userid = "";
    NavigationBar ($userid);
  ?>

  <h3>Password Retrieval</h3>

  <p>So you forgot your password! Hey it happens. Give us your
  username and select <i>Send Me My Password</i> and we will email you
  your password.</p>

  <form method="post"
  action="/maps/php/emailpassword.php?userid=$userid"
  name="emailpassword">

  <div align="center">

  <input class="inputfield" type="text" name="userid" value="" size="20">

  <p><input type="submit" value="Send Me My Password"></p>

  </div>

  </form>

  <?php copyright (2001);?>

  </div>
</body>
</html>
