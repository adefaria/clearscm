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
include "MAPS.php";

$next = (isset ($_GET [next])) ? $_GET[next] : 0;
$userid = $_REQUEST [userid];

// Connect to DB
OpenDB ();
SetContext ($userid);

// Get user information
$statement = "select * from user where userid=\"$userid\"";

$result = mysql_query ($statement)
  or die ("emailpassword: SQL Query failed: " . $statement);

$row = mysql_fetch_array ($result);

$name		= $row [name];
$email		= $row [email];
$password	= $row [password];
$subject	= "Your MAPS Password";

// Decode password 
$statement = "select decode(\"$password\",\"$userid\")";

$result = mysql_query ($statement);

$row = mysql_fetch_array ($result, MYSQL_NUM);

$decoded_password = $row [0];

// Compose email
$message = "
<html>
<head>
 <title>Your MAPS Password</title>
</head>
<body>
<p>Your MAPS Password is $decoded_password</p>

<p>Click <a href=http://defaria.com/maps>here</a> to login to MAPS.
</body>
</html>
";

/* To send HTML mail, you can set the Content-type header. */
$headers  = "MIME-Version: 1.0\r\n";
$headers .= "Content-type: text/html; charset=iso-8859-1\r\n";

/* additional headers */
$headers .= "To: $email\r\n";
$headers .= "From: MAPS <MAPS@defaria.com>\r\n";

/* and now mail it */
$mailed = mail($to, $subject, $message, $headers);
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head>
  <title>MAPS: Password Retrieval</title>
  <?php MAPSHeader ()?>
</head>
<body>

<div class="heading">
  <h2 class="header" align="center">
  <font class="standout">MAPS</font> Password Retrieval</h2>
</div>

<div class="content">
  <?php NavigationBar ("")?>

  <p>Your password has been emailed to <?php echo $email?></p>

  <?php copyright (2001)?>

</body>
</html>
