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
$VERSION = "4.0";

// Get userid
if (isset($_REQUEST["userid"])) {
  $userid = $_REQUEST["userid"];
} // if
$from_cookie = false;

if (!isset($userid)) {
  // No userid, see if we have a cookie for it
  $userid = $_COOKIE["MAPSUser"];
  $from_cookie = true;

  // If we have a userid from the cookie, reset the cookie to keep the user
  // logged in for another 30 days.
  setcookie("MAPSUser", $userid, time() + 60 * 60 * 24 * 30, "/maps");
} // if

$lines = 10;
$Types = array(
  "returned",
  "whitelist",
  "blacklist",
  "registered",
  "mailloop",
  "nulllist"
);

$db;

function DBError($msg, $statement)
{
  global $db;

  $errno = mysqli_errno($db);
  $errmsg = mysqli_error($db);
  print "$msg<br>Error # $errno $errmsg";
  print "<br>SQL Statement: $statement";

  exit($errno);
} // DBError

function OpenDB()
{
  global $db;

  $db = mysqli_connect("127.0.0.1", "maps", "spam")
    or DBError("OpenDB: Unable to connect to database server", "Connect");

  mysqli_select_db($db, "MAPS")
    or DBError("OpenDB: Unable to select MAPS database", "adefaria_maps");
} // OpenDB

function CloseDB()
{
  global $db;

  if (isset($db)) {
    mysqli_close($db);
  } // if
} // CloseDB

function SetContext($new_userid)
{
  global $userid;

  $userid = $new_userid;
} // SetContext

function Encrypt($password, $userid)
{
  global $db;

  $statement = "select hex(aes_encrypt(\"$password\",\"$userid\"))";

  $result = mysqli_query($db, $statement)
    or DBError("Encrypt: Unable to execute statement", $statement);

  // Get return value, which should be the encoded password
  $row = mysqli_fetch_array($result);

  return $row[0];
} // Encrypt

function UserExists($userid)
{
  global $db;

  $statement = "select userid, password from user where userid = \"$userid\"";

  $result = mysqli_query($db, $statement)
    or DBError("UserExists: Unable to execute statement", $statement);

  $row = mysqli_fetch_array($result);

  $dbuserid = $row["userid"];
  $dbpassword = $row["password"];

  if ($dbuserid != $userid) {
    return -1;
  } else {
    return $dbpassword;
  } # if
} // UserExists

function Login($userid, $password)
{
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
    setcookie("MAPSUser", $userid, time() + 60 * 60 * 24 * 30, "/maps");
    SetContext($userid);
    return 0;
  } // if
} // Login

function CountList($type)
{
  global $userid, $db;

  $statement = "select count(*) as count from list where type=\"$type\" and userid=\"$userid\"";

  $result = mysqli_query($db, $statement)
    or DBError("CountList: Unable to count list: ", $statement);

  // How many rows are there?
  $row = mysqli_fetch_array($result);

  return $row["count"];
} // CountList

function FindList($type, $next, $lines)
{
  global $db;
  global $userid;
  global $lines;

  $statement = "select * from list where type=\"$type\" and userid=\"$userid\" order by sequence limit $next, $lines";

  $result = mysqli_query($db, $statement)
    or DBError("FindList: Unable to execute query: ", $statement);

  $count = mysqli_num_rows($result);

  return array($count, $result);
} // FindList

function Today2SQLDatetime()
{
  return date("Y-m-d H:i:s");
} // Today2SQLDatetime

function countem($table, $condition)
{
  global $db;

  $statement = "select count(distinct sender) as count from $table where $condition";

  $result = mysqli_query($db, $statement)
    or DBError("countem: Unable to perform query: ", $statement);

  // How many rows are there?
  $row = mysqli_fetch_array($result);

  return $row["count"];
} // countem

function countlog($condition = "")
{
  global $userid;

  if ($condition != "") {
    return countem("log", "userid=\"$userid\" and " . $condition);
  } else {
    return countem("log", "userid=\"$userid\"");
  } // if
} // countlog

function SubtractDays($date, $nbr_days)
{

} // SubtractDays

function GetStats($nbr_days, $date = "")
{
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

function displayquickstats()
{
  $today = substr(Today2SQLDatetime(), 0, 10);
  $dates = getquickstats($today);
  $current_time = date("g:i A");

  // Start quickstats
  print "<div class=\"quickstats\">";
  print "<h4 align=\"center\" class=\"todaysactivity\" title=\"$today\">Today's Activity</h4>";
  print "<p align=\"center\" style=\"font-weight: normal;\">as of $current_time</p>";

  $processed = $dates[$today]["processed"];
  $returned = $dates[$today]["returned"];
  $returned_pct = $processed == 0 ? 0 :
    number_format($returned / $processed * 100, 1, ".", "");
  $whitelist = $dates[$today]["whitelist"];
  $whitelist_pct = $processed == 0 ? 0 :
    number_format($whitelist / $processed * 100, 1, ".", "");
  $blacklist = $dates[$today]["blacklist"];
  $blacklist_pct = $processed == 0 ? 0 :
    number_format($blacklist / $processed * 100, 1, ".", "");
  $registered = $dates[$today]["registered"];
  $mailloop = $dates[$today]["mailloop"];
  $nulllist = $dates[$today]["nulllist"];
  $nulllist_pct = $processed == 0 ? 0 :
    number_format($nulllist / $processed * 100, 1, ".", "");

  $returned_link = $returned == 0 ? '' :
    "<a href=\"/maps/bin/detail.cgi?type=returned;date=$today\">";
  $whitelist_link = $whitelist == 0 ? '' :
    "<a href=\"/maps/bin/detail.cgi?type=whitelist;date=$today\">";
  $blacklist_link = $blacklist == 0 ? '' :
    "<a href=\"/maps/bin/detail.cgi?type=blacklist;date=$today\">";
  $registered_link = $registered == 0 ? '' :
    "<a href=\"/maps/bin/detail.cgi?type=registered;date=$today\">";
  $mailloop_link = $mailloop == 0 ? '' :
    "<a href=\"/maps/bin/detail.cgi?type=mailloop;date=$today>\"";
  $nulllist_link = $nulllist == 0 ? '' :
    "<a href=\"/maps/bin/detail.cgi?type=nulllist;date=$today\">";

  print <<<EOT
<div id="quickstats">
<table cellpadding="2" border="0" align="center" cellspacing="0">
  <tr align="right">
    <td align="right" class="smalllabel">Processed</td>
    <td align="right" class="smallnumber">$processed</td>
    <td align="right" class="smallnumber">n/a</td>
  </tr>
  <tr align="right">
    <td align="right" class="smalllabel">${nulllist_link}Null</a></td>
    <td class="smallnumber">$nulllist</td>
    <td class="smallnumber">$nulllist_pct%</td>
  </tr>
  <tr align="right">
    <td align="right" class="smalllabel">${returned_link}Returned</a></td>
    <td class=smallnumber>$returned</td>
    <td class="smallnumber">$returned_pct%</td>
  </tr>
  <tr align="right">
    <td align="right" class="smalllabel">${whitelist_link}White</a></td>
    <td class="smallnumber">$whitelist</td>
    <td class="smallnumber">$whitelist_pct%</td>
  </tr>
  <tr align="right">
    <td align="right" class="smalllabel">${blacklist_link}Black</a></td>
    <td class="smallnumber">$blacklist</td>
    <td class="smallnumber">$blacklist_pct%</td>
  </tr>
  <tr align="right">
    <td align="right" class="smalllabel">${registered_link}Registered</a></td>
    <td class="smallnumber">$registered</td>
    <td class="smallnumber">n/a</td>
  </tr>
  <tr align="right">
    <td align="right" class="smalllabel">${mailloop_link}Mailloop</a></td>
    <td class="smallnumber">$mailloop</td>
    <td class="smallnumber">n/a</td>
  </tr>
</table>
</div>
</div>
EOT;
} // displayquickstats

function getquickstats($date)
{
  global $Types;

  $dates = GetStats(1, $date);

  foreach ($Types as $type) {
    if (isset($dates[$date]["processed"])) {
      $dates[$date]["processed"] += $dates[$date][$type];
    } else {
      $dates[$date]["processed"] = $dates[$date][$type];
    } // if
  } # foreach

  return $dates;
} // getquickstats

function NavigationBar($userid)
{
  global $VERSION;

  print "<div id=leftbar>";

  if (!isset($userid) || $userid == "") {
    print <<<END
    <h2 align='center'>MAPS $VERSION</h2>
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
    <h2 align='center'>MAPS $VERSION</h2>
    <div class="username">Welcome $Userid</div>
    <div class="menu">
    <a href="/maps/">Home</a><br>
    <a href="/maps/bin/stats.cgi">Statistics</a><br>
    <a href="/maps/bin/editprofile.cgi">Profile</a><br>
    <a href="/maps/php/ListDomains.php">Top 20</a><br>
    <a href="/maps/php/list.php?type=white">White</a><br>
    <a href="/maps/php/list.php?type=black">Black</a><br>
    <a href="/maps/php/list.php?type=null">Null</a><br>
    <a href="/maps/doc/">Help</a><br>

    <a href="/maps/?logout=yes">Logout</a>
    </div>
END;

    displayquickstats();

    print <<<END
  <div class="search" style="padding-top: 5px;">
  <form method="get" action="/maps/bin/search.cgi" name="search" onsubmit="return checksearch(this);">
    <input type="text" class="searchfield" id="searchfield" name="str"
     size="20" maxlength="255" value="" placeholder="Search Sender/Subject" onclick="document.search.str.value='';">
  </form>
  </div>
END;


  } // if

  print "</div>";
} # NavigationBar

function GetUserLines()
{
  global $userid, $db;

  $lines = 10;

  $statement = "select value from useropts where userid=\"$userid\" and name=\"Page\"";

  $result = mysqli_query($db, $statement)
    or DBError("GetUserLines: Unable to execute query: ", $statement);

  $row = mysqli_fetch_array($result);

  if (isset($row["value"])) {
    $lines = $row["value"];
  } // if

  return $lines;
} // GetUserLines

function DisplayList($type, $next, $lines)
{
  global $userid;
  global $total;
  global $last;
  global $db;

  $statement = "select * from list where userid=\"$userid\" and type=\"$type\" order by sequence limit $next, $lines";

  $result = mysqli_query($db, $statement)
    or DBError("DisplayList: Unable to execute query: ", $statement);

  for ($i = 0; $i < $lines; $i++) {
    $row = mysqli_fetch_array($result);

    if (!isset($row["sequence"])) {
      break;
    } // if

    $sequence = $row["sequence"];
    $username = $row["pattern"] == "" ? "&nbsp;" : $row["pattern"];
    $domain = $row["domain"] == "" ? "&nbsp;" : $row["domain"];
    $hit_count = $row["hit_count"] == "" ? "&nbsp;" : $row["hit_count"];
    $last_hit = $row["last_hit"] == "" ? "&nbsp;" : $row["last_hit"];
    $retention = $row["retention"] == "" ? "&nbsp;" : $row["retention"];
    $comments = $row["comment"] == "" ? "&nbsp;" : $row["comment"];

    // Colorize language rejection messages
    if (preg_match("/.*email rejected/i", $comments)) {
      $comments = "<span class=\"error\">$comments</span>";
    }

    // Remove time from last hit
    $last_hit = substr($last_hit, 0, (strlen($last_hit) - strpos($last_hit, " ")) + 1);

    // Reformat last_hit
    $last_hit = substr($last_hit, 5, 2) . "/" .
      substr($last_hit, 8, 2) . "/" .
      substr($last_hit, 0, 4);
    $leftclass = ($i == $lines || $sequence == $total || $sequence == $last) ?
      "tablebottomleft" : "tableleftdata";
    $dataclass = ($i == $lines || $sequence == $total || $sequence == $last) ?
      "tablebottomdata" : "tabledata";
    $rightclass = ($i == $lines || $sequence == $total || $sequence == $last) ?
      "tablebottomright" : "tablerightdata";

    print "<td class=$leftclass align=right>" . $sequence . "<input type=checkbox name=action" . $sequence . " value=on></td>\n";
    print "<td class=$dataclass align=right>" . $username . "</td>";
    print "<td class=$dataclass align=center>@</td>";
    print "<td class=$dataclass align=left><a href=\"http://$domain\" target=_blank>$domain</a></td>";
    print "<td class=$dataclass align=right>" . $hit_count . "</td>";
    print "<td class=$dataclass align=center>" . $last_hit . "</td>";
    print "<td class=$dataclass align=right>" . $retention . "</td>";
    print "<td class=$rightclass align=left>" . $comments . "</td>";
    print "</tr>";
  } // for
} // DisplayList

function MAPSHeader()
{
  $mod_date = date("F d Y @ g:i a", filemtime($_SERVER['SCRIPT_FILENAME']));
  $time = time();
  print <<<END
  <meta name="author" content="Andrew DeFaria <Andre@DeFaria.com>">
  <meta name="last-modified" content="$mod_date">
  <meta name="MAPS" "Mail Authorization and Permission System">
  <meta name="keywords" content="Eliminate SPAM, Permission based email, SPAM filtering system">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv=Refresh content="900">
  <link rel="icon" href="/maps/MAPS.png" type="image/png">
  <link rel="SHORTCUT ICON" href="/maps/MAPS.png" type="image/png">
  <script>
    if (window.top === window.self) {
      window.location.replace("/#maps");
    }
  </script>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Dancing+Script:wght@400;700&family=Inter:wght@400;500;600;700&family=Outfit:wght@500;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/css/style.css?v=$time">
  <link rel="stylesheet" type="text/css" href="/maps/css/MAPSStyle.css?v=$time"/>
  <script language="JavaScript1.2" src="/maps/JavaScript/MAPSUtils.js?v=$time"
   type="text/javascript"></script>
  <script language="JavaScript1.2" src="/maps/JavaScript/CheckAddress.js?v=$time"
   type="text/javascript"></script>
  <script type="text/javascript">
    (function() {
        var isStandalone = (window === window.top);
        if (isStandalone) {
            // Redirect to main shell
            var currentUrl = window.location.pathname + window.location.search;
            // Prevent redirect loops if we are already at root but somehow thinks standalone?
            // Assuming /?url= handles it.
             window.location.href = '/?url=' + encodeURIComponent(currentUrl);
        } else {
            // Embedded mode
            document.documentElement.classList.add('embedded');
            document.addEventListener('DOMContentLoaded', function() {
                document.body.classList.add('embedded');
            });
        }
    })();
  </script>
END;
} // MAPSHeader

function ListDomains($top = 10)
{
  global $userid, $db;

  // Generate a list of the top 10 spammers by domain
  $statement = "select count(sender) as nbr, ";
  // Must extract domain from sender...
  $statement = $statement . "substring(sender, locate(\"@\",sender, 1)+1) as domain ";
  // From email for the current userid...
  $statement = $statement . "from email where userid=\"$userid\" ";
  // Group things by domain but order them descending on nbr...
  $statement = $statement . "group by domain order by nbr desc";

  // Do the query
  $result = mysqli_query($db, $statement)
    or DBError("ListDomains: Unable to execute query: ", $statement);

  print "<div id=highlightrow>";
  print <<<END
  <table border="0" cellspacing="0" cellpadding="4" align="center" name="domainlist">
    <tr>
      <th class="tableleftend">&nbsp;</th>
      <th class="tableheader">Domain</th>
      <th class="tablerightend">Returns</th>
    </tr>
END;

  // Get results
  for ($i = 0; $i < $top; $i++) {
    $row = mysqli_fetch_array($result);
    $domain = $row["domain"];
    $nbr = $row["nbr"];

    print "<tr>";
    $ranking = $i + 1;
    if ($i < $top - 1) {
      print "<td align=center class=tableleftdata>" . $ranking . "<input type=checkbox name=action" . $i . " value=on></td>\n";
      print "<td class=tabledata><a href=\"http://$domain\" target=\"_blank\">$domain</a></td>";
      print "<input type=hidden name=email$i value=\"@$domain\">";
      print "<td align=center class=tablerightdata>$nbr</td>";
    } else {
      print "<td align=center class=tablebottomleft>" . $ranking . "<input type=checkbox name=action" . $i . " value=on></td>\n";
      print "<td class=tablebottomdata><a href=\"http://$domain\" target=\"_blank\">$domain</a></td>";
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
</div>
END;
} // ListDomains

function Space()
{
  global $userid, $db;

  // Tally up space used by $userid
  $space = 0;

  $statement = "select * from email where userid = \"$userid\"";

  $result = mysqli_query($db, $statement)
    or DBError("Space: Unable to execute query: ", $statement);

  while ($row = mysqli_fetch_array($result)) {
    $msg_space =
      strlen($row["userid"]) +
      strlen($row["sender"]) +
      strlen($row["subject"]) +
      strlen($row["timestamp"]) +
      strlen($row["data"]);
    $space += $msg_space;
  } // while

  mysqli_free_result($result);

  return $space;
} // Space
?>