<?php
include "site-functions.php";
include "MAPS.php";

$logout   = $_REQUEST['logout'];
$errormsg = $_REQUEST['errormsg'];

if (isset ($logout)) {
  setcookie ("MAPSUser", "", time()+60*60*24*30, "/maps");
} else {
  if (isset ($userid) && $from_cookie) {
    header ("Location: php/main.php");
    exit;
  } // if
} // if
?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head>
  <title>MAPS: Mail Authorization and Permission System</title>
  <?php MAPSHeader ()?>
</head>
<body>

<div class="heading">
  <h2 class="header" align="center">Mail Authorization and Permission System</h2>
  <h3 class="header" align="center">Spam Elimination System</h3>
</div>

<div class="content">
  <?php
    OpenDB();
    NavigationBar ("");
  ?>

  <p>MAPS is a system for totally eliminating spam from your life.  It
  seeks to minimize the amount of intervention and thus the amount of
  time you spent dealing with unsolicited emails by requiring that all
  email are solicited. MAPS provides a convenient way to manage your
  spam and to allow those you wish to receive email from to be able to
  email you without hassle.</p>

  <p>To learn more about MAPS select an option from the menu on the
  left. Be sure to read <a href="/maps/doc/Using.php">Using MAPS</a>
  to familiarize yourself with how the MAPS system works and to
  configure your email client. Then signup for an account (it's free!)
  and login and enjoy spam free email!</p>

  <form method="post" action="php/main.php"
   enctype="application/x-www-form-urlencoded">

  <table cellpadding="2" bgcolor="white" width="40%" cellspacing="0"
   border="0" align="center">

  <tr>
    <td class="label" valign="middle">Username:
    </td>
    <td valign="middle">
      <input type="text" name="userid" size="20" class="inputfield"></input>
    </td>
  </tr>

  <tr>
    <td class="label" valign="middle">Password:
    </td>
    <td valign="middle">
      <input type="password" name="password" size="20" class="inputfield"></input>
    </td>
  </tr>

  <tr>
    <td colspan="2" align="center"><input type="submit" name="submit" value="Login"></input>
    </td>
  </tr>

  <?php
  if (isset ($errormsg)) {
    print "<tr><td class=error colspan=2 align=center>$errormsg</td></tr>";
  } // if
  ?>

  <tr>
    <td colspan="2" align="center">
      <a href="php/ForgotPassword.php">Forgot your password?</a>
    </td>
  </tr>
  </table>
  </form>

  <?php copyright (2001);?>

  </div>
</body>
</html>
