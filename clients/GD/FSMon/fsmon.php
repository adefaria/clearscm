<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	fsmon.php
// Description:	Produce a graph of filesystem usage
// Author:	Andrew@ClearSCM.com
// Created:	Mon Apr 28 15:20:06 MST 2008
// Modified:	
// Language:	PHP
//
// (c) Copyright 2008, ClearSCM Inc., all rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
$script = basename ($_SERVER["PHP_SELF"]);

include_once "FsmonDB.php";
include_once "Fsutils.php";

$version = VERSION;

$system	= $_REQUEST["system"];
$mount	= $_REQUEST["mount"];
$period	= $_REQUEST["period"];
$scale	= $_REQUEST["scale"];

function createHeader () {
  global $version, $system, $mount;

  $sysLabel	= (empty ($system)) ? "All Systems"	: $system;
  $mountLabel	= (empty ($mount))  ? "All Filesystems" : $mount;

  $header = <<<END
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Testing.css">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Tables.css">
  <title>FSMon v($version) $sysLabel - $mountLabel</title>
</head>
<body>
END;

  $header .= banner ();
  $header .= <<<END
<h1 align="center">Filesystem Monitor</h1>
END;

  return $header;
} // createHeader

function createPage ($system, $mount = "", $period = "daily", $scale = "gig") {
  $data = getFSInfo ($system, $mount, $period);

  $page .= <<<END
<table align=center>
  <thead>
    <tr>
      <th class="left">System</th>
      <th>Mount Point</th>
      <th>Timestamp</th>
      <th>Size</th>
      <th>Used</th>
      <th>Free</th>
      <th class="right">Reserve</th>
    </tr>
  </thead>
  <tbody>
END;

  foreach ($data as $line) {
    $page .= <<<END
      <tr class="white">
        <td>$line[sysname]</td>
        <td>$line[mount]</td>
        <td>$line[timestamp]</td>
        <td align="right">$line[size]</td>
        <td align="right">$line[used]</td>
        <td align="right">$line[free]</td>
        <td align="right">$line[reserve]</td>
      </tr>
END;
  } // foreach
    
  $page .=<<<END
  </tbody>
</table>
END;

  return $page;
} // createPage

function displayReport ($system = "", $mount = "", $period = "daily", $scale = "gig") {
  print createPage ($system, $mount, $period, $scale);
} // displayReport

function displayMount ($system = "", $mount = "", $period = "daily", $scale = "gig") {
  global $script;

  print <<<END
<table cellspacing="0" align="center">
  <tr>
    <form action="$script">
    <td align="center">System:&nbsp;
      <select name="system" class="inputfield">
END;

 foreach (getSystem () as $item) {
   print "<option";

   if ($item["name"] == $system) {
     print " selected=\"selected\"";
   } // if

   print ">$item[name]</option>";
 } // foreach

  print <<<END
      </select>
    &nbsp;Mount:&nbsp;
      <select name="mount" class="inputfield">
END;

  foreach (getMounts ($system) as $item) {
    print "<option";

    if ($item == $mount) {
      print " selected=\"selected\"";
    } // if

    print ">$item</option>";
  } // foreach

  print <<<END
      </select>
    &nbsp;Period:&nbsp;
      <select name="period" class="inputfield">
END;

  foreach (getPeriods () as $item) {
   print "<option";

   if ($item == $period) {
     print " selected=\"selected\"";
   } // if

   print ">$item</option>";
 } // foreach

  print <<<END
      </select>
    &nbsp;Scale:&nbsp;
      <select name="scale" class="inputfield">
END;

  foreach (getScales () as $item) {
    print "<option";

    if ($item == $scale) {
      print " selected=\"selected\"";
    } // if

    print ">$item</option>";
  } // foreach

  print <<<END
      </select>
      &nbsp;<input type="submit" value="Graph" /></form>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="graphFS.php?system=$system&mount=$mount&period=$period&scale=$scale">
    </td>
  </tr>
</table>
END;
//  displayReport ($system, $mount, $period, $scale);
} // displayMount

function displayFilesystems ($system = "", $mount = "", $period = "daily", $scale = "gig") {
  if (empty ($mount)) {
    foreach (getMounts ($system) as $mount) {
      displayMount ($system, $mount, $period, $scale);
      print "<p></p>";
    } // foreach
  } else {
    displayMount ($system, $mount, $period, $scale);
  } // if
} // displayFilesystems

function displayGraph ($system = "", $mount = "", $period = "daily", $scale = "gig") {
  print createHeader ();

  if (empty ($system)) {
    foreach (getSystem () as $system) {
      displayFilesystems ($system["name"], $mount, $period, $scale);
    } // foreach
  } else {
    displayFilesystems ($system, $mount, $period, $scale);
  } // if
} // displayGraph

openDB ();

if (empty ($system)) {
  print createHeader ();
  print "<ul>";

  foreach (getSystem () as $system) {
    print "<li><a href=$script?system=$system[name]>$system[name]</a></li>";

//    print "<ul>";

//    $mounts = getMounts ($system["name"]);

//    foreach ($mounts as $mount) {
//      print "<li><a href=$script?system=$system[name]&mount=$mount>$mount</a></li>";
//    } // foreach

//    print "</ul>";
  } // foreach

  print "</ul>";
} else {
  displayGraph ($system, $mount, $period, $scale);
} // if

print copyright ();
?>
</body>
</html>
