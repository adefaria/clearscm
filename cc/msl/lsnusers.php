<!--
File:		lsnusers.php,v
Revision:	1.1.1.1

Description:	List users on the exclusion list (-nusers) for the stream lock.

Author:		Andrew@DeFaria.com
Created:	Fri Jul 14 09:44:04 PDT 2006
Modified:	2007/05/17 07:45:48
Language:	PHP

(c) Copyright 2006, Andrew@DeFaria.com, all rights reserved.
-->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <meta name="GENERATOR" content="Mozilla/4.61 [en] (Win98; U) [Netscape]">
  <link rel="stylesheet" type="text/css" href="/css/default.css">
<?php
include_once ("streams.php");
$version = "1.0";

# "Command line" parameters...
if (!empty ($_GET ["stream"])) {
  $stream = $_GET ["stream"];
  $heading = "Stream Locks for stream $stream";
} else {
  $heading = "Stream Locks for stream &lt;unknown&gt:";
} // if

?>
  <title><?php echo $heading?></title>
</head>

<center><h1><?php echo $heading?></h1></center>

<?php
if (empty ($stream)) {
  error ("Stream not specified!");
} // if

$nlocked_users		= get_nusers ($stream);
$nlocked_usernames	= get_usernames ();

if (!empty ($nlocked_users)) {
  print "<p>Users excluded from lock for this stream include:</p>\n";
  print "<blockquote>\n";
  sort ($nlocked_users);
  foreach ($nlocked_users as $user) {
    //print "<li>$user <small><a href=\"private/rmnusers.php?stream=$stream&user=$user\">delete</a></small></li>\n";
    print "<a href=\"private/rmnusers.php?stream=$stream&user=$user\"><img align=top src=\"delete.gif\" alt=\"delete\" heigth=15 width=15 border=0></a>&nbsp;&nbsp;";
    if (array_key_exists ($user, $nlocked_usernames)) {
      print $nlocked_usernames{$user};
    } else {
      print $user;
    } // if
    print "<br>\n";
  } // foreach
} else {
  print "<b><font color=red>Stream $stream is not locked.</font></b>";
} // if

print "</blockquote>\n";
print "<p><a href=\"private/addnuser.php?stream=$stream\">Add new user</a></p>\n";
?>

<center>
<p><small><a href="/nusers_stream">Manage Stream Locks Home</a></small></p>
<?php copyright (null ,$version);?>
</center>
</body>
</html>
