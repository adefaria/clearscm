<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:        $RCSFile$
// Revision:    $Revision: 1.1 $
// Description: Main PHP module to MAPS
// Author:      Andrew@DeFaria.com
// Created:     Fri Nov 29 14:17:21  2002
// Modified:    $Date: 2013/06/12 14:05:48 $
// Language:    PHP
//
// (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
// Get userid
if (isset($_REQUEST["userid"])) {
  $userid = $_REQUEST["userid"];
} // if
$from_cookie = false;

if (!isset($userid)) {
  // No userid, see if we have a cookie for it
  $userid=$_COOKIE["MAPSUser"];
  $from_cookie = true;
} // if

$lines = 10;
$Types = array (
  "returned",
  "whitelist",
  "blacklist",
  "registered",
  "mailloop",
  "nulllist"
);

function DBError($msg, $statement) {
  $errno  = mysql_errno();
  $errmsg = mysql_error();
  print "$msg<br>Error # $errno $errmsg";
  print "<br>SQL Statement: $statement";

  exit($errno);
} // DBError

function OpenDB() {
  $db = mysql_connect("localhost", "maps", "spam")
    or DBError("OpenDB: Unable to connect to database server", "Connect");

  mysql_select_db("MAPS")
    or DBError("OpenDB: Unable to select MAPS database", "adefaria_maps");
} // OpenDB

function SetContext($new_userid) {
  global $userid;

  $userid = $new_userid;
} // SetContext

function Encrypt($password, $userid) {
  $statement = "select encode(\"$password\",\"$userid\")";

  $result = mysql_query($statement)
    or DBError("Encrypt: Unable to execute statement", $statement);

  // Get return value, which should be the encoded password
  $row = mysql_fetch_array($result);

  return $row[0];
} // Encrypt

function UserExists($userid) {
  $statement = "select userid, password from user where userid = \"$userid\"";

  $result = mysql_query($statement)
    or DBError ("UserExists: Unable to execute statement", $statement);

  $row = mysql_fetch_array($result);

  $dbuserid   = $row["userid"];
  $dbpassword = $row["password"];

  if ($dbuserid != $userid) {
    return -1;
  } else {
    return $dbpassword;
  } # if
} // UserExists

function Login($userid, $password) {
  $password = Encrypt($password, $userid);

  // Check if user exists
  $dbpassword = UserExists($userid);

  // Return -1 if user doesn't exist
  if ($dbpassword == -1) {
    return -1;
  } // if

  // Return -2 if password does not match
  if ($password != $dbpassword) {
    return -2;
  } else {
    setcookie("MAPSUser", $userid, time()+60*60*24*30, "/maps");
    SetContext($userid);
    return 0;
  } // if
} // Login

function CountList ($type) {
  global $userid;

  $statement = "select count(*) as count from list where type=\"$type\" and userid=\"$userid\"";

  $result = mysql_query($statement)
    or DBError("CountList: Unable to count list: ", $statement);

  // How many rows are there?
  $row = mysql_fetch_array($result);

  return $row["count"];
} // CountList

function FindList($type, $next, $lines) {
  global $db;
  global $userid;
  global $lines;

  $statement = "select * from list where type=\"$type\" and userid=\"$userid\" order by sequence limit $next, $lines";

  $result = mysql_query($statement)
    or DBError ("FindList: Unable to execute query: ", $statement);

  $count = mysql_num_rows($result);

  return array($count, $result);
} // FindList

function Today2SQLDatetime() {
  return date ("Y-m-d H:i:s");
} // Today2SQLDatetime

function countem($table, $condition) {
  $statement = "select count(distinct sender) as count from $table where $condition";

  $result = mysql_query($statement)
    or DBError("countem: Unable to perform query: ", $statement);

  // How many rows are there?
  $row = mysql_fetch_array($result);

  return $row["count"];
} // countem

function countlog($condition="") {
  global $userid;

  if ($condition != "") {
    return countem("log", "userid=\"$userid\" and " . $condition);
  } else {
    return countem("log", "userid=\"$userid\"");
  } // if
} // countlog

function SubtractDays($date, $nbr_days) {

} // SubtractDays

function GetStats($nbr_days, $date = "") {
  global $Types;

  if ($date == "") {
    $date = Today2SQLDatetime();
  } // if

  while ($nbr_days > 0) {
    $ymd = substr($date, 0, 10);
    $sod = $ymd . " 00:00:00";
    $eod = $ymd . " 23:59:59";

    foreach ($Types as $type) {
      $condition = "type=\"$type\" and (timestamp > \"$sod\" and timestamp < \"$eod\")";
      $stats[$type] = countlog($condition);
    } # foreach

    $dates[$ymd] = &$stats;

    $date = SubtractDays($date, 1);
    $nbr_days--;
  } # while

  return $dates;
} # GetStats

function displayquickstats() {
  $today = substr (Today2SQLDatetime(), 0, 10);
  $dates = getquickstats($today);
  $current_time = date("g:i:s a");

  // Start quickstats
  print "<div class=quickstats>";
  print "<h4 align=center class=header>Today's Activity</h4>";
  print "<p align=center><b>as of $current_time</b></p>";

  $processed     = $dates[$today]["processed"];
  $returned      = $dates[$today]["returned"];
  $returned_pct  = $processed == 0 ? 0 :
    number_format ($returned / $processed * 100, 1, ".", "");
  $whitelist     = $dates[$today]["whitelist"];
  $whitelist_pct = $processed == 0 ? 0 :
    number_format ($whitelist / $processed * 100, 1, ".", "");
  $blacklist     = $dates[$today]["blacklist"];
  $blacklist_pct = $processed == 0 ? 0 :
    number_format ($blacklist / $processed * 100, 1, ".", "");
  $registered    = $dates[$today]["registered"];
  $mailloop      = $dates[$today]["mailloop"];
  $nulllist      = $dates[$today]["nulllist"];
  $nulllist_pct  = $processed == 0 ? 0 :
    number_format ($nulllist / $processed * 100, 1, ".", "");

  $returned_link = $returned == 0 ? 0 :
    "<a href=/maps/bin/detail.cgi?type=returned;date=$today>$returned</a>";
  $whitelist_link = $whitelist == 0 ? 0 :
    "<a href=/maps/bin/detail.cgi?type=whitelist;date=$today>$whitelist</a>";
  $blacklist_link = $blacklist == 0 ? 0 :
    "<a href=/maps/bin/detail.cgi?type=blacklist;date=$today>$blacklist</a>";
  $registered_link = $registered == 0 ? 0 :
    "<a href=/maps/bin/detail.cgi?type=registered;date=$today>$registered</a>";
  $mailloop_link = $mailloop == 0 ? 0 :
    "<a href=/maps/bin/detail.cgi?type=mailloop;date=$today>$mailloop</a>";
  $nulllist_link = $nulllist == 0 ? 0 :
    "<a href=/maps/bin/detail.cgi?type=nulllist;date=$today>$nulllist</a>";

print <<<EOT
<table cellpadding="2" border="0" align="center" cellspacing="0">
  <tr align="right">
    <td align="right" class="smalllabel">Processed</td>
    <td align="right" class="smallnumber">$processed</td>
    <td align="right" class="smallnumber">n/a</td>
  </tr>
  <tr align="right">
    <td class="smalllabel">Returned</td>
    <td class=smallnumber>$returned_link
    <td class="smallnumber">$returned_pct%</td>
  </tr>
  <tr align="right">
    <td class="smalllabel">Whitelist</td>
    <td class="smallnumber">$whitelist_link
    <td class="smallnumber">$whitelist_pct%</td>
  </tr>
  <tr align="right">
    <td class="smalllabel">Blacklist</td>
    <td class="smallnumber">$blacklist_link
    <td class="smallnumber">$blacklist_pct%</td>
  </tr>
  <tr align="right">
    <td class="smalllabel">Registered</td>
    <td class="smallnumber">$registered_link
    <td class="smallnumber">n/a</td>
  </tr>
  <tr align="right">
    <td class="smalllabel">Mailloop</td>
    <td class="smallnumber">$mailloop_link
    <td class="smallnumber">n/a</td>
  </tr>
  <tr align="right">
    <td class="smalllabel">Nulllist</td>
    <td class="smallnumber">$nulllist_link
    <td class="smallnumber">$nulllist_pct%</td>
  </tr>
</table>
</div>
EOT;
} // displayquickstats

function getquickstats($date) {
  global $Types;

  $dates = GetStats(1, $date);

  foreach ($Types as $type) {
    if (isset ($dates[$date]["processed"])) {
      $dates[$date]["processed"] += $dates[$date][$type];
    } else {
      $dates[$date]["processed"] = $dates[$date][$type];
    } // if
  } # foreach

  return $dates;
} // getquickstats

function NavigationBar($userid) {
  print "<div id=leftbar>";

  if (!isset ($userid) || $userid == "") {
    print <<<END
  <div class="username">Welcome to MAPS</div>
    <div class="menu">
    <a href="/maps/doc/">What is MAPS?</a><br>
    <a href="/maps/doc/SPAM.php">What is SPAM?</a><br>
    <a href="/maps/doc/Requirements.php">Requirements</a><br>
    <a href="/maps/SignupForm.html">Signup</a><br>
    <a href="/maps/doc/Using.php">Using MAPS</a><br>
    <a href="/maps/doc/">Help</a><br>
    </div>
END;
  } else {
    $Userid = ucfirst($userid);
    print <<<END
  <div class="username">Welcome $Userid</div>
    <div class="menu">
    <a href="/maps/">Home</a><br>
    <a href="/maps/bin/stats.cgi">Statistics</a><br>
    <a href="/maps/bin/editprofile.cgi">Profile</a><br>
    <a href="/maps/php/Reports.php">Reports</a><br>
    <a href="/maps/php/list.php?type=white">White</a><br>
    <a href="/maps/php/list.php?type=black">Black</a><br>
    <a href="/maps/php/list.php?type=null">Null</a><br>
    <a href="/maps/doc/">Help</a><br>
    <a href="/maps/adm/">Admin</a><br>
    <a href="/maps/?logout=yes">Logout</a>
    </div>
END;
    print <<<END
  <div class="search">
  <form method="get" action="/maps/bin/search.cgi" name="search">
    Search Sender/Subject
    <input type="text" class="searchfield" id="searchfield" name="str"
     size="20" maxlength="255"  value="" onclick="document.search.str.value='';">
  </form>
  </div>
END;

    displayquickstats();

    print <<<END
  <div class="search">
  <form "method"=post action="javascript://" name="address"
   onsubmit="checkaddress(this);">
    Check Email Address
    <input type="text" class="searchfield" id="searchfield" name="email"
     size="20" maxlength="255" value="" onclick="document.address.email.value = '';">
  </form>
  </div>
END;
  } // if

  print "</div>";
} # NavigationBar

function GetUserLines() {
  global $userid;

  $lines = 10;

  $statement = "select value from useropts where userid=\"$userid\" and name=\"Page\"";

  $result = mysql_query($statement)
    or DBError("GetUserLines: Unable to execute query: ", $statement);

  $row = mysql_fetch_array ($result);

  if (isset ($row["value"])) {
    $lines = $row["value"];
  } // if

  return $lines;
} // GetUserLines

function DisplayList($type, $next, $lines) {
  global $userid;
  global $total;
  global $last;

  $statement = "select * from list where userid=\"$userid\" and type=\"$type\" order by sequence limit $next, $lines";

  $result = mysql_query($statement)
    or DBError("DisplayList: Unable to execute query: ", $statement);

  for ($i = 0; $i < $lines; $i++) {
    $row = mysql_fetch_array ($result);

    if (!isset ($row ["sequence"])) {
      break;
    } // if

    $sequence  = $row["sequence"];
    $username  = $row["pattern"]   == "" ? "&nbsp;" : $row["pattern"];
    $domain    = $row["domain"]    == "" ? "&nbsp;" : $row["domain"];
    $hit_count = $row["hit_count"] == "" ? "&nbsp;" : $row["hit_count"];
    $last_hit  = $row["last_hit"]  == "" ? "&nbsp;" : $row["last_hit"];
    $comments  = $row["comment"]   == "" ? "&nbsp;" : $row["comment"];

    // Remove time from last hit
    $last_hit = substr($last_hit, 0, (strlen($last_hit) - strpos($last_hit, " ")) + 1);

    // Reformat last_hit
    $last_hit = substr ($last_hit, 5, 2) . "/" .
                substr ($last_hit, 8, 2) . "/" .
                substr ($last_hit, 0, 4);
    $leftclass  = ($i == $lines || $sequence == $total || $sequence == $last) ?
      "tablebottomleft" : "tableleftdata";
    $dataclass  = ($i == $lines || $sequence == $total || $sequence == $last) ?
      "tablebottomdata"  : "tabledata";
    $rightclass = ($i == $lines || $sequence == $total || $sequence == $last) ?
      "tablebottomright" : "tablerightdata";

    print "<td class=$leftclass align=center>"  . $sequence  . "</td>";
    print "<td class=$dataclass align=center><input type=checkbox name=action" . $sequence . " value=on></td>\n";
    print "<td class=$dataclass align=right>"   . $username  . "</td>";
    print "<td class=$dataclass align=center>@</td>";
    print "<td class=$dataclass align=left><a href=\"http://$domain\" target=_blank>$domain</a></td>";
    print "<td class=$dataclass align=right>"   . $hit_count . "</td>";
    print "<td class=$dataclass align=center>"  . $last_hit  . "</td>";
    print "<td class=$rightclass align=left>"   . $comments  . "</td>";
    print "</tr>";
  } // for
} // DisplayList

function MAPSHeader() {
  print <<<END
  <meta name="author" content="Andrew DeFaria <Andre@DeFaria.com>">
  <meta name="MAPS" "Mail Authorization and Permission System">
  <meta name="keywords" content="Eliminate SPAM, Permission based email, SPAM filtering system">
  <meta http-equiv=Refresh content="900">
  <link rel="icon" href="/maps/MAPS.png" type="image/png">
  <link rel="SHORTCUT ICON" href="/maps/favicon.ico">
  <link rel="stylesheet" type="text/css" href="/maps/css/MAPSStyle.css"/>
  <script language="JavaScript1.2" src="/maps/JavaScript/MAPSUtils.js"
   type="text/javascript"></script>
  <script language="JavaScript1.2" src="/maps/JavaScript/CheckAddress.js"
   type="text/javascript"></script>
END;
} // MAPSHeader

function ListDomains($top = 10) {
  global $userid;

  // Generate a list of the top 10 spammers by domain
  $statement = "select count(sender) as nbr, ";
  // Must extract domain from sender...
  $statement = $statement . "substring(sender, locate(\"@\",sender, 1)+1) as domain ";
  // From email for the current userid...
  $statement = $statement . "from email where userid=\"$userid\" ";
  // Group things by domain but order them descending on nbr...
  $statement = $statement . "group by domain order by nbr desc";

  // Do the query
  $result = mysql_query($statement)
    or DBError("ListDomains: Unable to execute query: ", $statement);

  print <<<END
  <table border="0" cellspacing="0" cellpadding="4" align="center" name="domainlist">
    <tr>
      <th class="tableleftend">Mark</th>
      <th class="tableheader">Ranking</th>
      <th class="tableheader">Domain</th>
      <th class="tablerightend">Returns</th>
    </tr>
END;

  // Get results
  for ($i = 0; $i < $top; $i++) {
    $row = mysql_fetch_array ($result);
    $domain = $row["domain"];
    $nbr    = $row["nbr"];

    print "<tr>";
    $ranking = $i + 1;
    if ($i < $top - 1) {
      print "<td class=tableleftdata align=center><input type=checkbox name=action" . $i . " value=on></td>\n";
      print "<td align=center class=tabledata>" . $ranking . "</td>";
      print "<td class=tabledata>$domain</td>";
      print "<input type=hidden name=email$i value=\"@$domain\">";
      print "<td align=center class=tablerightdata>$nbr</td>";
    } else {
      print "<td class=tablebottomleft align=center><input type=checkbox name=action" . $i . " value=on></td>\n";
      print "<td align=center class=tablebottomdata>" . $ranking . "</td>";
      print "<td class=tablebottomdata>$domain</td>";
      print "<input type=hidden name=email$i value=\"@$domain\">";
      print "<td align=center class=tablebottomright>$nbr</td>";
    } // if
    print "</tr>";
  } // for

  print <<<END
  <tr>
    <td align=center colspan=4><input type="submit" name="action" value="Nulllist" onclick="return CheckAtLeast1Checked (document.domains);" /><input type="submit" name="action" value="Reset" onclick="return ClearAll (document.domains);" />
    </td>
  </tr>
<table>
END;
} // ListDomains

function Space() {
  global $userid;

  // Tally up space used by $userid
  $space = 0;

  $statement = "select * from email where userid = \"$userid\"";

  $result = mysql_query($statement)
    or DBError("Space: Unable to execute query: ", $statement);

  while ($row = mysql_fetch_array ($result)) {
    $msg_space =
      strlen($row["userid"])    +
      strlen($row["sender"])    +
      strlen($row["subject"])   +
      strlen($row["timestamp"]) +
      strlen($row["data"]);
    $space = $space + $msg_space;
  } // while

  return $space;
} // Space
?>
