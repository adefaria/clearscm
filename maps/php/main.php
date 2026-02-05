<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	$RCSFile$
// Revision:	$Revision: 1.1 $
// Description:	Display MAPS main page
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

OpenDB();

if (isset($_REQUEST["password"])) {
  $password = $_REQUEST["password"];
} // if

if (isset($userid)) {
  if (!$from_cookie) {
    $result = Login($userid, $password);

    if ($result == -1) {
      header("Location: /maps/?errormsg=User $userid does not exist");
      exit($result);
    } elseif ($result == -2) {
      header("Location: /maps/?errormsg=Invalid password");
      exit($result);
    } // if
  } // if
} else {
  header("Location: /maps/?errormsg=Please specify a username");
  exit($result);
} // if
?>

<!DOCTYPE html
  PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">

<head>
  <title>MAPS: Home</title>
  <?php MAPSHeader() ?>
</head>

<body>

  <div class="heading">
    <h2 class="header" align="center">Spam Elimination</h2>
  </div>

  <div class="content">
    <?php NavigationBar($userid) ?>

    <h3>Welcome to MAPS!</h3>

    <p>This is the main or home page of MAPS. To the left you see a menu
      of choices that you can use to explore MAPS functionality. <a href="/maps/bin/stats.cgi">Statistics</a> gives you
      a view of the
      spam that MAPS has been trapping for you in tabular format. You can
      use <a href="/maps/bin/editprofile.cgi">Edit Profile</a> to change
      your profile information or to change your password.</p>

    <p>MAPS also offers a series of web based <a href="/maps/php/Reports.php">Reports</a> to analyze your mail flow. You
      can manage your <a href="/maps/php/list.php?type=white">White</a>,
      <a href="/maps/php/list.php?type=black">Black</a> and <a href="/maps/php/list.php?type=null">Null</a> lists
      although MAPS
      seeks to put that responsibility on those who wish to email you. You
      can use this to pre-register somebody or to black or null list
      somebody. You can also import/export your lists through these
      pages.
    </p>

    <p><a href="/maps/Admin.html">MAPS Administration</a> is to
      administer MAPS itself and is only available to MAPS
      Administrators.</p>

    <p>Also on the left you will see <i>Today's Activity</i> which
      quickly shows you what mail MAPS processed today for you.</p>

    <?php copyright(2001); ?>

  </div>
</body>

</html>