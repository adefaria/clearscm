<!--
File:		addnuser.php,v
Revision:	1.1.1.1

Description:	Pick a user to be added to the exclusion list (-nusers). 

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
include_once ("../streams.php");
$version = "1.0";

if (!empty ($_GET ["stream"])) {
  $stream = $_GET ["stream"];
} // if 

if (!empty ($stream)) {
  $heading = "Select user to allow access to $stream";
} else {
  $heading = "Select user to allow access to &lt;unknown&gt;";
} // if
?>
  <title><?php echo $heading?></title>
</head>

<center><h1><?php echo $heading?></h1></center>

<?php
// Santity check
if (empty ($stream)) {
  error ("Stream parameter not supplied");
} // if

$users = get_usernames ();
asort ($users);
print "<center><form method=\"get\" action=\"mknusers.php\" name=\"add_nuser\">\n";
print "<input type=hidden name=stream value=$stream>\n";
print "<select name=\"user\" class=\"inputfield\">\n";
foreach ($users as $key => $user) {
  print "<option>$user</option>\n";
} // foreach
?>
</select>

&nbsp;<input type="submit" value="Select"></p>
</form></center>

<center>
<p><small><a href="/nusers_stream">Manage Stream Locks Home</a></small></p>
<?php copyright (null ,$version);?>
</center>
</body>
</html>
