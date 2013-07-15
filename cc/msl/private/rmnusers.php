<!--
File:		rmnusers.php,v
Revision:	1.1.1.1

Description:	Remove a user to the exclusion list (-nusers). 

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

# "Command line" parameters...
if (!empty ($_GET ["stream"])) {
  $stream = $_GET ["stream"];
} // if 
if (!empty ($_GET ["user"])) {
  $user = $_GET ["user"];
} // if 

if (!empty ($stream)) {
  if (!empty ($user)) {
    $heading = "Removing access of $user to $stream";
  } else {
    $heading = "Removing access of &lt;unknown&gt; to $stream";
  } // if
} else {
  $heading = "Removing access of $user to &lt;unknown&gt;";
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

if (empty ($user)) {
  error ("User parameter not supplied");
} // if

$nusers = get_nusers ($stream);

if (!is_member ($user, $nusers)) {
  print "<font color=red><b>ERROR:</b></font> $user is already not allowed access to $stream<br>";
} else {
  $nusers = remove_from_array ($user, $nusers);
  $status = chnusers ($stream, $nusers);

  if ($status == 0) {
    print "$user is no longer allowed to access $stream";
  } else {
    print "<font color=red><b>ERROR:</b></font> Unable to remove $user from $stream";
  } // if
} // if
?>

<center>
<p><small><a href="/nusers_stream/lsnusers.php?stream=<?=$stream?>">Manage Stream Locks for <?=$stream?></a></small></p>
<?php copyright (null ,$version);?>
</center>
</body>
</html>
