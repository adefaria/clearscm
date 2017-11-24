<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	$RCSFile$
// Revision:	$Revision: 1.1 $
// Description:	Process lists
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
  MAPSHeader ();
  $next = (isset ($_GET ["next"])) ? $_GET ["next"] : 0;
  $type = $_GET ["type"];
  if (isset($_GET['message'])) {
    $message = $_GET["message"];
  } else {
    $message = '';
  } // if
  $Type = ucfirst ($type);
  $Userid = ucfirst ($userid);
?>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head>
  <title>MAPS: Manage <?php echo "$Type"?> List</title>
  <script language="JavaScript1.2" src="/maps/JavaScript/ListActions.js"
   type="text/javascript"></script>
<?php 
// Connect to MySQL
OpenDB ();

// Set User context
SetContext ($userid);

// Set $lines
$lines = GetUserLines ();

if (($next - $lines) > 0) {
  $prev = $next - $lines;
} else {
  $prev = $next == 0 ? -1 : 0;
} // if

$total = CountList ($type);
$last = $next + $lines < $total ? $next + $lines : $total;
$last_page = floor ($total / $lines) + 1;
$this_page = $next / $lines + 1;
?>
</head>
<body>

<div class="heading">
  <h2 class="header" align="center">
  <font class="standout">MAPS</font> Manage <?php echo "$Userid's "; echo $Type?> List</h2>
</div>

<div class="content">
  <?php NavigationBar ($userid)?>
  <form method="post" action="/maps/bin/processaction.cgi" name="list">
  <div align="center">
  <?php 
    if ($message != "") {
      print "<center><font class=\"error\">$message</font></center>";
    } // if
    $current = $next + 1;
    print "<input type=hidden name=type value=$type>";
    print "<input type=hidden name=next value=$next>";
    print "Page: <select name=page onChange=\"ChangePage(this.value,'$type','$lines');\"";
    for ($i = 0; $i <= $last_page; $i++) {
      if ($i == ($this_page)) {
        print "<option selected>$i</option>";
      } else {
        print "<option>$i</option>";
      } // if
    } // for
    print "</select>";
    //print "next: $next last_page: $last_page";
    print "&nbsp;of <a href=\"/maps/php/list.php?type=$type&next=" . 
          ($last_page - 1) * $lines . "\">$last_page</a>";
  ?>
  </div>
  <div class="toolbar" align="center">
    <?php
    $prev_button = $prev >= 0 ? 
      "<a href=list.php?type=$type&next=$prev><img src=/maps/images/previous.gif border=0 alt=Previous align=middle accesskey=p></a>" : "";
    $next_button = ($next + $lines) < $total ?
      "<a href=list.php?type=$type&next=" . ($next + $lines) . "><img src=/maps/images/next.gif border=0 alt=Next align=middle accesskey=n></a>" : "";
    print $prev_button;
    ?>
    <input type="submit" name="action" value="Add New Entry"
      onclick="return NoneChecked (document.list);">
    <input type="submit" name="action" value="Delete Marked"
      onclick="return CheckAtLeast1Checked (document.list) && AreYouSure ('Are you sure you want to delete these entries?');">
    <input type="submit" name="action" value="Modify Marked"
      onclick="return CheckAtLeast1Checked (document.list);">
    <input type="submit" name="action" value="Reset Marks"
      onclick="return ClearAll (document.list);">
    <?php print $next_button?>
  </div>
  <table border="0" cellspacing="0" cellpadding="4" width="100%" align="center" name="list">
    <tr>
      <th class="tableleftend">Seq</th>
      <th class="tableheader">Mark</th>
      <th class="tableheader">Username</th>
      <th class="tableheader">@</th>
      <th class="tableheader">Domain</th>
      <th class="tableheader">Hit Count</th>
      <th class="tableheader">Last Hit</th>
      <th class="tablerightend">Comments</th>
    </tr>

    <?php DisplayList ($type, $next, $lines)?>

  </table>
  <br>
  <div align=center>
    <a href="/maps/bin/exportlist.cgi?type=<?php echo $type?>">
    <input type=submit name=export value="Export List"></a>
    <a href="/maps/bin/importlist.cgi?type=<?php echo $type?>">
    <input type=submit name=import value="Import List"></a>
  </div>
  </form>
  <?php copyright (2001)?>

</body>
</html>
