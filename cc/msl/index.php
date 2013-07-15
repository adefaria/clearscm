<!--
File:		index.php,v
Revision:	1.1.1.1

Description:	Manage Stream Locks. This web application allows managers to manage 
		locks on UCM streams. Security is provided through simple Basic 
		Authentication provided by the web server.

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

$heading = "Manage Stream Locks";
?>
  <title><?php echo $heading?></title>
</head>

<center><h1><?php echo $heading?></h1></center>

<p>Popular Streams:</p>

<ul>
  <li><a href="lsnusers.php?stream=RISS15_Integration">RISS15_Integration</a></li>
  <li><a href="lsnusers.php?stream=RISS151_Integration">RISS151_Integration</a></li>
  <li><a href="lsnusers.php?stream=osaka_strm">osaka_strm</a></li>
</ul>

<center>
<form method="get" 
      action="lsnusers.php"
      name="select_stream">

<p><b>All streams:</b>&nbsp;<select name="stream" class="inputfield">
<?php
$streams = get_streams ();
sort ($streams);

foreach ($streams as $stream) {
  print "<option>$stream</option>\n";
} // foreach
?>
</select>

&nbsp;<input type="submit" value="Select"></p>
</form>

<p><small><a href="/">Back to main build page</a></small></p>
</center>
<?php copyright (null ,$version);?>
</body>
</html>
