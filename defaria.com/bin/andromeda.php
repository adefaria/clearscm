<?php
# Welcome to Andromeda!
# ------------------------------------------------------------
# Thanks for choosing to evaluate Andromeda. You'll find it to
# be easy to set up, fully-featured, and highly configurable.
# To get started, please check out the online documentation:
#
#   http://www.turnstyle.com/andromeda/docs.asp
#
# To purchase your copy, please visit:
#
#   http://www.turnstyle.com/andromeda
#
# Note
# ------------------------------------------------------------
# Configure Andromeda with a preference file (don't change any
# of this code). See this page for details:
#
#   http://www.turnstyle.com/andromeda/preferences.asp
#
# If you run multiple copies of Andromeda and want this copy
# to use a different prefs file, you can change the file name
# below.
#
# Any other changes to the code violate the terms of the
# license and will prevent it from working properly.
$andromedaPrefsFileName = "andromedaPrefs.php";

# ------------------------------------------------------------
# License Agreement
# ------------------------------------------------------------
# This software is the copyrighted material of Scott Matthews,
# Turnstyle. This document is a license agreement. By running
# this software on your computer you agree to the terms of
# this license.
#
# The Andromeda Evaluation is licensed for non-commercial,
# evaluation purposes only. The evaluation period is not to
# exceed one month, after which you agree to purchase the
# appropriately licensed version if you choose to continue
# using Andromeda.
#
# Additional licensing information is available from
# info@turnstyle.com.
#
# You agree not to copy or distribute this software or change
# the source code without prior written permission. Please
# send any questions or comments to info@turnstyle.com.
# 
# Scott Matthews, Turnstyle takes no responsibility for any
# damage that this software might cause.
# 
# This software is designed to provide access to collections
# of files. By using it, you agree to comply with all federal
# and state laws applicable to such content, as well as the
# terms of this license. You agree not to use this software
# to distribute or faciliate the distribution of unauthorized
# copies of copyrighted works.
# 
# If you disagree with any of these terms, you are not
# authorized to use this software. If you do agree with these
# terms, please enjoy.
# 
# Copyright (c)1999-2002 Scott Matthews, Turnstyle
# http://www.turnstyle.com/andromeda
# ------------------------------------------------------------
function loadConstants () {
  global $andromedaConst,$SCRIPT_NAME_FIXED,$SCRIPT_PATH_FIXED,$ckServerIP,$REMOTE_ADDR;
  $andromedaConst["andromedaVersion"] = "1.9.3.2 PHP";
  $andromedaConst["localUser"] = ($ckServerIP == $REMOTE_ADDR);
  $andromedaConst["scriptFileName"] = basename($SCRIPT_NAME_FIXED);
  $andromedaConst["scriptPhysicalPath"] = parentFolder($SCRIPT_PATH_FIXED);
  $andromedaConst["moduleMode"] = ($andromedaConst["scriptFileName"] == "modules.php");
  if ($andromedaConst["moduleMode"]) {
    $andromedaConst["scriptPhysicalPath"] .= "/modules/" . basename(dirname(__FILE__));
  }
  $andromedaConst["appauth"] = "Scott Matthews";
  $andromedaConst["appcorp"] = "Turnstyle";
  $andromedaConst["appname"] = "Andromeda";
  $andromedaConst["approot"] = "http://www.turnstyle.com/andromeda";
  $andromedaConst["edition"] = "";
}

function loadDefaults () {
  global $andromedaConst,$andromedaPrefs,$SCRIPT_NAME_FIXED,$SCRIPT_PATH_FIXED;
  $andromedaPrefs["siteName"] = "andromeda";
  $andromedaPrefs["useImageFiles"] = false;
  $andromedaPrefs["imageFolderPath"] = "";
  $andromedaPrefs["displayNew"] = false;
  $andromedaPrefs["displayAMG"] = true;
  $andromedaPrefs["mediaWebPath"] = parentFolder($SCRIPT_NAME_FIXED);
  $andromedaPrefs["mediaPhysicalPath"] = str_replace("\\\\","\\",parentFolder($SCRIPT_PATH_FIXED));
  if ($andromedaConst["moduleMode"]) {
    $andromedaPrefs["mediaWebPath"] .= "/modules/" . basename(dirname(__FILE__));
    $andromedaPrefs["mediaPhysicalPath"] .= "/modules/" . basename(dirname(__FILE__));
  }
  $andromedaPrefs["editMode"] = false;
  $andromedaPrefs["ftpPath"] = "";
  $andromedaPrefs["email"] = "";
  $andromedaPrefs["permitSearch"] = true;
  $andromedaPrefs["hostAddress"] = "";
//  $andromedaPrefs["customHeader"] = "<table cellspacing=0 cellpadding=4 border=0 align=center><tr><td><font size=\"2\">The Andromeda evaluation displays every other file. <a href=\"http://www.turnstyle.com/andromeda/purchase.asp\" target=_blank>[buy&nbsp;now]</a></font></td></tr></table>";
//  $andromedaPrefs["customHeader"] = "";
  $andromedaPrefs["customBlock"] = "";
  $andromedaPrefs["popupMaxWidth"] = 48;
  $andromedaPrefs["folderAux1"] = "";
  $andromedaPrefs["requireLogon"] = false;
  $andromedaPrefs["localFilePlayback"] = false;
  $andromedaPrefs["cBlockSize"] = 3100;
  $andromedaPrefs["cBlockCount"] = 2;
  $andromedaPrefs["audioFileTypes"] = "mp3,wma,wav,aif,aiff,au,ogg,ra,mid,midi";
  $andromedaPrefs["videoFileTypes"] = "mpg,mpeg,mpe,asf,avi,wmv,vob,rv,rm,mov,qt";
  $andromedaPrefs["playlistFileTypes"] = "m3u,asx,ram";
  $andromedaPrefs["tkNumTrimCodes"] = "## - ,##_-_,##_,##.";
  $andromedaPrefs["cssLinkHref"] = "";
  $andromedaPrefs["playlistMime"] = "audio/x-mpegurl";
  $andromedaPrefs["protocol"] = "http";
  $andromedaPrefs["fileLinks"] = true;
  $andromedaPrefs["playLinks"] = true;
  $andromedaPrefs["permitPlaylists"] = true;
  $andromedaPrefs["getID3info"] = true;
  $andromedaPrefs["skipID3v1"] = false;
  $andromedaPrefs["absoluteHeader"] = "";
  $andromedaPrefs["absoluteFooter"] = "";
  $andromedaPrefs["disableHTMLheaders"] = false;
  $andromedaPrefs["includeHeader"] = "";
  $andromedaPrefs["includeFooter"] = "";
  $andromedaPrefs["includeJavascript"] = "";
  $andromedaPrefs["folderListInfo"] = "_folderListInfo";
  $andromedaPrefs["folderOpenInfo"] = "_folderOpenInfo";
  $andromedaPrefs["folderListImage"] = "_folderListImage";
  $andromedaPrefs["folderOpenImage"] = "_folderOpenImage";
  $andromedaPrefs["folderListImageDims"] = "";
  $andromedaPrefs["folderOpenImageDims"] = "";
  $andromedaPrefs["skinFile"] = "andromedaSkin.txt";
  $andromedaPrefs["logonFile"] = "andromedaLogons.php";
  $andromedaPrefs["includeEXTM3U"] = false;
  $andromedaPrefs["defaultLanguage"] = "EN";
  $andromedaPrefs["globalAnnotations"] = true;
  $andromedaPrefs["permitTranslation"] = true;
  $andromedaPrefs["skipPrefix"] = ".";
  $andromedaPrefs["folderSkipNames"] = "_private,_fpclass,_vti_cnf,_vti_pvt,_derived,_overlay,RECYCLER,Recycled,System Volume Information,Network Trash Folder";
  $andromedaPrefs["checkboxDefault"] = false;
  $andromedaPrefs["coreInclude"] = "";
  $andromedaPrefs["moduleOnly"] = false;
  $andromedaPrefs["iconSize"] = 1;
  $andromedaPrefs["useExtLogon"] = false;
  $andromedaPrefs["hideMenubar"] = false;
  $andromedaPrefs["rootName"] = "";
  $andromedaPrefs["maxPlaylistTracks"] = 5000;
  $andromedaPrefs["timeout"] = "";
  $andromedaPrefs["usePlaylistIcons"] = true;
  $andromedaPrefs["vbrScanCount"] = 50;
  $andromedaPrefs["vbrSkipCount"] = 50;
  $andromedaPrefs["cbrCutoff"] = 5;
  $andromedaPrefs["compactSearch"] = false;
  $andromedaPrefs["logonMessage"] = "";
  $andromedaPrefs["fileCount"] = true;
  $andromedaPrefs["fileCountWidth"] = 20;
  $andromedaPrefs["pDimentions"] = "16,16";
  $andromedaPrefs["aDimentions"] = "26,16";
  $andromedaPrefs["vDimentions"] = "26,16";
  $andromedaPrefs["lDimentions"] = "26,16";
  $andromedaPrefs["hDimentions"] = "16,16";
  $andromedaPrefs["iDimentions"] = "16,16";
  $andromedaPrefs["rDimentions"] = "16,16";
  $andromedaPrefs["tDimentions"] = "16,16";
  $andromedaPrefs["oDimentions"] = "20,16";
  $andromedaPrefs["cDimentions"] = "26,16";
  $andromedaPrefs["gDimentions"] = "16,16";
  $andromedaPrefs["qDimentions"] = "16,16";
  $andromedaPrefs["saDimentions"] = "26,16";
  $andromedaPrefs["snDimentions"] = "25,16";
  $andromedaPrefs["psDimentions"] = "42,16";
  $andromedaPrefs["paDimentions"] = "42,16";
  $andromedaPrefs["prDimentions"] = "42,16";
  $andromedaPrefs["pvDimentions"] = "42,16";
  $andromedaPrefs["kDimentions"] = "16,16";
  $andromedaPrefs["siteWidth"] = "100%";
  $andromedaPrefs["bodyBgColor"] = "9999cc";
  $andromedaPrefs["bodyTextColor"] = "333333";
  $andromedaPrefs["bodyLinkColor"] = "666699";
  $andromedaPrefs["bodyVlinkColor"] = "996699";
  $andromedaPrefs["bodyAlinkColor"] = "999966";
  $andromedaPrefs["bodyMarginSize"] = "0";
  $andromedaPrefs["headDiv"] = "";
  $andromedaPrefs["menubarColor"] = "999999";
  $andromedaPrefs["siteNameColor"] = "ffff00";
  $andromedaPrefs["menubarDiv"] = "cccc99,1;9999cc,3;cccc99,1;999999,8;666666,1";
  $andromedaPrefs["bodyFgColor"] = "cccc99";
  $andromedaPrefs["formStyle"] = "font-size:9pt;color:000000;background-color:ffffff;";
  $andromedaPrefs["bodyFgDiv"] = "999966,1;efefcc,1";
  $andromedaPrefs["bodyFgToRowDiv"] = "ffffcc,1";
  $andromedaPrefs["rowColor1"] = "efefd0";
  $andromedaPrefs["rowColor2"] = "efefef";
  $andromedaPrefs["rowLinkColor"] = "";
  $andromedaPrefs["rowTextColor"] = "333333";
  $andromedaPrefs["newFileColor"] = "cc6666";
  $andromedaPrefs["rowDiv"] = "d0d0d0,1";
  $andromedaPrefs["rowToBodyFgDiv"] = "666666,1";
  $andromedaPrefs["footDiv"] = "ffffcc,1;999999,2;666666,1";
}

function loadPrefs () {
  global $andromedaConst,$andromedaPrefs,$andromedaPrefsFileName;
  if (file_exists($andromedaConst["scriptPhysicalPath"] . "/" . $andromedaPrefsFileName)) {
    $fcontents = file ($andromedaConst["scriptPhysicalPath"] . "/" . $andromedaPrefsFileName);
    for ($i = 0; $i < count($fcontents); $i++) {
      $row = $fcontents[$i];
      if (substr($row,0,1) == "#") {
	$rowa = explode("\t",$row);
	if (count($rowa) >= 2) {
	  $keyval = trim(substr($rowa[0],1));
	  $valval = trim($rowa[count($rowa)-1]);
	  if ($valval == "true") {$valval = true;}
	  elseif ($valval == "false") {$valval = false;}
	  $andromedaPrefs[$keyval] = $valval;
	}
      }
    }
  }
}

function loadSkin () {
  global $andromedaConst,$andromedaPrefs;
  if (file_exists($andromedaConst["scriptPhysicalPath"] . "/" . $andromedaPrefs["skinFile"])) {
    $fcontents = file ($andromedaConst["scriptPhysicalPath"] . "/" . $andromedaPrefs["skinFile"]);
    for ($i = 0; $i < count($fcontents); $i++) {
      $row = $fcontents[$i];
      $rowa = explode("\t",$row);
      if (count($rowa) >= 2) {
	$keyval = trim($rowa[0]);
	$valval = trim($rowa[count($rowa)-1]);
	if ($valval == "true") {$valval = true;}
	elseif ($valval == "false") {$valval = false;}
	$andromedaPrefs[$keyval] = $valval;
      }
    }
  }
}

function loadLogons () {
  global $andromedaConst,$andromedaPrefs,$andromedaLogons;
  if (file_exists($andromedaConst["scriptPhysicalPath"] . "/" . $andromedaPrefs["logonFile"])) {
    $fcontents = file ($andromedaConst["scriptPhysicalPath"] . "/" . $andromedaPrefs["logonFile"]);
    for ($i = 0; $i < count($fcontents); $i++) {
      $row = $fcontents[$i];
      if (substr($row,0,1) == "#") {
	$rowa = explode("\t",$row);
	if (count($rowa) >= 2) {
	  $keyval = trim(substr($rowa[0],1));
	  $valval = trim($rowa[count($rowa)-1]);
	  $andromedaLogons[$keyval] = $valval;
	}
      }
    }
  }
}

function vPath ($x) {
  $vpchk = true;
  if ($x != "") {
    $vptmpa = explode("/",str_replace("\\","/",$x));
    if ($vptmpa[0] != "") {$vpchk = false;}
    else {
      for ($vpi = 1; $vpi < count($vptmpa); $vpi++) {
	if (($vptmpa[$vpi] == "") || ($vptmpa[$vpi] == ".") || ($vptmpa[$vpi] == "..")) {
	  $vpchk = false;
	  break;
	}
      }
    }
  }
  return $vpchk;
}

function andromedaHeader ($x) {
  andromedaHeaderCore($x,false);
}

function andromedaHeaderCore ($x,$y) {
  global $andromedaConst, $andromedaPrefs, $clangCodes;
  if (!$andromedaPrefs["disableHTMLheaders"]) {
    echo "<html><head><META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=" . $clangCodes[1] . "\"><title>" . htmlspecialchars($andromedaPrefs["siteName"] . ": " . $x) . "</title>";
    if ($andromedaPrefs["cssLinkHref"] != "") {
      echo "<link rel=\"stylesheet\" type=\"text/css\" href=\"" . $andromedaPrefs["cssLinkHref"] . "\">";
    }
    echo "<script";
    if ($andromedaPrefs["includeJavascript"] != "") {
      echo " src=\"" . $andromedaPrefs["includeJavascript"] . "\"";
    }
    echo "></script></head><body bgcolor=\"" . $andromedaPrefs["bodyBgColor"] . "\" text=\"" . $andromedaPrefs["bodyTextColor"] . "\" link=\"" . $andromedaPrefs["bodyLinkColor"] . "\" vlink=\"" . $andromedaPrefs["bodyVlinkColor"] . "\" alink=\"" . $andromedaPrefs["bodyAlinkColor"] . "\" topmargin=\"" . $andromedaPrefs["bodyMarginSize"] . "\" leftmargin=\"" . $andromedaPrefs["bodyMarginSize"] . "\" marginheight=\"" . $andromedaPrefs["bodyMarginSize"] . "\" marginwidth=\"" . $andromedaPrefs["bodyMarginSize"] . "\">";
  }
  if ($y) {
    echo "<script language=javascript><!--\nlocation.replace(\"" . andrLink("","") . "\");//--></script>";
  }
  if ($andromedaConst["moduleMode"]) {include("header.php");
  } else {
    if ($andromedaPrefs["includeHeader"] != "") {
      include($andromedaPrefs["includeHeader"]);
    }
  }
  echo $andromedaPrefs["absoluteHeader"];
  echo "<center>";
  colorbars($andromedaPrefs["headDiv"]);
  if (!$andromedaPrefs["hideMenubar"]) {
    echo "<table cellspacing=0 cellpadding=4 border=0 width=\"" . $andromedaPrefs["siteWidth"] . "\" bgcolor=\"" . $andromedaPrefs["menubarColor"] . "\"><tr><td><table cellspacing=0 cellpadding=0 border=0><tr><td><a href=" . andrLink("","") . ">";
    imagetag("h","i",trans(17));
    echo "</a></td><td>";
    ipad(4,1);
    echo "</td><td><font size=\"2\" face=\"helvetica,arial\" color=\"" . $andromedaPrefs["siteNameColor"] . "\"><b><i>" . $andromedaPrefs["siteName"] . "</i></b></font></td></tr></table></td><td align=right><table cellspacing=0 cellpadding=0 border=0><tr>";
    if ($andromedaPrefs["ftpPath"] != "") {
      echo "<td><a href=\"" . $andromedaPrefs["ftpPath"] . "\" target=ftp>";
      imagetag("t","i",trans(20));
      echo "</a></td><td>";
      ipad(4,1);
      echo "</td>";
    }
    echo "<td><a href=\"" . $andromedaConst["approot"] . "\" target=_top>";
    imagetag("i","i",$andromedaConst["appname"] . ": " . trans(17));
    echo "</a></td></tr></table>";
    echo "</td></tr></table>";
    colorbars($andromedaPrefs["menubarDiv"]);
  }
  if ($andromedaPrefs["customHeader"] != "") {
    echo "<table cellspacing=0 cellpadding=4 border=0 width=\"" . $andromedaPrefs["siteWidth"] . "\" bgcolor=\"" . $andromedaPrefs["bodyFgColor"] . "\"><tr><td><font size=\"2\"";
    if ($andromedaPrefs["disableHTMLheaders"]) {echo " color=" . $andromedaPrefs["bodyTextColor"];}
    echo ">" . $andromedaPrefs["customHeader"] . "</font></td></tr></table>";
    colorbars($andromedaPrefs["bodyFgDiv"]);
  }
  flush();
}

function andromedaFooter () {
  global $andromedaPrefs, $andromedaConst, $rosetta, $currentLanguage, $clangCodes;
  if ($andromedaPrefs["customBlock"] != "") {
    echo "<table cellspacing=0 cellpadding=4 border=0 width=\"" . $andromedaPrefs["siteWidth"] . "\" bgcolor=\"" . $andromedaPrefs["bodyFgColor"] . "\"><tr><td align=center><font size=\"2\"";
    if ($andromedaPrefs["disableHTMLheaders"]) {
      echo " color=" . $andromedaPrefs["bodyTextColor"];
    }
    echo ">" . $andromedaPrefs["customBlock"] . "</font></td></tr></table>";
    colorbars($andromedaPrefs["bodyFgDiv"]);
  }
  echo "<table cellspacing=0 cellpadding=4 border=0 width=\"" . $andromedaPrefs["siteWidth"] . "\" bgcolor=\"" . $andromedaPrefs["bodyFgColor"] . "\"><tr><td align=center><font size=\"2\"";
  if ($andromedaPrefs["disableHTMLheaders"]) {
    echo " color=" . $andromedaPrefs["bodyTextColor"];
  }
  echo ">";
  //addvpad(12);
  //if ($andromedaPrefs["email"] != "") {
    //echo trans(26) . " &raquo; ";
    //if ($andromedaPrefs["disableHTMLheaders"]) {
      //echo "<a href=\"mailto:" . $andromedaPrefs["email"] . "\" style=\"color:" . $andromedaPrefs["bodyLinkColor"] . "\"><font color=\"" . $andromedaPrefs["bodyLinkColor"] . "\">" . $andromedaPrefs["email"] . "</font></a>";
    //} else {
      //echo "<a href=\"mailto:" . $andromedaPrefs["email"] . "\">" . $andromedaPrefs["email"] . "</a>";
    //}
    //addvpad(12);
  //}
  if ($andromedaPrefs["permitTranslation"]) {
    echo "<table cellspacing=0 cellpadding=0 border=0><form method=get action=" . $andromedaConst["scriptFileName"] . ">";
    if ($andromedaConst["moduleMode"]) {
      echo "<input type=hidden name=op value=modload><input type=hidden name=name value=\"" . basename(dirname(__FILE__)) . "\"><input type=hidden name=file value=\"" . getbasename(basename(__FILE__)) . "\">";
    }
    echo "<input type=hidden name=q value=t><tr><td><select name=t style=\"" . $andromedaPrefs["formStyle"] . "\" onChange=\"javascript:window.location.href = '" . andrLink("?q=t&t=","") . "' + options[selectedIndex].value;\">";
    while (list($k, $v) = each ($rosetta)) {
      $clangCodesTmp = explode("\t",$rosetta[$k][0]);
      echo "<option value=" . $k;
      if ($k == $currentLanguage) {
	echo " selected";
      }
      echo ">";
      if ($clangCodesTmp[1] == $clangCodes[1]) {
	echo $v[1];
      } else {
	echo $clangCodesTmp[2];
      }
    }
    echo "</select></td><noscript><td>";
    ipad(4,1);
    echo "</td><td>";
    imagetag("g","f","");
    echo "</td></noscript></tr></form></table>";
    addvpad(12);
  }
  $ptag = trans(27);
  if ($andromedaPrefs["disableHTMLheaders"]) {
    $ptag = str_replace("#a","<a href=\"" . $andromedaConst["approot"] . "\" target=_top style=\"color:" . $andromedaPrefs["bodyLinkColor"] . "\"><font color=\"" . $andromedaPrefs["bodyLinkColor"] . "\">" . $andromedaConst["appname"] . "</font></a>",$ptag);
  } else {
    $ptag = str_replace("#a","<a href=\"" . $andromedaConst["approot"] . "\" target=_top>" . $andromedaConst["appname"] . "</a>",$ptag);
  }
  echo str_replace("##",$andromedaConst["andromedaVersion"],$ptag);
  addvpad(16);
  echo $andromedaConst[ca2s(array(101,100,105,116,105,111,110))] ;
  addvpad(6);
  echo "</font></td></tr></table>";
  colorbars($andromedaPrefs["footDiv"]);
  echo "</center>";
  echo $andromedaPrefs["absoluteFooter"];
  if ($andromedaConst["moduleMode"]) {
    include("footer.php");
  } else {
    if ($andromedaPrefs["includeFooter"] != "") {
      include($andromedaPrefs["includeFooter"]);
    }
  }
  if (!$andromedaPrefs["disableHTMLheaders"]) {
    echo "</body></html>";
  }
  echo "<!--\n\n\n\n\n\t| " . $andromedaPrefs["siteName"] . "\n\t|\n\t| " . str_replace("##",$andromedaConst["andromedaVersion"],str_replace("#a",$andromedaConst["appname"],trans(27))) . "\n\t| " . $andromedaConst["edition"] . "\n\t| (c)" . date("Y"). " " . $andromedaConst["appauth"] . ", " . $andromedaConst["appcorp"] . "\n\t| " . $andromedaConst["approot"] ."\n\n\n\n-->";
}

function showfolder ($x) {
  global $andromedaPrefs, $totalrowcount;
  if (file_exists($andromedaPrefs["mediaPhysicalPath"] . $x)) {
    $folderName = displayName($x,false);
    andromedaHeader($folderName);
    folderOpenNote($x . "/" . $andromedaPrefs["folderOpenInfo"] . ".txt");
    navbar3($x,"browse");
    if ($andromedaPrefs["permitPlaylists"]) {
      playlistFormHead(true);
    }
    colorbars($andromedaPrefs["bodyFgToRowDiv"]);
    $subfolders = getsubfolders($x);
    for ($i = 0; $i < count($subfolders); $i++) {
      folderrow($x . "/" . $subfolders[$i],false,true);
      rowNote($x . "/" . $subfolders[$i] . "/" . $andromedaPrefs["folderListInfo"] . ".txt",$x . "/" . $subfolders[$i]);
      flush();
    }
    $mp3s = getmp3s($x);
    for ($i = 0; $i < count($mp3s); $i++) {
      filerow($x . "/" . $mp3s[$i],false,true);
      rowNote($x . "/" . getbasename($mp3s[$i]) . ".txt","");
      flush();
    }
    colorbars($andromedaPrefs["rowToBodyFgDiv"]);
    if ($andromedaPrefs["permitPlaylists"]) {
      playlistFormFoot(true);
    }
    displayAMG($folderName,isAlbum($x));
    andromedaFooter();
  } else {fourOfour ();
  }
}

function fourOfour () {
  global $andromedaPrefs;
  andromedaHeader(trans(40));
  echo "<table cellspacing=0 cellpadding=4 border=0 width=\"" . $andromedaPrefs["siteWidth"] . "\" bgcolor=\"" . $andromedaPrefs["bodyFgColor"] . "\" height=220><tr><td align=center>";
  if ($andromedaPrefs["disableHTMLheaders"]) {
    echo "<font color=" . $andromedaPrefs["bodyTextColor"] . ">";
  }
  echo trans(40) . ". " . trans(43) . ", ";
  if ($andromedaPrefs["disableHTMLheaders"]) {
    echo "<a href=" . andrLink("","") . " style=\"color:" . $andromedaPrefs["bodyLinkColor"] . "\"><font color=\"" . $andromedaPrefs["bodyLinkColor"] . "\">" . trans(42) . "</font></a>";
  } else {
    echo "<a href=" . andrLink("","") . ">" . trans(42) . "</a>";
  }
  echo ".";
  if ($andromedaPrefs["disableHTMLheaders"]) {
    echo "</font>";
  }
  echo "</td></tr></table>";
  colorbars($andromedaPrefs["bodyFgDiv"]);
  andromedaFooter();
}

function navbar3 ($x,$y) {
  global $andromedaConst, $andromedaPrefs, $ckplaylist;
  if ($andromedaPrefs["permitSearch"]) {
    if ($y == "search") {
      searchbar($x);
    } else {searchbar("");
    }
    colorbars($andromedaPrefs["bodyFgDiv"]);
  }
  if (!(($x == "") && ($y == "browse"))) {
    echo "<table cellspacing=0 cellpadding=4 border=0 width=\"" . $andromedaPrefs["siteWidth"] . "\" bgcolor=\"" . $andromedaPrefs["bodyFgColor"] . "\"><tr><td><table cellspacing=0 cellpadding=0 border=0><tr><td>";
    imagetag("o","i","");
    echo "</td><td>";
    drill2(parentFolder($x),2);
    echo "</td></tr></table></td></tr></table>";
    colorbars($andromedaPrefs["bodyFgDiv"]);
  }
  if ($y == "browse") {
    if ($x == "") {
      $sidestep = false;
    } else {
      $sidestep = (subfolderCount(parentFolder($x)) > 1);
    }
    if ($andromedaPrefs["playLinks"]) {
      $playalbum = playable($x);
    }
  }
  echo "<table cellspacing=0 cellpadding=4 border=0 width=\"" . $andromedaPrefs["siteWidth"] . "\" bgcolor=\"" . $andromedaPrefs["bodyFgColor"] . "\"><tr><td><table cellspacing=0 cellpadding=0 border=0><tr>";
  if (($x == "") && ($y == "browse")) {
    echo "<td>";
    imagetag("o","i","");
    echo "</td>";
  }
  if ($sidestep) {
    echo "<form method=get action=" . $andromedaConst["scriptFileName"] . ">";
    if ($andromedaConst["moduleMode"]) {
      echo "<input type=hidden name=op value=modload><input type=hidden name=name value=\"" . basename(dirname(__FILE__)) . "\"><input type=hidden name=file value=\"" . getbasename(basename(__FILE__)) . "\">";
    }
    echo "<input type=hidden name=q value=f>";
  }
  if (($x == "") && ($y == "browse")) {
    echo "<td><font size=\"2\"";
    if ($andromedaPrefs["disableHTMLheaders"]) {
      echo " color=" . $andromedaPrefs["bodyTextColor"];
    }
    echo "><b>" . $andromedaPrefs["rootName"] . "</b></font></td>";
  } elseif ($y == "search") {
    echo "<td><font size=\"2\"";
    if ($andromedaPrefs["disableHTMLheaders"]) {echo " color=" . $andromedaPrefs["bodyTextColor"];}
    echo "><b>" . "[" . $x . "] " . trans(37) . "</b></font></td>";
  } elseif ($y == "playlist") {
    echo "<td><font size=\"2\"";
    if ($andromedaPrefs["disableHTMLheaders"]) {
      echo " color=" . $andromedaPrefs["bodyTextColor"];
    }
    echo "><b>" . $x . "</b></font></td>";
  } else {
    if ($sidestep) {
      echo "<td><font></font><select name=f style=\"" . $andromedaPrefs["formStyle"] . "\" onChange=\"javascript:window.location.href='" . andrLink("?q=f&f=","") . "' + escape(options[selectedIndex].value).replace(/\+/g,'%2B');\">";
      $subfolders = getsubfolders(parentFolder($x));
      for ($i = 0; $i < count($subfolders); $i++) {
	echo "<option value=\"" . parentFolder($x) . "/" . $subfolders[$i] . "\"";
	if ($x == parentFolder($x) . "/" . $subfolders[$i]) {
	  echo " selected";
	}
	echo ">" . limitName(displayName($subfolders[$i],false));
      }
      echo "</select></td><noscript><td>";
      ipad(4,1);
      echo "</td><td>";
      imagetag("g","f","");
      echo "</td></noscript>";
    } else {
      echo "<td><font size=\"2\"";
      if ($andromedaPrefs["disableHTMLheaders"]) {
	echo " color=" . $andromedaPrefs["bodyTextColor"];
      }
      echo "><b>" . displayName($x,false) . "</b></font></td>";
    }
  }
  if ($sidestep) {
    echo "</form>";
  }
  if ($andromedaPrefs["folderAux1"] != "") {
    echo "<td>";
    ipad(4,1);
    echo "</td><td><a href=\"" . $andromedaPrefs["folderAux1"] . urlencode($x) . "\">";
    imagetag ("q","i","discuss");
    echo "</a></td>";
  }
  if (($y == "playlist") && ($ckplaylist != "") && $andromedaPrefs["playLinks"]) {
    echo "<td>";
    ipad(4,1);
    echo "</td><td><a href=" . andrLink("?q=y&y=p","") . ">";
    imagetag("p","i",trans(11));
    echo "</a></td>";
  }
  if ($playalbum) {
    echo "<td>";
    ipad(4,1);
    echo "</td><td>";
    playFolderButton($x);
    echo "</td>";
  }
  if ($x == "") {
    $metadisplay = $andromedaPrefs["mediaPhysicalPath"];
  } else {
    $metadisplay = $x;
  }
  if ($y == "browse") {
    $metapath = "/" . $andromedaPrefs["rootName"] . $x;} else {
    $metapath = "/" . $andromedaPrefs["rootName"] . "/" . $x;
  }
  echo "<td>";
  ipad(4,1);
  echo "</td>";
  echo "<td><a href=\"". $andromedaConst["approot"] . "/meta.asp?p=" . urlencode($metapath) . "\" target=_blank>";
  imagetag("k","i",$andromedaConst["appname"] . ": " . displayname($metadisplay,false));
  echo "</a></td>";
  echo "</tr></table></td></tr></table>";
  flush();
}

function folderOpenNote ($x) {
  global $andromedaPrefs, $currentLanguage;
  if ($andromedaPrefs["globalAnnotations"] || ($andromedaPrefs["defaultLanguage"] == $currentLanguage)) {
    if (file_exists($andromedaPrefs["mediaPhysicalPath"] . parentFolder($x) . "/" . $andromedaPrefs["folderOpenImage"] . ".jpg")) {
      $folderImageExt = ".jpg";
    } elseif (file_exists($andromedaPrefs["mediaPhysicalPath"] . parentFolder($x) . "/" . $andromedaPrefs["folderOpenImage"] . ".gif")) {
      $folderImageExt = ".gif";
    }
    if (file_exists($andromedaPrefs["mediaPhysicalPath"] . $x)) {
      $fd = fopen($andromedaPrefs["mediaPhysicalPath"] . $x, "r");
      $note = fread($fd, filesize($andromedaPrefs["mediaPhysicalPath"] . $x));
      fclose ($fd);
    }
    if (($folderImageExt != "") || ($note != "")) {
      echo "<table cellspacing=0 cellpadding=4 border=0 width=\"" . $andromedaPrefs["siteWidth"] . "\" bgcolor=\"" . $andromedaPrefs["bodyFgColor"] . "\"><tr>";
      if ($note != "") {
	echo "<td align=center><table cellspacing=0 cellpadding=0 border=0><tr><td><font size=\"2\"";
	if ($andromedaPrefs["disableHTMLheaders"]) {
	  echo " color=" . $andromedaPrefs["bodyTextColor"];
	}
	echo ">" . $note ."</font></td></tr></table></td>";
      }
      if ($folderImageExt != "") {
	if ($andromedaPrefs["folderOpenImageDims"] != "") {
	  $ittmpa = explode(",",$andromedaPrefs["folderOpenImageDims"]);
	  $imgdimtag = " width=" . $ittmpa[0] . " height=" . $ittmpa[1];
	} else {
	  $imgdimtag = "";
	}
	echo "<td align=center><img src=\"" . mkMediaWebPath(parentFolder($x) . "/" . $andromedaPrefs["folderOpenImage"] . $folderImageExt) . "\"" . $imgdimtag . "></td>";
      }
      echo "</tr></table>";
      colorbars($andromedaPrefs["bodyFgDiv"]);
    }
  }
}

function folderrow ($x,$d,$m) {
  global $andromedaPrefs,$totalrowcount;
  $totalrowcount = $totalrowcount + 1;
  $mysubfolderCount = subfolderCount($x);
  $myfileCount = fileCount($x);
  if ($totalrowcount != 1) {
    colorBars($andromedaPrefs["rowDiv"]);
  }
  echo "<table cellspacing=0 cellpadding=4 border=0 width=\"" . $andromedaPrefs["siteWidth"] . "\" bgcolor=" . switchrow($totalrowcount,$andromedaPrefs["rowColor1"],$andromedaPrefs["rowColor2"]) . "><tr><td valign=top>";
  if ($d) {
    drill2(parentFolder($x),1);
    addvpad(8);
  }
  echo "<table cellspacing=0 cellpadding=0 border=0><tr>";
  if ($andromedaPrefs["permitPlaylists"]) {
    echo "<td valign=top><input type=checkbox name=\"f[]\" value=\"";
    if ($m) {
      echo "o" . $x;
    } else {
      echo $totalrowcount;
    }
    echo "\"";
    if ($andromedaPrefs["checkboxDefault"]) {
      echo " checked";
    }
    echo "></td>";
  }
  echo "<td valign=top><a href=" . folderLink($x) . ">";
  imagetag("c","i","");
  echo "</a></td><td valign=top>";
  if (($andromedaPrefs["disableHTMLheaders"] || ($andromedaPrefs["rowLinkColor"] != $andromedaPrefs["bodyLinkColor"])) && $andromedaPrefs["rowLinkColor"] != "") {
    echo "<a href=" . folderLink($x) . " style=\"color:" . $andromedaPrefs["rowLinkColor"] . "\"><font size=\"2\" color=\"" . $andromedaPrefs["rowLinkColor"] . "\">" . displayName($x,false) . "</font></a>";
  } else {
    echo "<a href=" . folderLink($x) . "><font size=\"2\">" . displayName($x,false) . "</font></a>";
  }
  if ($andromedaPrefs["displayNew"]) {
    echo displaynew(newestfile($x));
  }
  echo "</td></tr></table></td><td align=right>";
  if (($mysubfolderCount == 0) && ($myfileCount == 0)) {
    $desc2 = "&nbsp;";
  }
  if (($mysubfolderCount > 1) && ($myfileCount == 0)) {
    $desc2 = $mysubfolderCount . "&nbsp;" . trans(5);
    $link2 = folderLink($x);
  }
  if (($mysubfolderCount == 0) && ($myfileCount > 0)) {
    $desc2 = $myfileCount . "&nbsp;" . ifps2($myfileCount,trans(2),trans(3));
    $link2 = folderLink($x);
  }
  if (($mysubfolderCount > 0) && ($myfileCount > 0)) {
    $desc2 = $mysubfolderCount . "&nbsp;". ifps2($mysubfolderCount,trans(4),trans(5)) . ", " . $myfileCount . "&nbsp;" . ifps2($myfileCount,trans(2),trans(3));
    $link2 = folderLink($x);
  }
  if (($mysubfolderCount == 1) && ($myfileCount == 0)) {
    $tyty = getsubfolders($x);
    $desc2 = displayName($tyty[0],false);
    $link2 = folderLink($x . "/" . $tyty[0]);
  }
  if ($link2 != "") {
    if (($andromedaPrefs["disableHTMLheaders"] || ($andromedaPrefs["rowLinkColor"] != $andromedaPrefs["bodyLinkColor"])) && $andromedaPrefs["rowLinkColor"] != "") {
      $desc2 = "<a href=" . $link2 . " style=\"color:" . $andromedaPrefs["rowLinkColor"] . "\"><font size=\"1\" color=\"" . $andromedaPrefs["rowLinkColor"] . "\">" . $desc2 . "</font></a>";
    } else {
      $desc2 = "<a href=" . $link2 . "><font size=\"1\">" . $desc2 . "</font></a>";}
  } else {
    $desc2 = "<font size=\"1\">" . $desc2 . "</font>";
  }
  if ($andromedaPrefs["playLinks"]) {
    if (playable($x)) {
      echo "<table cellspacing=0 cellpadding=0 border=0><tr><td align=right>";
      echo $desc2;
      echo "</td><td>";
      ipad(4,1);
      echo "</td><td>";
      playFolderButton($x);
      echo "</td></tr></table>";
    } else {echo $desc2;}
  } else {
    echo $desc2;
  }
  echo "</td></tr></table>";
}

function filerow ($x,$d,$m) {
  global $andromedaConst, $andromedaPrefs, $totalrowcount, $filerowcount, $fileTypes;
  $thisfiletype = strtolower(getextention($x));
  $thisfilesize = filesize($andromedaPrefs["mediaPhysicalPath"] . $x);
  if ($andromedaPrefs["getID3info"] && ($thisfiletype == "mp3") && ($thisfilesize > 0)) {
    $fp = fopen($andromedaPrefs["mediaPhysicalPath"] . $x,"rb");
    $mp3Length = "";
    $mp3Album = "";
    $mp3Artist = "";
    $mp3TrackName = "";
    $mp3Quality = "";
    $fpp = 0;
    for ($i = 0; $i <= 9; $i++) {
      $bb[$i] = ord(fread($fp,1));
    }
    $fpp = $fpp + 10;
    $validID3v2header = (($bb[0] == 73) && ($bb[1] == 68) && ($bb[2] == 51) && ($bb[3] < 255) && ($bb[4] < 255) && ($bb[5] == ($bb[5] & 240)) && ($bb[6] == 0) && ($bb[7] < 128) && ($bb[8] < 128) && ($bb[9] < 128));
    if ($validID3v2header) {
      $ID3size = $bb[7] * 128 * 128 + $bb[8] * 128 + $bb[9];
      $extendedHeader = ($bb[5] & 64) / 64;
      $footerPresent = ($bb[5] & 16) / 16;
      $totalID3size = 10 + $ID3size + $footerPresent * 10;
      if ($extendedHeader == 1) {
	for ($i = 0; $i <= 5; $i++) {
	  $bb[$i] = ord(fread($fp,1));
	}
	$fpp = $fpp + 6;
	$extendedHeaderSize = $bb[1] * 128 * 128 + $bb[2] * 128 + $bb[3];
	fseek($fp,10 + $extendedHeaderSize);
	$fpp = 10 + $extendedHeaderSize;
      }
      for ($i = 0; $i <= 9; $i++) {
	$bb[$i] = ord(fread($fp,1));
      }
      $fpp = $fpp + 10;
      while (((($bb[0] >= 48) && ($bb[0] <= 57)) || (($bb[0] >= 65) && ($bb[0] <= 90))) && ((($bb[1] >= 48) && ($bb[1] <= 57)) || (($bb[1] >= 65) && ($bb[1] <= 90))) && ((($bb[2] >= 48) && ($bb[2] <= 57)) || (($bb[2] >= 65) && ($bb[2] <= 90))) && ((($bb[3] >= 48) && ($bb[3] <= 57)) || (($bb[3] >= 65) && ($bb[3] <= 90))) && ($bb[4] == 0) && ($bb[5] < 128) && ($bb[6] < 128) && ($bb[7] < 128)) {
	$ID3frameID = chr($bb[0]) . chr($bb[1]) . chr($bb[2]) . chr($bb[3]);
	$ID3frameSize = $bb[5] * 128 * 128 + $bb[6] * 128 + $bb[7];
	if ($ID3frameSize > 0) {
	  $ID3frameVal = fread($fp,$ID3frameSize);
	  $ID3frameVal = substr($ID3frameVal,1,strlen($ID3frameVal)-1);
	  $fpp = $fpp + $ID3frameSize;
	} else {
	  $ID3frameVal = "";
	}
	if ($ID3frameID == "TLEN") {
	  $mp3Length = $ID3frameVal / 1000;
	} elseif ($ID3frameID == "TALB") {
	  $mp3Album = $ID3frameVal;
	} elseif ($ID3frameID == "TPE1") {
	  $mp3Artist = $ID3frameVal;
	} elseif ($ID3frameID == "TIT2") {
	  $mp3TrackName = $ID3frameVal;
	}
	for ($i = 0; $i <= 9; $i++) {
	  $bb[$i] = ord(fread($fp,1));
	}
	$fpp = $fpp + 10;
      }
      $offset = $totalID3size - $fpp;
      if ($offset >= 0) {
	fseek($fp,$totalID3size);
	$fpp = $totalID3size;
	for ($i = 0; $i <= 3; $i++) {
	  $bb[$i] = ord(fread($fp,1));
	}
	$fpp = $fpp + 4;
      } else {
	for ($i = 1; $i <= (-1 * $offset); $i++) {
	  $bb[$i-1] = $bb[10 + $offset + $i - 1];
	}
	if ((4 + $offset) > 0) {
	  for ($i = (-1 * $offset); $i <= 3; $i++) {
	    $bb[$i] = ord(fread($fp,1));
	    $fpp = $fpp + 1;
	  }
	}
      }
    }
    $cbr = true;
    for ($xox = 1; $xox <= ($andromedaPrefs["vbrScanCount"] + $andromedaPrefs["vbrSkipCount"]); $xox++) {
      $mpegVersion = ($bb[1] & 24) / 8;
      $layer = ($bb[1] & 6) / 2;
      $protection = ($bb[1] & 1);
      $bitrate = ($bb[2] & 240) / 16;
      $samplefrequency = ($bb[2] & 12) / 4;
      $padded = ($bb[2] & 2) / 2;
      $channelMode = ($bb[3] & 192) / 64;
      $validMP3frame = (($bb[0] == 255) && ($bb[1] >= 224) && ($mpegVersion != 1) && ($layer != 0) && ($bitrate != 0) && ($bitrate != 15) && ($samplefrequency != 3));
      if ($validMP3frame) {
	if ($mpegVersion == 3) {
	  if ($layer == 3) {
	    $column = 1;
	  } elseif ($layer == 2) {
	    $column = 2;
	  } elseif ($layer == 1) {
	    $column = 3;
	  }
	  if ($samplefrequency == 0) {
	    $samplefrequencyD = 44100;
	  } elseif ($samplefrequency == 1) {
	    $samplefrequencyD = 48000;
	  } elseif ($samplefrequency == 2) {
	    $samplefrequencyD = 32000;
	  }
	} elseif ($mpegVersion == 2) {
	  if ($layer == 3) {
	    $column = 4;
	  } elseif ($layer == 2) {
	    $column = 5;
	  } elseif ($layer == 1) {
	    $column = 5;
	  }
	  if ($samplefrequency == 0) {
	    $samplefrequencyD = 22050;
	  } elseif ($samplefrequency == 1) {
	    $samplefrequencyD = 24000;
	  } elseif ($samplefrequency == 2) {
	    $samplefrequencyD = 16000;
	  }
	} elseif ($mpegVersion == 0) {
	  if ($layer == 3) {
	    $column = 4;
	  } elseif ($layer == 2) {
	    $column = 5;
	  } elseif ($layer == 1) {
	    $column = 5;
	  }
	  if ($samplefrequency == 0) {
	    $samplefrequencyD = 11025;
	  } elseif ($samplefrequency == 1) {
	    $samplefrequencyD = 12000;
	  } elseif ($samplefrequency == 2) {
	    $samplefrequencyD = 8000;
	  }
	}
	$bitrateDataA = array(32,32,32,32,8,64,48,40,48,16,96,56,48,56,24,128,64,56,64,32,160,80,64,80,40,192,96,80,96,48,224,112,96,112,56,256,128,112,128,64,288,160,128,144,80,320,192,160,160,96,352,224,192,176,112,384,256,224,192,128,416,320,256,224,144,448,384,320,256,160);
	$bitrateD = $bitrateDataA[($bitrate - 1) * 5 + $column - 1];
	if (($bitrateD != $prevbitrateD) && ($prevbitrateD != "")) {
	  $cbr = false;
	}
	$prevbitrateD = $bitrateD;
	if ($channelMode == 0) {
	  $channelModeD = "Stereo";
	} elseif ($channelMode == 1) {
	  $channelModeD = "Joint Stereo";
	} elseif ($channelMode == 2) {
	  $channelModeD = "Dual Channel";
	} elseif ($channelMode == 3) {
	  $channelModeD = "Single channel (Mono)";
	}
	if (($layer == 1) || ($layer == 2)) {
	  $framesize = floor((144 * 1000 * $bitrateD) / $samplefrequencyD) + $padded;
	} elseif ($layer == 3) {
	  $framesize = floor(12 * 1000 * $bitrateD / $samplefrequencyD + $padded) * 4;
	}
	if ($xox > $andromedaPrefs["vbrSkipCount"]) {
	  $avgbitrateD += $bitrateD;
	}
	if (($xox >= $andromedaPrefs["cbrCutoff"]) && $cbr) {
	  break;
	}
      } else {
	$bitrateD = "";
	break;
      }
      if ($xox == 1) {
	if ($validID3v2header) {
	  $cursor = $framesize-4;
	} else {
	  $cursor = $framesize-10;
	}
      } else {$cursor = $framesize-4;
      }
      if ($fpp + $cursor < $thisfilesize) {
	$skip = ord(fread($fp,$cursor));
	$fpp = $fpp + $cursor;
	for ($i = 0; $i <= 3; $i++) {
	  $bb[$i] = ord(fread($fp,1));
	}
	$fpp = $fpp + 4;
      } else {
	break;
      }
    }
    if ($bitrateD != "") {
      if ($cbr) {
	if ($mp3Length == "") {
	  $mp3Length = round($thisfilesize / ($bitrateD * 1000 / 8));
	}
	$mp3Quality = $bitrateD . "&nbsp;Kbit/s";
      } else {
	if ($mp3Length == "") {
	  $mp3Length = round($thisfilesize / ($avgbitrateD/($xox-1-$andromedaPrefs["vbrSkipCount"]) * 1000 / 8));
	}
	$mp3Quality = round($avgbitrateD/($xox-1-$andromedaPrefs["vbrSkipCount"])) . "&nbsp;Kbit/s&nbsp;VBR";
      }
    }
    if (!$andromedaPrefs["skipID3v1"] && ($mp3TrackName == "")) {
      fseek($fp,$thisfilesize - 128);
      $id3v1tag = strtoupper(fread($fp,3));
      if (($id3v1tag == "ID3") || ($id3v1tag == "TAG")) {
	$id3v1Title = trim(fread($fp,30));
	$id3v1Artist = trim(fread($fp,30));
	$id3v1Album = trim(fread($fp,30));
	$id3v1Year = trim(fread($fp,4));
	$id3v1Comment = trim(fread($fp,28));
	$id3v12skip = ord(fread($fp,1));
	$id3v12number = ord(fread($fp,1));
	$id3v1Genre = ord(fread($fp,1));
	if ($mp3Album == "") {
	  $mp3Album = $id3v1Album;
	}
	if ($mp3Artist == "") {
	  $mp3Artist = $id3v1Artist;
	}
	if ($mp3TrackName == "") {
	  $mp3TrackName = $id3v1Title;
	}
      }
    }
    if (substr($mp3Album,0,2) == "ÿş") {
      $mp3Album = substr($mp3Album,2);
    }
    if (substr($mp3Artist,0,2) == "ÿş") {
      $mp3Artist = substr($mp3Artist,2);
    }
    if (substr($mp3TrackName,0,2) == "ÿş") {
      $mp3TrackName = substr($mp3TrackName,2);
    }
    fclose($fp);
  }
  switch ($fileTypes[$thisfiletype]) {
    case "audio":
      $fileicon = "a";
      break;
    case "video":
      $fileicon = "v";
      break;
    case "playlist":
      $fileicon = "l";
      break;
  }
  $totalrowcount = $totalrowcount + 1;
  $filerowcount = $filerowcount + 1;
  if ($totalrowcount != 1) {
    colorBars($andromedaPrefs["rowDiv"]);
  }
  echo "<table cellspacing=0 cellpadding=4 border=0 width=\"" . $andromedaPrefs["siteWidth"] . "\" bgcolor=" . switchrow($totalrowcount,$andromedaPrefs["rowColor1"],$andromedaPrefs["rowColor2"]) . "><tr><td>";
  if ($d) {
    drill2(parentFolder($x),1);
    addvpad(8);
  }
  echo "<table cellspacing=0 cellpadding=0 border=0><tr>";
  if ($andromedaPrefs["permitPlaylists"]) {
    echo "<td valign=top><input type=checkbox name=\"f[]\" value=\"";
    if ($m) {
      echo "i" . $x;
    } else {
      echo $totalrowcount;
    }
    echo "\"";
    if ($andromedaPrefs["checkboxDefault"]) {
      echo " checked";
    }
    echo "></td>";
  }
  echo "<td valign=top>";
  if ($andromedaPrefs["fileLinks"]) {
    if ($andromedaConst["localUser"] && $andromedaPrefs["localFilePlayback"]) {
      $filepath = $andromedaPrefs["mediaPhysicalPath"] . $x;
    } else {
      $filepath = mkMediaWebPath($x);
    }
    echo "<a href=\"" . $filepath . "\">";
    imagetag($fileicon,"i","");
    echo "</a>";
  } else {
    imagetag($fileicon,"i","");
  }
  echo "</td><td valign=top>";
  if ($andromedaPrefs["fileCount"]) {
    echo "<table cellspacing=0 cellpadding=0 border=0><tr><td align=right valign=top width=\"" . $andromedaPrefs["fileCountWidth"] . "\"><font size=\"2\" color=\"" . $andromedaPrefs["rowTextColor"] . "\">";
    // This seems to count by 2
//    if ($d) {
      echo $filerowcount;
//    } else {
//      echo ($filerowcount*2-1);
//    }
    echo ".</font></td><td>";
    ipad(4,1);
    echo "</td><td>";
  }
  if ($andromedaPrefs["fileLinks"]) {
    if (($andromedaPrefs["disableHTMLheaders"] || ($andromedaPrefs["rowLinkColor"] != $andromedaPrefs["bodyLinkColor"])) && $andromedaPrefs["rowLinkColor"] != "") {
      echo "<a href=\"" . $filepath . "\" style=\"color:" . $andromedaPrefs["rowLinkColor"] . "\"><font size=\"2\" color=\"" . $andromedaPrefs["rowLinkColor"] . "\">";
      if ($mp3TrackName != "") {
	echo $mp3TrackName;
      } else {
	echo displayName($x,true);
      }
      echo "</font></a>";
    } else {
      echo "<a href=\"" . $filepath . "\"><font size=\"2\">";
      if ($mp3TrackName != "") {
	echo $mp3TrackName;
      } else {
	echo displayName($x,true);
      }
      echo "</font></a>";
    }
  } else {
    echo "<font size=\"2\" color=\"" . $andromedaPrefs["rowTextColor"] . "\">";
    if ($mp3TrackName != "") {
      echo $mp3TrackName;
    } else {
      echo displayName($x,true);
    }
    echo "</font>";
  }
  if ($andromedaPrefs["displayNew"]) {
    displaynew(filemtime($andromedaPrefs["mediaPhysicalPath"] . $x));
  }
  if (($mp3Artist != "") || ($mp3Album != "")) {
    echo "<br><font size=\"1\" color=\"" . $andromedaPrefs["rowTextColor"] . "\">";
    if (($mp3Artist != "") && ($mp3Album != "")) {
      echo $mp3Artist . " - " . $mp3Album;
    } else {
      echo $mp3Artist . $mp3Album;
    }
    echo "</font>";
  }
  if ($andromedaPrefs["fileCount"]) {
    echo "</td></tr></table>";
  }
  echo "</td></tr></table></td><td align=right>";
  if ($andromedaPrefs["playLinks"]) {
    echo "<table cellspacing=0 cellpadding=0 border=0><tr><td align=right><font size=\"1\" color=\"" . $andromedaPrefs["rowTextColor"] . "\">";
    if (($mp3Length != "") || ($mp3Quality != "")) {
      if (($mp3Length != "") && ($mp3Quality != "")) {
	echo sec2time($mp3Length) . " &#183; " . $mp3Quality;
      } else {
	if ($mp3Length != "") {
	  echo sec2time($mp3Length);
	} else {
	  echo $mp3Quality;
	}
      }
      echo " &#183; ";
    }
    echo byteCount($thisfilesize) . " &#183; " . strtoupper($thisfiletype) . "</font></td><td>";
    ipad(4,1);
    echo "</td><td><a href=" . andrLink("?q=m&m=",$x) . ">";
    imagetag("p","i","");
    echo "</a></td></tr></table>";
  } else {
    echo "<font size=\"1\" color=\"" . $andromedaPrefs["rowTextColor"] . "\">";
    if (($mp3Length != "") || ($mp3Quality != "")) {
      if (($mp3Length != "") && ($mp3Quality != "")) {echo sec2time($mp3Length) . " &#183; " . $mp3Quality;
      } else {
	if ($mp3Length != "") {
	  echo sec2time($mp3Length);
	} else {
	  echo $mp3Quality;
	}
      }
      echo " &#183; ";
    }
    echo byteCount($thisfilesize) . " " . strtoupper($thisfiletype) . "</font>";
  }
  echo "</td></tr></table>";
}

function rowNote ($x,$i) {
  global $andromedaPrefs, $totalrowcount, $currentLanguage;
  if ($andromedaPrefs["globalAnnotations"] || ($andromedaPrefs["defaultLanguage"] == $currentLanguage)) {
    if ($i != "") {
      if (file_exists($andromedaPrefs["mediaPhysicalPath"] . $i . "/" . $andromedaPrefs["folderListImage"] . ".jpg")) {
	$folderImageExt = ".jpg";
      } elseif (file_exists($andromedaPrefs["mediaPhysicalPath"] . $i . "/". $andromedaPrefs["folderListImage"] . ".gif")) {
	$folderImageExt = ".gif";
      }
    }
    if (file_exists($andromedaPrefs["mediaPhysicalPath"] . $x)) {
      $fd = fopen($andromedaPrefs["mediaPhysicalPath"] . $x, "r");
      $note = fread($fd, filesize($andromedaPrefs["mediaPhysicalPath"] . $x));
      fclose ($fd);
    }
    if (($folderImageExt != "") || ($note != "")) {
      echo "<table cellspacing=0 cellpadding=0 border=0 width=\"" . $andromedaPrefs["siteWidth"] . "\" bgcolor=" . switchrow($totalrowcount,$andromedaPrefs["rowColor1"],$andromedaPrefs["rowColor2"]) . "><tr><td>";
      ipad(30,1);
      echo "</td><td width=100%>";
      if ($folderImageExt != "") {
	if ($andromedaPrefs["folderListImageDims"] != "") {
	  $ittmpa = explode(",",$andromedaPrefs["folderListImageDims"]);
	  $imgdimtag = " width=" . $ittmpa[0] . " height=" . $ittmpa[1];
	} else {
	  $imgdimtag = "";
	}
	echo "<table cellspacing=0 cellpadding=0 border=0 align=left><tr><td><a href=" . folderLink(parentFolder($x)) . "><img src=\"" . mkMediaWebPath(parentFolder($x) . "/" . $andromedaPrefs["folderListImage"] . $folderImageExt) . "\"" . $imgdimtag . " border=0></a></td></tr></table>";
      }
      if ($note != "") {
	echo "<font size=\"2\" color=\"" . $andromedaPrefs["rowTextColor"] . "\">" . $note . "</font>";
      }
      echo "</td></tr></table>";
      colorbar($andromedaPrefs["siteWidth"],"6",switchrow($totalrowcount,$andromedaPrefs["rowColor1"],$andromedaPrefs["rowColor2"]));
    }
  }
}

function searchbar ($s) {
  global $andromedaConst, $andromedaPrefs, $sm;
  echo "<table cellspacing=0 cellpadding=4 border=0 width=\"" . $andromedaPrefs["siteWidth"] . "\" bgcolor=\"" . $andromedaPrefs["bodyFgColor"] . "\"><tr><td align=right><table cellspacing=0 cellpadding=0 border=0><form method=get action=" . $andromedaConst["scriptFileName"] . ">";
  if ($andromedaConst["moduleMode"]) {
    echo "<input type=hidden name=op value=modload><input type=hidden name=name value=\"" . basename(dirname(__FILE__)) . "\"><input type=hidden name=file value=\"" . getbasename(basename(__FILE__)) . "\">";
  }
  echo "<input type=hidden name=q value=s>";
  if ($andromedaPrefs["compactSearch"]) {
    echo "<input type=hidden name=sm value=ff>";
  }
  echo "<tr><td align=right><font face=\"helvetica,arial\" size=\"1\"";
  if ($andromedaPrefs["disableHTMLheaders"]) {
    echo " color=" . $andromedaPrefs["bodyTextColor"];
  }
  echo ">" . trans(13) . " " . $andromedaPrefs["siteName"] . "</font></td>";
  if (!$andromedaPrefs["compactSearch"]) {
    echo "<td>";
    ipad(4,1);
    echo "</td><td><select name=sm style=\"" . $andromedaPrefs["formStyle"] . "\"><option value=fo";
    if (($sm == "fo") || ($sm == "")) {
      echo " selected";
    }
    echo ">" . trans(5) . "<option value=fi";
    if ($sm == "fi") {
      echo " selected";
    }
    echo ">" . trans(3) . "<option value=ff";
    if ($sm == "ff") {
      echo " selected";
    }
    echo ">" . trans(5) . " + " . trans(3) . "</select></td>";
  }
  echo "<td>";
  ipad(4,1);
  echo "</td><td><input name=s size=20 value=\"" . htmlspecialchars($s) . "\" style=\"" . $andromedaPrefs["formStyle"] . "\"></td><td>";
  ipad(4,1);
  echo "</td><td>";
  imagetag("g","f","");
  echo "</td></tr></form></table></td></tr></table>";
}

// This checks to see if the code has been modified and exits if it has been
//if ((abs(filesize(__FILE__) - strlen($andromedaPrefsFileName) - 114923 + 18) > 1) && 
//    (abs(filesize(__FILE__) - strlen($andromedaPrefsFileName) - 114923 + 1690 + 18) > 1)) {
//  exit();
//}

function displayAMG ($n,$a) {
  global $andromedaPrefs;
  if ($andromedaPrefs["displayAMG"]) {
    echo "<table cellspacing=0 cellpadding=4 border=0 width=\"" . $andromedaPrefs["siteWidth"] . "\" bgcolor=\"" . $andromedaPrefs["bodyFgColor"] . "\"><tr><td align=right><table cellspacing=0 cellpadding=0 border=0><form action=\"http://www.allmusic.com/cg/amg.dll\" method=post target=amg><input type=hidden name=P value=amg><tr><td align=right><font face=\"helvetica,arial\" size=\"1\"";
    if ($andromedaPrefs["disableHTMLheaders"]) {
      echo " color=" . $andromedaPrefs["bodyTextColor"];
    }
    echo ">" . trans(13) . " allmusic.com</font></td><td>";
    ipad(4,1);
    echo "</td><td><select name=opt1 style=\"" . $andromedaPrefs["formStyle"] . "\"><option value=1>" . trans(21) . "<option value=2";
    if ($a) {
      echo " selected";
    }
    echo ">" . trans(22) . "<option value=3>" . trans(23) . "<option value=5>" . trans(24) . "<option value=4>" . trans(25) . "</select></td><td>";
    ipad(4,1);
    echo "</td><td><input type=textfield name=sql size=20 maxlength=30 value=\"" . htmlspecialchars($n) . "\" style=\"" . $andromedaPrefs["formStyle"] . "\"></td><td>";
    ipad(4,1);
    echo "</td><td>";
    imagetag("g","f","");
    echo "</td></tr></form></table></td></tr></table>";
    colorbars($andromedaPrefs["bodyFgDiv"]);
  }
}

function search ($s,$sm) {
  global $andromedaPrefs,$totalrowcount;
  andromedaHeader("[" . $s . "] " . trans(37));
  navbar3($s,"search");
  if ($andromedaPrefs["permitPlaylists"]) {
    playlistFormHead(true);
  }
  colorbars($andromedaPrefs["bodyFgToRowDiv"]);
  if (strlen(trim($s)) > 1) {
    if (($sm == "fo") || ($sm == "ff") || ($sm == "")) {
      searchFolders("",$s);
    }
    if (($sm == "fi") || ($sm == "ff") || ($sm == "")) {
      searchFiles("",$s);
    }
    if ($totalrowcount == 0) {
      echo "<table cellspacing=0 cellpadding=0 border=0 bgcolor=\"" . $andromedaPrefs["rowColor1"] . "\" width=\"" . $andromedaPrefs["siteWidth"] . "\"><tr><td align=center>";
      addvpad(48);
      echo "<font face=\"helvetica,arial\" size=\"2\" color=\"" . $andromedaPrefs["rowTextColor"] . "\"><b>" . trans(39) . "</b></font>";
      addvpad(48);
      echo "</td></tr></table>";}
    colorbars($andromedaPrefs["rowToBodyFgDiv"]);
    if ($andromedaPrefs["permitPlaylists"]) {
      playlistFormFoot(true);
    }
  } else {
    echo "<table cellspacing=0 cellpadding=0 border=0 bgcolor=\"" . $andromedaPrefs["rowColor1"] . "\" width=\"" . $andromedaPrefs["siteWidth"] . "\"><tr><td align=center>";
    addvpad(48);
    echo "<font face=\"helvetica,arial\" size=\"2\" color=\"" . $andromedaPrefs["rowTextColor"] . "\"><b>" . trans(38) . "</b></font>";
    addvpad(48);
    echo "</td></tr></table>";
    colorbars($andromedaPrefs["rowToBodyFgDiv"]);
    if ($andromedaPrefs["permitPlaylists"]) {
      playlistFormFoot(true);
    }
  }
  displayAMG($s,false);
  andromedaFooter();
}

function searchFolders ($x,$s) {
  global $andromedaPrefs;
  $subfolders = getsubfolders($x);
  for ($i = 0; $i < count($subfolders); $i++) {
    if (eregi($s,str_replace("_"," ",$subfolders[$i]))) {
      folderrow($x . "/" . $subfolders[$i],true,true);
      flush();
    }
    searchFolders($x . "/" . $subfolders[$i],$s);
  }
}

function searchFiles ($x,$s) {
  global $andromedaPrefs;
  $mp3s = getmp3s($x);
  for ($i = 0; $i < count($mp3s); $i++) {
    if (eregi($s,str_replace("_"," ",$mp3s[$i]))) {
      filerow($x . "/" . $mp3s[$i],true,true);
      flush();
    }
  }
  $subfolders = getsubfolders($x);
  for ($i = 0; $i < count($subfolders); $i++) {
    searchFiles($x . "/" . $subfolders[$i],$s);
  }
}

function playlistFormHead ($x) {
  global $andromedaPrefs;
  if ($x) {
    $m = 1;
  } else {
    $m = 0;
  }
  echo "<script language=JavaScript><!--
function ca(x){for(i=0;i<document.forms[\"l\"].elements.length;i++){var j=document.forms[\"l\"].elements[i];if(j.type==\"checkbox\"){j.checked=x;}}}function ac(){var x=false;for(i=0;i<document.forms[\"l\"].elements.length;i++){var j=document.forms[\"l\"].elements[i];if(j.type==\"checkbox\"){x=x||j.checked;};if(x){break}}return x;}";
  if ($andromedaPrefs["usePlaylistIcons"]) {
    echo "function pf(x,y){if(!y){y=ac()}if(y){document.forms[\"l\"][\"y\"].value=x;document.forms[\"l\"].submit();}}";
  }
  echo "//--></script>";
  echo "<table cellspacing=0 cellpadding=0 border=0 bgcolor=\"" . $andromedaPrefs["bodyFgColor"] . "\" width=\"" . $andromedaPrefs["siteWidth"] . "\"><tr><td><table cellspacing=0 cellpadding=0 border=0><form method=post action=" . andrLink("?q=y&m=" . $m,"") . " name=l>";
  if ($andromedaPrefs["usePlaylistIcons"]) {
    echo "<script language=JavaScript><!--
document.write(\"<input type=hidden name=y value=\\\"\\\">\");//--></script>";
  }
  echo "<tr><td></td></tr></table></td></tr></table>";
}

function playlistFormFoot ($x) {
  global $andromedaPrefs, $totalrowcount, $ckplaylist;
  if (($totalrowcount > 0) || ($ckplaylist != "")) {
    $plb = $andromedaPrefs["usePlaylistIcons"];
    echo "<table cellspacing=0 cellpadding=4 border=0 width=\"" . $andromedaPrefs["siteWidth"] . "\" bgcolor=\"" . $andromedaPrefs["bodyFgColor"] . "\"><tr><td>";
    echo "<table cellspacing=0 cellpadding=0 border=0><tr>";
    if ($totalrowcount > 0) {
      echo "<script language=JavaScript><!--
";
      if ($plb) {
	echo "document.write(\"<td valign=top><a href=# onclick=\\\"ca(true);return false\\\">";
	imagetagE("sa","i",trans(6));
	echo "</a></td><td valign=top><a href=# onclick=\\\"ca(false);return false\\\">";
	imagetagE("sn","i",trans(7));
	echo "</a></td>";
      } else {
	echo "document.write(\"<td valign=top><input type=submit value=\\\"" . trans(6) . "\\\" style=\\\"" . $andromedaPrefs["formStyle"] . "\\\" onclick=\\\"ca(true);return false;\\\"></td><td valign=top><input type=submit value=\\\"" . trans(7) . "\\\" style=\\\"" . $andromedaPrefs["formStyle"] . "\\\" onclick=\\\"ca(false);return false;\\\"></td>";
      }
      echo "<td>";
      ipad(8,1);
      echo "</td>\");//--></script>";
    }
    if (($totalrowcount > 0) && ($andromedaPrefs["playLinks"])) {
      echo "<td valign=top>";
      if ($plb) {
	echo "<script language=JavaScript><!--
document.write(\"<a href=# onclick=\\\"pf('" . trans(10) . "',false);return false\\\">";
	imagetagE("ps","i",trans(10));
	echo "</a>\");//--></script>";
	echo "<noscript>";
      }
      echo "<input type=submit name=y value=\"" . trans(10) . "\" style=\"" . $andromedaPrefs["formStyle"] . "\" onclick=\"return ac()\">";
      if ($plb) {
	echo "</noscript>";
      }
      echo "</td>";
      echo "<td>";
      ipad(8,1);
      echo "</td>";
    }
    if ($x && $totalrowcount > 0) {
      echo "<td valign=top>";
      if ($plb) {
	echo "<script language=JavaScript><!--
document.write(\"<a href=# onclick=\\\"pf('" . trans(8) . "',false);return false\\\">";
	imagetagE("pa","i",trans(8));
	echo "</a>\");//--></script>";
	echo "<noscript>";
      }
      echo "<input type=submit name=y value=\"" . trans(8) . "\" style=\"" . $andromedaPrefs["formStyle"] . "\" onclick=\"return ac()\">";
      if ($plb) {
	echo "</noscript>";
      }
      echo "</td>";
      echo "<td>";
      ipad(8,1);
      echo "</td>";
    }
    if (($x == false) && ($totalrowcount > 0)) {
      echo "<td valign=top>";
      if ($plb) {
	echo "<script language=JavaScript><!--
document.write(\"<a href=# onclick=\\\"pf('" . trans(9) . "',false);return false\\\">";
	imagetagE("pr","i",trans(9));
	echo "</a>\");//--></script>";
	echo "<noscript>";
      }
      echo "<input type=submit name=y value=\"" . trans(9) . "\" style=\"" . $andromedaPrefs["formStyle"] . "\" onclick=\"return ac()\">";
      if ($plb) {
	echo "</noscript>";
      }
      echo "</td>";
      echo "<td>";
      ipad(8,1);
      echo "</td>";
    }
    if ($x && ($ckplaylist != "")) {
      echo "<td valign=top>";
      if ($plb) {
	echo "<script language=JavaScript><!--
document.write(\"<a href=# onclick=\\\"pf('" . trans(45) . "',true);return false\\\">";
	imagetagE("pv","i",trans(45));
	echo "</a>\");//--></script>";
	echo "<noscript>";
      }
      echo "<input type=submit name=y value=\"" . trans(45) . "\" style=\"" . $andromedaPrefs["formStyle"] . "\">";
      if ($plb) {
	echo "</noscript>";
      }
      echo "</td>";
      echo "<td>";
      ipad(8,1);
      echo "</td>";
    }
    if (($totalrowcount > 0) && ($ckplaylist != "")) {
      $plbnote = trans(12);
      $plbnote = str_replace("##",round((strlen($ckplaylist)/($andromedaPrefs["cBlockCount"]*$andromedaPrefs["cBlockSize"]))*100),$plbnote);
      echo "<td><font size=\"2\"";
      if ($andromedaPrefs["disableHTMLheaders"]) {
	echo " color=" . $andromedaPrefs["bodyTextColor"];
      }
      echo ">" . $plbnote . "</font></td>";
    }
    echo "</tr></table>";
    echo "</td></tr></table>";
    colorbars($andromedaPrefs["bodyFgDiv"]);
  }
  echo "<table cellspacing=0 cellpadding=0 border=0 bgcolor=\"" . $andromedaPrefs["bodyFgColor"] . "\" width=\"" . $andromedaPrefs["siteWidth"] . "\"><tr><td><table cellspacing=0 cellpadding=0 border=0><tr><td></td></tr></form></table></td></tr></table>";
}

function displayPlaylist ($x) {
  global $andromedaPrefs, $ckplaylist, $totalrowcount;
  andromedaHeader(trans(44));
  navbar3(trans(44),"playlist");
  playlistFormHead(false);
  colorbars($andromedaPrefs["bodyFgToRowDiv"]);
  $xtmpa = explode("\n",$ckplaylist);
  for ($xi = 0; $xi < count($xtmpa)-1; $xi++) {
    if (substr($xtmpa[$xi],0,1) == "o") {
      folderrow(substr($xtmpa[$xi],1),true,false);
    }
    if (substr($xtmpa[$xi],0,1) == "i") {
      filerow(substr($xtmpa[$xi],1),true,false);
    }
  }
  colorbars($andromedaPrefs["rowToBodyFgDiv"]);
  playlistFormFoot(false);
  displayAMG("",false);
  andromedaFooter();
}

function readPlaylist ($x) {
  global $andromedaPrefs;
  $rtmp = "";
  for ($rpi = 1; $rpi <= $andromedaPrefs["cBlockCount"]; $rpi++) {
    $rtmp2 = $x . $rpi;
    global $$rtmp2;
    $rtmp = $rtmp . fixgpc($$rtmp2);
  }
  return($rtmp);
}

function writePlaylist ($x) {
  global $andromedaPrefs, $ckplaylist;
  for ($rpi = 1; $rpi <= $andromedaPrefs["cBlockCount"]; $rpi++) {
    $rpitmp = substr($ckplaylist,(($rpi-1)*$andromedaPrefs["cBlockSize"]), $andromedaPrefs["cBlockSize"]);
    if ($rpi == $andromedaPrefs["cBlockCount"]) {
      $rpitmp = substr($rpitmp,0,strrpos($rpitmp,"\n")+1);
    }
    setcookie($x . $rpi, $rpitmp);
  }
}

function playFolder ($x) {
  global $andromedaPrefs,$totalrowcount;
  if (file_exists($andromedaPrefs["mediaPhysicalPath"] . $x)) {
    playFolder2($x);
    if ($totalrowcount == 0) {
      Header("Location: " . andrlink("?q=f&f=",$x));
    }
  } else {
    fourOfour();
  }
}

function playable ($x) {
  global $andromedaPrefs;
  $pinme = false;
  $tmp = $andromedaPrefs["mediaPhysicalPath"] . $x;
  $handle=opendir($tmp);
  while ($file = readdir($handle)) {
    if (is_file("$tmp/$file")) {
      if (legalFile($file)) {
	$pinme = true;
	break;
      }
    }
  }
  closedir($handle);
  if (!$pinme) {
    $tmp = $andromedaPrefs["mediaPhysicalPath"] . $x;
    $handle=opendir($tmp);
    while ($file = readdir($handle)) {
      if (is_dir("$tmp/$file") && $file != "." && $file != "..") {
	if (legalFolder($file)) {
	  if (playable($x . "/" . $file)) {
	    $pinme = true;
	    break;
	  }
	}
      }
    }
    closedir($handle);
  }
  return($pinme);
}

function playFolder2 ($x) {
  global $andromedaPrefs, $totalrowcount;
  $subfolders = getsubfolders($x);
  for ($i = 0; $i < count($subfolders); $i++) {
    playFolder2($x . "/" . $subfolders[$i]);
    if ($totalrowcount == $andromedaPrefs["maxPlaylistTracks"]) {break;
    }
  }
  $mp3s = getmp3s($x);
  for ($i = 0; $i < count($mp3s); $i++) {
    playlistRow($x . "/" . $mp3s[$i]);
    if ($totalrowcount == $andromedaPrefs["maxPlaylistTracks"]) {
      break;
    }
  }
  if (count($mp3s) > 0) {
    flush();
  }
}

function playlistHeader () {
  global $andromedaConst, $andromedaPrefs, $ckServerName, $plrpre;
  Header('Cache-Control: private');
  Header("Content-Type: " . $andromedaPrefs["playlistMime"]);
  switch (strtolower($andromedaPrefs["playlistMime"])) {
    case "audio/x-mpegurl":
      $fext = "m3u";
      break;
    case "audio/x-pn-realaudio":
      $fext = "ram";
      break;
    default:
      $fext = "";
  }
  if ($fext != "") {
    Header("Content-Disposition: inline; filename=playlist." . $fext);
  }
  if ($andromedaPrefs["includeEXTM3U"]) {
    echo "#EXTM3U\n";
  }
  if (!($andromedaConst["localUser"] && $andromedaPrefs["localFilePlayback"])) {
    if ($andromedaPrefs["hostAddress"] != "") {
      $plrpre = $andromedaPrefs["protocol"] . "://" . $andromedaPrefs["hostAddress"];
    } else {
      $plrpre = $andromedaPrefs["protocol"] . "://" . $ckServerName;
    }
  }
}

function playlistRow ($x) {
  global $andromedaConst, $andromedaPrefs, $totalrowcount, $plrpre;
  if ($totalrowcount == 0) {
    playlistHeader();
  }
  $totalrowcount += 1;
  if ($andromedaPrefs["includeEXTM3U"]) {
    echo "#EXTINF:-1," . displayName($x,true) . "\n";
  }
  if ($andromedaConst["localUser"] && $andromedaPrefs["localFilePlayback"]) {
    echo $andromedaPrefs["mediaPhysicalPath"] . $x . "\n";
  } else {
    echo $plrpre . mkMediaWebPath($x) . "\n";
  }
}

function playPrepList ($x) {
  global $andromedaPrefs;
  $xtmpa = explode("\n",$x);
  for ($xi = 0; $xi < count($xtmpa)-1; $xi++) {
    if (substr($xtmpa[$xi],0,1) == "o") {
      playFolder2(substr($xtmpa[$xi],1));
    }
    if (substr($xtmpa[$xi],0,1) == "i") {
      playlistRow(substr($xtmpa[$xi],1));
    }
    if ($totalrowcount == $andromedaPrefs["maxPlaylistTracks"]) {
      break;
    }
  }
}

function imagetag ($x,$m,$t) {
  global $andromedaPrefs;
  $ittmpa = explode(",",$andromedaPrefs[$x . "Dimentions"]);
  imagetag2($x,$ittmpa[0],$ittmpa[1],$t,true,$m,"");
}

function imagetagE ($x,$m,$t) {
  global $andromedaPrefs;
  $ittmpa = explode(",",$andromedaPrefs[$x . "Dimentions"]);
  imagetag2($x,$ittmpa[0],$ittmpa[1],$t,true,$m,"\\");
}

function imagetag2 ($x,$a,$b,$t,$c,$m,$e) {
  global $andromedaPrefs;
  switch ($m) {
    case "i":
      echo "<img src=";
      break;
    case "f":
      echo "<input type=image src=";
      break;
  }
  if ($andromedaPrefs["useImageFiles"]) {
    echo $andromedaPrefs["imageFolderPath"] . $x . ".gif";
  } else {
    echo andrLink("?i=",$x);
  }
  echo " width=" . $a * $andromedaPrefs["iconSize"] . " height=" . $b * $andromedaPrefs["iconSize"];
  if ($c) {
    echo " border=0";
  }
  if ($t != "") {
    echo " alt=" . $e . "\"" . htmlspecialchars($t) . $e . "\"";
  }
  echo ">";
}

function displayImage ($dix) {
  switch ($dix) {
    case "p": // playButton
      $imageDataLookup = array(71,73,70,56,57,97,16,0,16,0,162,0,0,51,153,0,102,204,0,51,102,0,255,255,255,0,0,0,255,255,255,0,0,0,0,0,0,33,249,4,1,0,0,5,0,44,0,0,0,0,16,0,16,0,0,3,76,88,170,212,190,176,180,64,107,139,132,10,1,186,39,75,22,0,194,192,121,29,40,141,228,96,162,0,40,118,165,123,210,147,87,219,122,78,187,192,147,192,215,2,14,88,195,140,206,200,34,17,119,205,141,108,121,68,13,25,203,38,233,138,37,69,165,24,194,102,156,140,132,28,23,72,2,0,59);
      break;
    case "i": // infoButton
      $imageDataLookup = array(71,73,70,56,57,97,16,0,16,0,162,0,0,255,255,255,204,204,204,153,153,153,102,102,102,51,51,51,255,255,255,0,0,0,0,0,0,33,249,4,1,0,0,5,0,44,0,0,0,0,16,0,16,0,0,3,64,88,186,220,94,35,142,215,70,8,147,80,53,0,38,129,70,117,24,224,137,14,105,134,140,36,121,151,203,5,166,41,88,53,54,95,177,192,199,156,23,207,21,97,16,86,158,201,3,148,76,110,64,4,146,146,162,177,232,54,193,34,118,155,0,0,59);
      break;
    case "h": // homeButton
      $imageDataLookup = array(71,73,70,56,57,97,16,0,16,0,162,0,0,102,102,153,153,153,204,204,204,255,255,255,255,204,204,204,102,102,102,0,0,0,255,255,255,33,249,4,1,0,0,7,0,44,0,0,0,0,16,0,16,0,0,3,85,120,170,214,190,240,52,65,43,48,209,212,80,74,248,1,198,80,95,65,16,30,40,106,37,49,12,168,42,145,230,208,193,233,197,214,197,219,199,58,1,239,229,195,5,123,53,34,202,118,236,184,148,157,66,176,69,196,5,0,23,73,235,196,245,100,181,156,168,24,43,2,131,62,216,239,162,145,78,55,34,107,199,27,146,0,0,59);
      break;
    case "r": // prefsButton
      $imageDataLookup = array(71,73,70,56,57,97,16,0,16,0,162,0,0,102,102,153,153,153,204,204,204,255,255,255,255,102,102,102,0,0,0,255,255,255,0,0,0,33,249,4,1,0,0,6,0,44,0,0,0,0,16,0,16,0,0,3,80,104,170,213,190,208,52,65,107,139,165,134,205,67,89,153,64,140,99,231,49,66,64,12,108,201,125,161,202,14,43,193,1,211,86,211,228,134,103,186,217,204,22,248,165,100,164,154,47,39,19,210,150,64,36,233,9,192,73,130,78,155,245,170,74,146,170,31,134,201,7,198,20,170,232,95,4,228,184,64,18,0,59);
      break;
    case "t": // ftpButton
      $imageDataLookup = array(71,73,70,56,57,97,16,0,16,0,162,0,0,102,102,153,153,153,204,204,204,255,255,255,255,0,0,0,255,255,255,0,0,0,0,0,0,33,249,4,1,0,0,5,0,44,0,0,0,0,16,0,16,0,0,3,78,88,170,212,190,176,52,65,107,139,164,134,205,3,89,153,176,1,36,208,125,146,56,14,131,186,125,33,7,176,110,0,76,118,73,151,54,62,179,64,90,47,99,11,6,69,55,34,128,242,171,32,113,50,225,232,38,233,52,101,40,130,85,147,67,85,59,83,42,164,81,42,93,34,12,199,121,145,0,0,59);
      break;
    case "g": // goButton
      $imageDataLookup = array(71,73,70,56,57,97,16,0,16,0,162,0,0,102,102,153,153,153,204,204,204,255,255,255,255,0,0,0,255,255,255,0,0,0,0,0,0,33,249,4,1,0,0,5,0,44,0,0,0,0,16,0,16,0,0,3,72,88,170,212,190,176,52,65,107,139,164,134,205,3,89,153,208,141,30,35,146,221,151,1,67,187,177,110,0,76,114,59,188,182,76,215,49,60,204,25,92,207,6,20,249,132,183,226,145,151,156,73,80,29,231,19,42,147,78,71,128,236,7,210,200,122,129,17,144,227,2,73,0,0,59);
      break;
    case "q": // discussButton
      $imageDataLookup = array(71,73,70,56,57,97,16,0,16,0,162,0,0,102,102,153,153,153,204,204,204,255,255,255,255,0,0,0,255,255,255,0,0,0,0,0,0,33,249,4,1,0,0,5,0,44,0,0,0,0,16,0,16,0,0,3,71,88,170,212,190,176,52,65,107,139,164,134,205,3,89,153,208,141,30,35,110,67,151,150,33,186,6,195,10,76,46,23,115,115,86,239,65,126,198,43,224,198,231,10,222,122,52,216,81,8,152,73,72,35,231,19,58,148,78,163,205,15,164,209,236,230,34,32,199,5,146,0,0,59);
      break;
    case "a": // audioFile
      $imageDataLookup = array(71,73,70,56,57,97,26,0,16,0,162,0,0,102,102,51,153,153,102,204,204,153,255,255,204,255,255,255,102,102,102,51,51,51,255,255,255,33,249,4,1,0,0,7,0,44,0,0,0,0,26,0,16,0,0,3,93,120,186,92,254,144,201,121,10,185,152,216,66,187,189,6,246,113,157,244,25,225,21,149,13,97,12,105,70,178,40,58,8,113,16,104,172,242,14,55,28,65,39,234,29,12,186,128,64,152,225,245,144,186,101,40,185,155,149,12,128,172,50,86,124,214,0,129,233,78,101,84,88,176,185,106,185,2,226,146,203,31,87,211,105,140,207,233,61,136,254,193,72,0,0,59);
      break;
    case "v": // videoFile
      $imageDataLookup = array(71,73,70,56,57,97,26,0,16,0,162,0,0,255,255,255,239,239,239,102,102,102,51,51,51,255,255,255,0,0,0,0,0,0,0,0,0,33,249,4,1,0,0,4,0,44,0,0,0,0,26,0,16,0,0,3,78,72,186,44,254,144,201,73,4,184,24,88,65,231,248,32,168,93,92,183,124,65,154,126,218,99,158,131,186,14,89,249,162,50,139,217,102,232,215,47,5,78,165,35,5,9,195,25,48,152,12,20,53,71,95,104,121,139,229,104,187,168,149,136,53,50,165,79,222,203,146,41,139,77,144,180,107,145,0,0,59);
      break;
    case "l": // palaylistFile
      $imageDataLookup = array(71,73,70,56,57,97,26,0,16,0,162,0,0,255,255,255,204,204,204,102,102,102,51,51,51,255,255,255,0,0,0,0,0,0,0,0,0,33,249,4,1,0,0,4,0,44,0,0,0,0,26,0,16,0,0,3,74,72,186,44,254,144,201,73,4,184,24,88,65,231,248,32,168,93,92,183,12,25,134,70,166,130,166,192,75,182,110,0,89,178,70,19,185,154,149,173,222,37,7,52,13,108,144,216,111,39,84,98,138,157,38,145,137,124,56,103,52,233,50,27,10,109,119,22,216,115,167,184,153,139,9,0,59);
      break;
    case "o": // folderOpen
      $imageDataLookup = array(71,73,70,56,57,97,20,0,16,0,162,0,0,255,255,153,153,153,102,224,224,153,204,204,153,255,255,255,102,102,102,255,255,255,0,0,0,33,249,4,1,0,0,6,0,44,0,0,0,0,20,0,16,0,0,3,60,104,186,220,174,37,198,247,138,184,183,80,102,49,150,146,83,12,100,89,126,13,168,74,89,74,188,112,60,10,26,7,220,120,62,215,118,238,143,188,69,193,247,11,4,33,68,157,177,146,196,77,68,171,213,102,74,173,90,167,9,0,59);
      break;
    case "c": // folderClosed
      $imageDataLookup = array(71,73,70,56,57,97,26,0,16,0,162,0,0,255,255,153,224,224,153,255,255,255,102,102,102,255,255,255,0,0,0,0,0,0,0,0,0,33,249,4,1,0,0,4,0,44,0,0,0,0,26,0,16,0,0,3,61,72,186,220,254,111,72,9,235,26,33,231,97,33,214,218,52,117,196,7,158,1,215,13,66,235,190,173,106,13,64,109,223,181,92,209,120,175,123,61,31,137,23,180,253,34,197,219,209,65,76,46,27,162,104,148,68,173,90,175,212,4,0,59);
      break;
    case "x": // invisiblePixel
      $imageDataLookup = array(71,73,70,56,57,97,1,0,1,0,128,0,0,255,255,255,0,0,0,33,249,4,1,0,0,0,0,44,0,0,0,0,1,0,1,0,0,2,2,68,1,0,59);
      break;
    case "sa":
      $imageDataLookup = array(71,73,70,56,57,97,26,0,16,0,162,0,0,255,255,255,204,204,204,153,153,153,102,102,102,0,0,0,0,0,0,0,0,0,0,0,0,44,0,0,0,0,26,0,16,0,0,3,80,72,186,220,238,33,202,73,107,28,130,4,193,187,255,160,128,105,97,56,96,223,184,149,222,0,172,109,6,179,238,11,170,55,42,2,252,204,225,41,0,166,102,187,201,110,60,162,175,3,108,241,158,75,230,17,20,128,178,68,83,106,145,150,165,94,127,221,175,73,118,42,155,207,232,114,230,193,110,19,18,0,59);
      break;
    case "sn":
      $imageDataLookup = array(71,73,70,56,57,97,25,0,16,0,162,0,0,255,255,255,204,204,204,153,153,153,102,102,102,0,0,0,0,0,0,0,0,0,0,0,0,44,0,0,0,0,25,0,16,0,0,3,65,72,186,220,206,33,202,73,107,28,36,136,205,187,255,2,166,129,228,39,150,40,119,166,232,218,13,112,44,155,153,9,220,248,61,190,181,55,228,185,157,170,247,178,68,104,66,22,82,89,114,49,125,196,39,47,32,171,90,175,152,135,118,75,72,0,0,59);
      break;
    case "ps":
      $imageDataLookup = array(71,73,70,56,57,97,42,0,16,0,162,0,0,255,255,255,204,204,204,153,153,153,102,102,102,0,0,0,0,0,0,0,0,0,0,0,0,44,0,0,0,0,42,0,16,0,0,3,91,72,186,220,254,240,133,73,171,189,56,211,161,130,248,96,40,10,195,48,158,39,71,120,104,10,152,109,171,178,113,56,0,111,157,118,186,141,231,61,208,44,248,185,253,96,193,33,209,120,92,242,150,63,28,77,167,76,70,167,212,167,85,74,44,106,123,70,44,248,75,5,136,199,171,238,224,140,14,148,222,240,184,124,78,135,71,238,248,60,33,1,0,59);
      break;
    case "pa":
      $imageDataLookup = array(71,73,70,56,57,97,42,0,16,0,162,0,0,255,255,255,204,204,204,153,153,153,102,102,102,0,0,0,0,0,0,0,0,0,0,0,0,44,0,0,0,0,42,0,16,0,0,3,102,72,186,220,254,240,133,73,171,189,56,211,161,130,248,32,168,105,97,249,113,132,103,126,217,224,14,215,26,162,170,188,14,0,48,216,50,205,11,23,156,46,99,243,241,54,175,220,11,86,41,118,126,155,156,84,202,164,56,83,208,137,112,170,180,92,107,191,165,242,245,3,25,87,173,174,151,119,54,165,135,235,175,173,245,138,177,159,229,124,153,182,236,251,255,128,129,17,131,132,133,4,9,0,59);
      break;
    case "pr":
      $imageDataLookup = array(71,73,70,56,57,97,42,0,16,0,162,0,0,255,255,255,204,204,204,153,153,153,102,102,102,0,0,0,0,0,0,0,0,0,0,0,0,44,0,0,0,0,42,0,16,0,0,3,91,72,186,220,254,240,133,73,171,189,56,211,161,130,248,32,168,105,97,249,113,132,103,126,99,182,134,168,250,206,244,28,215,45,102,119,248,52,252,192,160,101,151,234,5,6,128,164,50,57,24,190,110,180,205,114,217,172,16,101,181,160,118,80,3,65,87,185,75,150,247,10,59,175,51,179,149,246,237,186,217,157,173,124,78,167,71,238,248,60,33,1,0,59);
      break;
    case "pv":
      $imageDataLookup = array(71,73,70,56,57,97,42,0,16,0,162,0,0,255,255,255,204,204,204,153,153,153,102,102,102,0,0,0,0,0,0,0,0,0,0,0,0,44,0,0,0,0,42,0,16,0,0,3,108,72,186,220,254,240,133,73,171,189,56,211,161,130,248,32,168,105,97,249,113,132,103,126,217,224,98,107,136,170,113,233,2,184,91,175,243,46,84,3,156,112,0,139,245,118,27,161,146,104,169,29,107,73,101,238,226,236,248,162,82,102,165,154,242,201,178,94,153,53,118,185,225,8,47,138,239,105,106,189,208,218,245,120,53,162,192,39,242,46,185,62,185,231,3,46,129,130,131,132,133,134,130,17,137,138,139,4,9,0,59);
      break;
    case "k":
      $imageDataLookup = array(71,73,70,56,57,97,16,0,16,0,162,0,0,0,0,0,255,255,255,102,102,153,153,153,204,204,204,255,255,255,255,0,0,0,0,0,0,33,249,4,1,0,0,5,0,44,0,0,0,0,16,0,16,0,0,3,70,88,170,208,190,176,52,66,107,139,160,142,205,7,88,25,209,141,30,35,110,65,26,116,95,136,170,41,39,76,92,60,216,195,156,145,170,76,119,61,223,14,184,234,232,78,36,217,76,50,194,229,62,76,162,18,26,29,9,174,84,6,224,202,213,69,64,142,11,36,1,0,59);
      break;
  }
  for ($i = 0; $i < count($imageDataLookup); $i++) {
    $binstr = $binstr . chr($imageDataLookup[$i]);
  }
  Header("Content-Type: image/gif");
  echo $binstr;
}

function trans ($y) {
  global $rosetta, $currentLanguage;
  if ($rosetta[$currentLanguage][$y] != "") {
    return $rosetta[$currentLanguage][$y];
  } else {
    return $rosetta["EN"][$y];
  }
}

function sec2time ($x) {
  $minutes = floor($x / 60);
  $seconds = round($x - ($minutes * 60));
  if ($seconds < 10) {
    $seconds = "0" . $seconds;
  }
  return $minutes . ":" . $seconds;
}

function andromedaEncode ($x) {
  $tmp = rawurlencode($x);
  $tmp = eregi_replace("%2F","/",$tmp);
  $tmp = eregi_replace("%2E",".",$tmp);
  $tmp = eregi_replace("%2D","-",$tmp);
  $tmp = eregi_replace("%5F","_",$tmp);
  return($tmp);
}

function legalFolder ($x) {
  global $andromedaPrefs, $folderSkipNames;
  $lftmp = true;
  if ($andromedaPrefs["skipPrefix"] != "") {
    if (substr($x, 0, strlen($andromedaPrefs["skipPrefix"])) == $andromedaPrefs["skipPrefix"]) {
      $lftmp = false;
    }
  }
  if ($lftmp) {
    if ($folderSkipNames[$x]) {
      $lftmp = false;
    }
  }
  return $lftmp;
}

function legalFile ($x) {
  global $andromedaPrefs, $fileTypes;
  $lftmp = true;
  if ($andromedaPrefs["skipPrefix"] != "") {
    if (substr($x, 0, strlen($andromedaPrefs["skipPrefix"])) == $andromedaPrefs["skipPrefix"]) {
      $lftmp = false;
    }
  }
  if ($lftmp) {
    $isaftmp = $fileTypes[strtolower(getextention($x))];
    $lftmp = (($isaftmp == "audio") || ($isaftmp == "video") || ($isaftmp == "playlist"));
  }
  return($lftmp);
}

function subfolderCount ($dir) {
  global $andromedaPrefs;
  $sdctotal = 0;
  $tmp = $andromedaPrefs["mediaPhysicalPath"] . $dir;
  $handle=opendir($tmp);
  while ($file = readdir($handle)) {
    if (is_dir("$tmp/$file") && $file != "." && $file != ".." && legalFolder($file)) {
      $sdctotal = $sdctotal + 1;
    }
  }
  closedir($handle);
  return $sdctotal;
}

function fileCount ($dir) {
  global $andromedaPrefs;
  $tfileCount = 0;
  $tmp = $andromedaPrefs["mediaPhysicalPath"] . $dir;
  $handle=opendir($tmp);
  while ($file = readdir($handle)) {
    if (is_file("$tmp/$file") && legalFile($file)) {
      $tfileCount = $tfileCount + 1;
    }
  }
  closedir($handle);
  return round(($tfileCount/2)+.1);
}

function getsubfolders ($dir) {
  global $andromedaPrefs;
  $tmp = $andromedaPrefs["mediaPhysicalPath"] . $dir;
  $handle=opendir($tmp);
  while ($file = readdir($handle)) {
    if (is_dir("$tmp/$file") && $file != "." && $file != ".." && legalFolder($file)) {
      $tmp2[] = $file;
    }
  }
  closedir($handle);
  if ($tmp2) {
    usort($tmp2,"strcasecmp");
  }
  return $tmp2;
}

function getmp3s ($dir) {
  global $andromedaPrefs;
  $tmp = $andromedaPrefs["mediaPhysicalPath"] . $dir;
  $handle=opendir($tmp);
  $tc = true;
  while ($file = readdir($handle)) {
    if (is_file("$tmp/$file") && legalFile($file)) {
      // This appears to get every other file.
      //if ($tc) {
	$tmp2[] = $file;
//	$tc = false;
//      } else {
//	$tc = true;
//      }
    }
  }
  closedir($handle);
  if ($tmp2) {
    usort($tmp2,"strcasecmp");
  }
  return $tmp2;
}

function drill2 ($x,$z) {
  global $andromedaPrefs;
  if ($z == 1) {
    $lcolor = $andromedaPrefs["rowLinkColor"];
    $tcolor = $andromedaPrefs["rowTextColor"];
  } elseif ($andromedaPrefs["disableHTMLheaders"]) {
    $lcolor = $andromedaPrefs["bodyLinkColor"];
    $tcolor = $andromedaPrefs["bodyTextColor"];
  }
  echo "<font size=\"" . $z . "\"";
  if ($tcolor != "") {
    echo " color=" . $tcolor;
  }
  echo ">";
  if ($lcolor != "") {
    echo "<nobr><a href=" . andrLink("","") . " style=\"color:" . $lcolor . "\"><font color=" . $lcolor . ">" . $andromedaPrefs["rootName"] . "</font></a> /</nobr> ";
  } else {
    echo "<nobr><a href=" . andrLink("","") . ">" . $andromedaPrefs["rootName"] . "</a> /</nobr> ";
  }
  $tmpaa = explode("/",$x);
  $tlp = "";
  for ($i = 1; $i <= count($tmpaa)-1; $i++) {
    $tlp = $tlp . "/" . $tmpaa[$i];
    if ($lcolor != "") {
      echo "<nobr><a href=" . folderLink($tlp) . " style=\"color:" . $lcolor . "\"><font color=" . $lcolor . ">" . displayName($tmpaa[$i],false) . "</font></a> /</nobr> ";
    } else {
      echo "<nobr><a href=" . folderLink($tlp) . ">" . displayName($tmpaa[$i],false) . "</a> /</nobr> ";
    }
  }
  echo "</font>";
}

function playFolderButton ($plx) {
  echo "<a href=" . andrLink("?q=p&p=",$plx) . ">";
  imagetag("p","i",trans(11));
  echo "</a>";
}

function andrLink ($x,$y) {
  global $andromedaConst;
  if ($andromedaConst["moduleMode"]) {
    if ($x != "") {
      return($andromedaConst["scriptFileName"] . "?op=modload&name=" . basename(dirname(__FILE__)) . "&file=" . getbasename(basename(__FILE__)) . "&" . substr($x,1) . str_replace(".","%2E",urlencode($y)));
    } else {
      return($andromedaConst["scriptFileName"] . "?op=modload&name=" . basename(dirname(__FILE__)) . "&file=" . getbasename(basename(__FILE__)));
    }
  } else {
    return($andromedaConst["scriptFileName"] . $x . str_replace(".","%2E",urlencode($y)));
  }
}

function mkMediaWebPath ($x) {
  global $andromedaPrefs;
  return(andromedaEncode($andromedaPrefs["mediaWebPath"] . $x));
}

function folderLink ($x) {
  return(andrLink("?q=f&f=",$x));
}

function isAlbum ($x) {
  return ((subfolderCount($x) == 0) && (fileCount($x) > 0));
}

function byteCount ($x) {
  if ($x >= 1024 * 1000) {
    return((round(($x*100)/(1024*1024))/100) . "&nbsp;MB");
  } elseif ($x >= 1000) {
    return(round($x/1024) . "&nbsp;KB");
  } else {
    return($x . "&nbsp;byte");
  }
}

function addvpad ($height) {
  echo "<table cellspacing=0 cellpadding=0 border=0 height=$height><tr><td></td></tr></table>";
}

function ipad ($width,$height) {
  imagetag2 ("x",$width,$height,"",false,"i","");
}

function colorbar ($cbw, $cbh, $cbc) {
  echo "<table cellspacing=0 cellpadding=0 border=0 width=$cbw height=$cbh bgcolor=$cbc><tr><td>";
  ipad (1,1);
  echo "</td></tr></table>";
}

function colorBars ($cbs) {
  global $andromedaPrefs;
  if ($cbs != "") {
    $cbtmp1a = explode(";",$cbs);
    echo "<table cellspacing=0 cellpadding=0 border=0 width=\"" . $andromedaPrefs["siteWidth"] . "\">";
    for ($i = 0; $i < count($cbtmp1a); $i++) {
      $cbtmp2a = explode(",",$cbtmp1a[$i]);
      echo "<tr bgcolor=\"" . $cbtmp2a[0] . "\"><td>";
      ipad(1,$cbtmp2a[1]);
      echo "</td></tr>";
    }
    echo "</table>";
  }
}

function switchRow($swx,$swcolor1,$swcolor2) {
  if ($swx % 2 == 0) {
    return $swcolor1;
  } else {
    return $swcolor2;
  }
}

function ifps2 ($x,$y,$z) {
  if ($x == 1) {
    return ($y);
  } else {return ($z);
  }
}

function displayName ($x,$y) {
  global $andromedaPrefs;
  $cfntmp2 = basename($x);
  if ($y) {
    $cfntmp2 = getbasename($cfntmp2);
  }
  $tknumtrimcodea = explode(",",$andromedaPrefs["tkNumTrimCodes"]);
  for ($i = 0; $i < count($tknumtrimcodea); $i++) {
    $trimme = true;
    for ($j = 0; $j < strlen($tknumtrimcodea[$i]); $j++) {
      if (substr($tknumtrimcodea[$i],$j,1) == "#") {
	$trimme = ($trimme && (ord(substr($cfntmp2,$j,1)) >= 48) && (ord(substr($cfntmp2,$j,1)) <= 57));
      } else {
	$trimme = ($trimme && (substr($tknumtrimcodea[$i],$j,1) == substr($cfntmp2,$j,1)));
      }
      if ($trimme == false) {
	break;
      }
    }
    if ($trimme) {
      $cfntmp2 = substr($cfntmp2,strlen($tknumtrimcodea[$i]));
      break;
    }
  }
  $cfntmp2 = str_replace("_"," ",$cfntmp2);
  $cfntmp2 = trim($cfntmp2);
  if (strtolower(substr($cfntmp2,strlen($cfntmp2)-5)) == ", the") {
    $cfntmp2 = substr($cfntmp2,strlen($cfntmp2)-3) . " " . substr($cfntmp2,0,strlen($cfntmp2)-5);
  }
  if (count(explode(" ",$cfntmp2)) == 2) {
    $spos = strpos($cfntmp2," ");
    $lword = substr($cfntmp2,0,$spos);
    $rword = substr($cfntmp2,$spos+1);
    if (substr($lword,strlen($lword)-1) == ",") {
      $cfntmp2 = $rword . " " . substr($lword,0,strlen($lword)-1);
    }
  }
  return($cfntmp2);
}

function limitName ($x) {
  global $andromedaPrefs;
  if (strlen($x) < $andromedaPrefs["popupMaxWidth"]) {
    return ($x);
  } else {
    return (chop(substr ($x, 0, ($andromedaPrefs["popupMaxWidth"] - 2))) . "...");
  }
}

function ca2s ($x) {
  for ($i = 0; $i < count($x); $i++) {
    $tmp .= chr($x[$i]);
  }
  return $tmp;
}

function newestfile ($x) {
  global $andromedaPrefs;
  $mp3s = getmp3s($x);
  for ($i = 0; $i < count($mp3s); $i++) {
    $fdate = filemtime($andromedaPrefs["mediaPhysicalPath"] . $x . "/" . $mp3s[$i]);
    if ($fdate > $maxdate) {
      $maxdate = $fdate;
    }
  }
  $sfold = getsubfolders($x);
  for ($i = 0; $i < count($sfold); $i++) {
    $maxsubfiledate = (newestfile($x . "/" . $sfold[$i]));
    if ($maxsubfiledate > $maxdate) {
      $maxdate = $maxsubfiledate;
    }
  }
  return ($maxdate);
}

function displaynew ($x) {
  global $andromedaPrefs;
  if ($x > time() - 60 * 60 * 24 * 8) {
    $fmtFdate = date("m/d/Y",$x);
    if (date("m/d/Y",time()) == $fmtFdate) {
      echo "<font size=\"1\" color=\"" . $andromedaPrefs["newFileColor"] . "\"><b><i> " . str_replace(" ","&nbsp;",trans(28)) . "</i></b></font>";
    } elseif (date("m/d/Y",time() - 60 * 60 * 24) == $fmtFdate) {
      echo "<font size=\"1\" color=\"" . $andromedaPrefs["newFileColor"] . "\"><b><i> " . str_replace(" ","&nbsp;",trans(29)) . "</i></b></font>";
    } else {
      for ($i = 2; $i < 7; $i++) {
	if (date("m/d/Y",time() - 60 * 60 * 24 * $i) == $fmtFdate) {
	  echo "<font size=\"1\" color=\"" . $andromedaPrefs["newFileColor"] . "\"><b><i> " . str_replace(" ","&nbsp;",trans(30 + date("w",$x))) . "</i></b></font>";
	  break;
	}
      }
    }
  }
}

function getbasename ($x) {
  return(substr($x,0,strrpos($x,".")));
}

function getextention ($x) {
  return(substr($x,strrpos($x,".")+1));
}

function fixgpc ($x) {
  if (get_magic_quotes_gpc() == 1) {
    return (str_replace ("\\\"", "\"", str_replace ("\\'", "'", $x)));
  } else {
    return($x);
  }
}

function parentFolder ($x) {
  if ($x == "") {
    return ("");
  } else {
    $tmp = dirname($x);
    if ($tmp == "/" or $tmp == "\\") {
      return ("");
    } else {
      return ($tmp);
    }
  }
}
error_reporting (E_ALL ^ E_NOTICE);
if ($i == "") {
  $i = $HTTP_GET_VARS["i"];
}
if ($i) {
  displayImage($i);
} else {
  set_magic_quotes_runtime(0);
  if ($SCRIPT_NAME == "") {
    $SCRIPT_NAME = $HTTP_SERVER_VARS["SCRIPT_NAME"];
  }
  if ($PHP_SELF == "") {
    $PHP_SELF = $HTTP_SERVER_VARS["PHP_SELF"];
  }
  if ($PATH_TRANSLATED == "") {
    $PATH_TRANSLATED = $HTTP_SERVER_VARS["PATH_TRANSLATED"];
  }
  if ($SCRIPT_FILENAME == "") {
    $SCRIPT_FILENAME = $HTTP_SERVER_VARS["SCRIPT_FILENAME"];
  }
  if ($LOCAL_ADDR == "") {
    $LOCAL_ADDR = $HTTP_SERVER_VARS["LOCAL_ADDR"];
  }
  if ($SERVER_ADDR == "") {
    $SERVER_ADDR = $HTTP_SERVER_VARS["SERVER_ADDR"];
  }
  if ($SERVER_NAME == "") {
    $SERVER_NAME = $HTTP_SERVER_VARS["SERVER_NAME"];
  }
  if ($SERVER_PORT == "") {
    $SERVER_PORT = $HTTP_SERVER_VARS["SERVER_PORT"];
  }
  if ($REMOTE_ADDR == "") {
    $REMOTE_ADDR = $HTTP_SERVER_VARS["REMOTE_ADDR"];
  }
  if ($LOCAL_ADDR != "") {
    $ckServerIP = $LOCAL_ADDR;
  } else {
    $ckServerIP = $SERVER_ADDR;
  }
  if ($SERVER_NAME != "") {
    $ckServerName = $SERVER_NAME;
  } else {
    $ckServerName = $ckServerIP;
  }
  if (($SERVER_PORT != "80") && ($SERVER_PORT != "")) {
    $ckServerName = $ckServerName . ":" . $SERVER_PORT;
  }
  if (($SCRIPT_NAME != $PHP_SELF) && ($PHP_SELF != "")) {
    $SCRIPT_NAME_FIXED = str_replace($SCRIPT_NAME, "", $PHP_SELF);
  } else {
    $SCRIPT_NAME_FIXED = $SCRIPT_NAME;
  }
  if ($PATH_TRANSLATED == "") {
    $SCRIPT_PATH_FIXED = $SCRIPT_FILENAME;
  } else {$SCRIPT_PATH_FIXED = $PATH_TRANSLATED;
  }
  #
# PLEASE DO NOT MODIFY THE TRANSLATION DICTIONARIES. IF YOU THINK
# SOMETHING COULD BE PHRASED BETTER, PLEASE LET ME KNOW SO I CAN
# FIX IT FOR EVERYBODY.
  #
# THANKS
  #
  $rosetta["AR"] = array("Arabic\twindows-1256\tArabic","ÚÑÈí","ãáİ","ãáİÇÊ","ãÌáÏ","ãÌáÏÇÊ","ÃÎÊÇÑ Çáßá","áÇÔíÁ","ÃÖİ Åáì ŞÇÆãÉ ÇáÃÛÇäí ÇáãİÖáÉ","ÇãÓÍ ãä ŞÇÆãÉ ÇáÃÛÇäí ÇáãİÖáÉ","ÅÓÊãÇÚ ÇáÅÎÊíÇÑ","ÅÓÊãÇÚ Çáßá","ŞÇÆãÉ ÇáãİÖáÇÊ %## ããÊáÆÉ","ÈÍË","ÇáÑÌÇÁ ÇáÏÎæá","ÅÓã ÇáãÓÊÎÏã","ßáãÉ ÇáÚÈæÑ","ÇáÕİÍÉ ÇáÑÆíÓíÉ","ÇáÊİÖíáÇÊ","Úä #a","ãæŞÚ ÇáÃİ Êí Èí","ÇáİäÇäíä","ÇáÃáÈæãÇÊ","ÇáÃÛÇäí","ÇáÕäİ","ÚäÇæíä ÇáÃÛÇäí","ÃÓÆáÉ æ ÊÚáíŞÇÊ","åĞÇ ÇáãæŞÚ ãÏÇÑ ÈÈÑäÇãÌ #a äÓÎÉ ##","ÌÏíÏ Çáíæã","ÌÏíÏ ÇáÃãÓ","ÌÏíÏ ÇáÃÍÏ","ÌÏíÏ ÇáÃËäíä","ÌÏíÏ ÇáËáÇËÇÁ","ÌÏíÏ ÇáÃÑÈÚÇÁ","ÌÏíÏ ÇáÎãíÓ","ÌÏíÏ ÇáÌãÚÉ","ÌÏíÏ ÇáÓÈÊ","äÊíÌÉ ÇáÈÍË","íÌÈ ÊæİÑ Úáì ÇáÃŞá ÍÑİíä ááÈÍË","áÇ ÊæÌÏ äÊíÌÉ ãØÇÈŞÉ","Çáãáİ ÛíÑ ãæÌæÏ","ÓíÊã ÊÍæíáß ááãæŞÚ","ÇÎÊÇÑ åäÇ","áßí Êßãá","ŞÇÆãÉ ÇáÃÛÇäí ÇáãİÖáÉ","ÅÙåÇÑ ŞÇÆãÉ ÇáÃÛÇäí ÇáãİÖáÉ");
  $rosetta["BS"] = array("Bosnian\tiso-8859-1\tBosanski","Bosanski","fajl","fajlovi","folder","folderi","izaberi sve","nista","dodaj na listu","izbrisi sa liste","slusaj posebno","slusaj sve","lista je ##% puna","trazi","molimo vas logujte se","logujte se","Lozinka","Glavna strana","zeljena podesavanja","o #a","ftp site","izvodjac","albumi","pjesme","zanr","labels","pitanja i komentari","Powerd by #a verzija ##","novo Danas","novo jucer","novo Nedjelja","novo Ponedjeljak","novo Utorak","novo SrijedA","nOVO Cetvrtak","novo Petak","novo Subota","rezultati trazenja","trazena rijec mora imati najmanje dva slova","nista nema na dati text","File nije pronadjen","bicete preusmjereni na sajt","Klikni ovdje","da nastavite","lista","pogledaj listu");
  $rosetta["BG"] = array("Bulgarian\tWindows-1251\tBulgarian","Áúëãàğñêè","ôàéë","ôàéëà","ïàïêà","ïàïêè","èçáåğè âñè÷êè","îòêàæè âñè÷êè","äîáàâè â ñïèñúêà","èçâàäè îò ñïèñúêà","ïğîñëóøàé èçáğàíîòî","ïğîñëóøàé âñè÷êè","ñïèñúêúò å ïúëåí íà ##%","òúğñè â","ïğåäñòàâåòå ñå","ïîòğåáèòåë","ïàğîëà","íà÷àëíà ñòğàíèöà","íàñòğîéêè","çà #a","ftp äèğåêòîğèÿ","èçïúëíèòåëè","àëáóìè","ïåñíè","ñòèëîâå","îáëîæêè","âúïğîñè è êîìåíòàğè","ğåàëèçèğàíî ñ #a âåğñèÿ ##","äîáàâåíî Äíåñ","äîáàâåíî Â÷åğà","äîáàâåíî â Íåäåëÿ","äîáàâåíî â Ïîíåäåëíèê","äîáàâåíî âúâ Âòîğíèê","äîáàâåíî â Ñğÿäà","äîáàâåíî â ×åòâúğòúê","äîáàâåíî â Ïåòúê","äîáàâåíî â Ñúáîòà","ğåçóëòàò îò òúğñåíåòî","òúğñåíàòà ôğàçà òğÿáâà äà å íàé-ìàëêî îò äâà ñèìâîëà","íèùî íå å íàìåğåíî","Íÿìà òàêúâ ôàéë","Ùå áúäåòå ïğåíàñî÷åíè êúì ñòğàíèöàòà","íàòèñíåòå òóê","Çà ïğîäúëæåíèå","ñïèñúê","âèæ ñïèñúêà");
  $rosetta["CA"] = array("Catalan\tiso-8859-1\tCatal&agrave;","Català","arxiu","arxius","carpeta","carpetes","seleccionar tot","res","afegir a la llista","treure de la llista","reproduir selecció","reproduir tot","la llista està ##% plena","buscar a","identifica't si-us-plau","nom","clau","pàgina inicial","preferencies","sobre #a","lloc ftp","artistes","álbums","cançons","gèneres","segells","preguntes o comentaris","funciona amb #a versió ##","nou avui","nou d´ ahir","nou del diumenge","nou del dilluns","nou del dimarts","nou del dimecres","nou del dijous","nou del divendres","nou del dissabte","resultats de la búsqueda","cal introduir com a mínim 2 lletres","no s'han trobat coincidències","Arxiu no trobat","Hauries de ser redirigit cap aquest lloc","apreta aqui","Per continuar","llista","veure llista");
  $rosetta["CS"] = array("Czech\tiso-8859-2\tCesky","Èesky","soubor","soubory","slo¾ka","slo¾ky","vybrat v¹e","nic","pøidat do playlistu","odstranit z playlistu","pøehrát vybrané","pøehrát v¹e","playlist je z ##% plnı","hledat v","prihla¹te se prosím","jméno","heslo","titulní strana","nastavení","o #a","ftp server","umìlci","alba","písnì","¾ánry","labely","otázky nebo komentáøe","pou¾ívá #a verze ##","novinka dnes","novinka vèera","novinka Nedìle","novinka Pondìlí","novinka Úterı","novinka Støedy","novinka Ètvrtka","novinka Páteku","novinka Soboty","vısledky vyhledávání","zadejte alespoò 2 znaky","nic nenalezeno","Soubor nenalezen","Budete pøesmìrování na","klikni zde","Pokraèovat","playlist","prohlídnout playlist");
  $rosetta["ZH-cn"] = array("Chinese Simplified\tGB2312\tChinese Simplified","¼òÌåÖĞÎÄ","¸öµµ°¸","¸öµµ°¸","¸ö×ÊÁÏ¼Ğ","¸ö×ÊÁÏ¼Ğ","È«Ñ¡","Çå³ı","ĞÂÔöÖÁ²¥·ÅÇåµ¥","´Ó²¥·ÅÇåµ¥ÖĞÒÆ³ı","²¥·ÅÇåµ¥","È«²¿²¥·Å","²¥·ÅÇåµ¥ÒÑÊ¹ÓÃÁË##%","ËÑÑ°","ÇëµÇÈë","µÇÈëÃû³Æ","ÃÜÂë","Ê×Ò³","Éè¶¨","¹Øì¶ #a","ftp Õ¾Ì¨","Ñİ³ö/Ñİ×àÕß","×¨¼­","¸èÇú","Àà±ğ","³ªÆ¬¹«Ë¾","ÎÊÌâ»òÒâ¼û","ÓÉ #a ¿ª·¢ - °æ±¾ ##","ĞÂÔö - ½ñÌì","ĞÂÔö - ×òÌì","ĞÂÔö - ĞÇÆÚÈÕ","ĞÂÔö - ĞÇÆÚÒ»","ĞÂÔö - ĞÇÆÚ¶ş","ĞÂÔö - ĞÇÆÚÈş","ĞÂÔö- ĞÇÆÚËÄ","ĞÂÔö - ĞÇÆÚÎå","ĞÂÔö - ĞÇÆÚÁù","ËÑÑ°½á¹û","ËÑÑ°Ìõ¼ş±ØĞëÓÉÖÁÉÙÁ½¸ö×ÖÔªËù×é³É","ÕÒ²»µ½·ûºÏÒªÇóµÄÏîÄ¿","ÕÒ²»µ½µµ°¸","Äã½«»á±»´øÁì½øÈëÕ¾Ì¨","Çë°´ÕâÀï","¼ÌĞø","²¥·ÅÇåµ¥","¼ìÊÓ²¥·ÅÇåµ¥");
  $rosetta["ZH-tw"] = array("Chinese Traditional\tBIG5\tChinese Traditional","ÁcÅé¤¤¤å","­ÓÀÉ®×","­ÓÀÉ®×","­Ó¸ê®Æ§¨","­Ó¸ê®Æ§¨","¥ş¿ï","²M°£","·s¼W¦Ü¼½©ñ²M³æ","±q¼½©ñ²M³æ¤¤²¾°£","¼½©ñ²M³æ","¥ş³¡¼½©ñ","¼½©ñ²M³æ¤w¨Ï¥Î¤F##%","·j´M","½Ğµn¤J","µn¤J¦WºÙ","±K½X","­º­¶","³]©w","Ãö©ó #a","ftp ¯¸¥x","ºt¥X/ºt«µªÌ","±M¿è","ºq¦±","Ãş§O","°Û¤ù¤½¥q","°İÃD©Î·N¨£","¥Ñ #a ¶}µo - ª©¥» ##","·s¼W - ¤µ¤Ñ","·s¼W - ¬Q¤Ñ","·s¼W - ¬P´Á¤é","·s¼W - ¬P´Á¤@","·s¼W - ¬P´Á¤G","·s¼W - ¬P´Á¤T","·s¼W- ¬P´Á¥|","·s¼W - ¬P´Á¤­","·s¼W - ¬P´Á¤»","·j´Mµ²ªG","·j´M±ø¥ó¥²¶·¥Ñ¦Ü¤Ö¨â­Ó¦r¤¸©Ò²Õ¦¨","§ä¤£¨ì²Å¦X­n¨Dªº¶µ¥Ø","§ä¤£¨ìÀÉ®×","§A±N·|³Q±a»â¶i¤J¯¸¥x","½Ğ«ö³o¸Ì","Ä~Äò","¼½©ñ²M³æ","ÀËµø¼½©ñ²M³æ");
  $rosetta["DA"] = array("Danish\tiso-8859-1\tDansk","Dansk","fil","filer","mappe","mapper","vælg alle","ingen","tilføj til liste","fjern fra liste","afspil valgte","afspil alle","listen er ##% fuld","søg","vær venlig at logge ind","brugernavn","kodeord","hjemmeside","indstillinger","om #a","ftp site","kunstnere","albums","sange","genrer","titler","spørgsmål eller kommentarer","genereret af #a version ##","nye i dag","nye i går","nye søndag","nye mandag","nye tirsdag","nye onsdag","nyt torsdag","nye fredag","nye lørdag","søgeresultater","søgeordet skal minimum indeholde 2 karakterer","din søgning gav intet resultat","siden blev ikke fundet","du burde blive viderestillet til sitet","tryk her","for at fortsætte","listen","vis listen");
  $rosetta["DE"] = array("German\tiso-8859-1\tDeutsch","Deutsch","Datei","Dateien","Ordner","Ordner","alles auswählen","aufheben","zur Playlist hinzufügen","aus der Playlist entfernen","Auswahl abspielen","alles Abspielen","die Playlist ist zu ##% voll","durchsuche","Bitte anmelden","Benutzername","Passwort","Homepage","Einstellungen","über #a","FTP Server","Künstler","Alben","Titel","Genres","Labels","Fragen oder Kommentare","Powered by #a version ##","Neu, seit Heute","Neu, seit Gestern","Neu, seit Sonntag","Neu, seit Montag","Neu, seit Dienstag","Neu, seit Mittwoch","Neu, seit Donnerstag","Neu, seit Freitag","Neu, seit Samstag","Suchergebnisse","Der Suchbegriff muß mindestens 2 Zeichen enthalten","Keine Ergebnisse gefunden","Datei nicht gefunden","Sie sollten jetzt auf die Seite weitergeleitet werden","hier klicken","Um fortzufahren","Playlist","Playlist anzeigen");
  $rosetta["ET"] = array("Estonian\tiso-8859-1\tEesti","Eesti","fail","faili","kaust","kausta","vali kõikk","tühista valitud","lisa playlisti","kõrvalda playlistist","mängi valituid","mängi kõiki","playlistist on kasutusel ##%","otsi","palun logi sisse","kasutajanimi","salasõna","kodulehekülg","eelistused","info #a-st","ftp leht","artiste","albumeid","laule","muusika stiile","kaani","küsimused või kommentarid","Powered by #a version ##","uus täna","uus eile","uus Pühapäeval","uus Esmaspäeval","uus Teisipäeval","uus Kolmapäeval","uus Neljapäeval","uus Reedel","uus Lapäeval","otsimise tulemaus","otsitav sõna peaks olema väheamlt 2 tähemärki","sinu päringule ei leidunud vastust","Faili ei leidu","Sind suunatakse uuele lehele","klikki siia","Jätkamaks","playlist","näita playlisti");
  $rosetta["EL"] = array("Greek\tiso-8859-7\tEllinika","ÅëëçíéêÜ","áñ÷åßï","áñ÷åßá","öÜêåëïò","öÜêåëïé","åğéëïãŞ üëùí","êáíİíá","ğñïóèŞêç óôçí ëßóôá","áöáßñåóç áğü ôçí ëßóôá","Ğáßîå ôï åğéëåãìİíï","Ğáßîôá üëá","Ç ëßóôá åßíáé ##% ãåìÜôç","åıñåóç","åßóïäïò","üíïìá ÷ñŞóôç","êùäéêüò","êåíôñéêŞ óåëßäá","ğñïôéìŞóåéò","ó÷åôéêÜ ìå ôçí #a","ftp site","êáëéôİ÷íåò","äßóêïé","ôñáãïıäéá","åßäïò","åôéêİôåò","åñùôŞóåéò Ş ó÷üëéá","öôéáãìİíï ìå #a İêäïóç ##","Íåü óŞìåñá","Íİï ÷ôİò","Íİï ÊõñéáêŞ","Íİï Äåõôİñá","Íİï Ôñßôç","Íİï ÔåôÜñôç","Íİï Ğİìğôç","Íİï ĞáñáóêåõŞ","Íİï ÓáââÜôï","áğïôåëİóìáôá åıñåóçò","ç ëİîç ğñïò áíáæŞôçóç ğñİğåé íá İ÷åé ôïõëÜ÷éóôïí 2 ÷áñáêôŞñåò","äåí âñİèçêå ôßğïôá","Ôï áñ÷åßï äåí âñİèçêå","Èá ìåôáöåñèåßôå óôï site","êÜíôå click åäş","Ãéá íá óõíå÷ßóåôå","ëßóôá ôñáãïõäéşí","äåßôå ôçí ëßóôá ôñáãïõäéşí");
  $rosetta["EN"] = array("English\tiso-8859-1\tEnglish","English","file","files","folder","folders","select all","none","add to playlist","remove from playlist","play selection","play all","the playlist is ##% full","Search","please logon","logon","password","home page","preferences","about #a","ftp site","artists","albums","songs","genres","labels","","","new today","new yesterday","new Sunday","new Monday","new Tuesday","new Wednesday","new Thursday","new Friday","new Saturday","Search results","the search term must be at least 2 characters","no matches found","File not found","You should be redirected into the site","click here","To continue","playlist","view playlist");
  $rosetta["ES"] = array("Spanish\tiso-8859-1\tEspa&ntilde;ol","Español","archivo","archivos","carpeta","carpetas","seleccionar todo","ninguno","añadir a la lista"," quitar de la lista","reproducir selección","reproducir todas","la lista esta ##% llena","buscar en","autentifícate por favor","nombre","contraseña","web inicial","preferencias","acerca de #a","sitio de ftp","artistas","discos","canciones","géneros","disqueras","preguntas o comentarios","soportado por #a versión ##","nueva hoy","nueva ayer","nueva domingo","nueva lunes","nueva martes","nueva miércoles","nueva jueves","nueva viernes","nueva sábado","resultados de la búsqueda","la búsqueda debe tener al menos 2 letras","no se encontraron coincidencias","Archivo no encontrado","Deberías ser redirigido al sitio","pulsa aquí","Para continuar","lista","ver lista");
  $rosetta["FR"] = array("French\tiso-8859-1\tFran&ccedil;ais","Français","fichier","fichiers","dossier","dossiers","sélectionner tout","aucun","ajouter à la liste","enlever de la liste","jouer la sélection","jouer tout","la liste est pleine à ##%","rechercher","enregistrez-vous, svp","usager","mot de passe","acceuil","préférences","à propos d'#a","site ftp","artistes","albums","chansons","genres","maisons d'éditions","questions ou commentaires","généré par #a version ##","ajouté aujourd'hui","ajouté hier","ajouté dimanche","ajouté lundi","ajouté mardi","ajouté mercredi","ajouté jeudi","ajouté vendredi","ajouté samedi","résultats","le mot-clé recherché doit avoir au moins 2 caractères","aucuns résultats pour cette recherche","Le fichier n'a pas été trouvé","Vous devriez être redirigé vers le site","cliquez ici","Pour continuer","liste","voir la liste");
  $rosetta["IS"] = array("Icelandic\tiso-8859-1\t&Iacute;slenska","Íslenska","skrá","skrár","mappa","möppur","velja allt","ekkert","bæta viğ lagalista","fjarlægja af lagalista","spila val","spila allt","lagalistinn er ##% fullur","leita á","skráğu şig inn","notendanafn","lykilorğ","heimasíğa","stillingar","um #a","ftp svæği","listamenn","plötur","lög","tegund","útgáfur","spurningar eğa ábendingar","knúiğ af #a útgáfa ##","nıtt í dag","nıtt í gær","nıtt á sunnudag","nıtt á mánudag","nıtt á şriğjudag","nıtt á miğvikudag","nıtt á fimmtudag","nıtt á föstudag","nıtt á laugardag","niğurstöğur leitar","leitin verğur ağ innihalda ağ minnsta kosti 2 stafi","ekkert fannst","Skráin finnst ekki","Şú ættir ağ vera fluttur á síğuna","smelltu hér","Til ağ halda áfram","agalisti","skoğa lagalista");
  $rosetta["IT"] = array("Italian\tiso-8859-1\tItaliano","Italiano","file","files","cartella","cartelle","seleziona tutto","cancella","aggiungi alla playlist","rimuovi dalla playlist","play selezione","play tutto","la playlist e' piena al ##%","cerca","inserisci utente e password","utente","password","home page","preferenze","informazioni su #a","sito FTP ","artisti","albums","canzoni","generi","etichette","domande o commenti","creato con #a versione ##","aggiunto oggi","aggiunto ieri","aggiunto domenica","aggiunto lunedi","aggiunto martedi","aggiunto mercoledi","aggiunto giovedi","aggiunto venerdi","aggiunto sabato","risultati della ricerca","la parola da cercare deve esse di 2 lettere almeno","nessun risultato per questa ricerca","File non trovato","Sarete rediretti al sito","clicca qui","Per continuare","playlist","guarda la playlist");
  $rosetta["JA"] = array("Japanese\tShift_JIS\tJapanese","“ú–{Œê","ƒtƒ@ƒCƒ‹","•¡”ƒtƒ@ƒCƒ‹","ƒtƒHƒ‹ƒ_","•¡”ƒtƒHƒ‹ƒ_","‘S•”‘I‘ğ","‚È‚µ","ƒŠƒXƒg‚É’Ç‰Á‚·‚é","ƒŠƒXƒg‚©‚çíœ‚·‚é","‘I‘ğ‚µ‚½‹È‚ğÄ¶‚·‚é","‚·‚×‚ÄÄ¶‚·‚é","ƒŠƒXƒg‚Í##%ƒtƒ‹","ƒT[ƒ`","ƒƒOƒIƒ“‚µ‚Ä‚­‚¾‚³‚¢","ƒƒOƒIƒ“","ƒpƒXƒ[ƒh","ƒz[ƒ€ƒy[ƒW","ƒIƒvƒVƒ‡ƒ“","#a‚É‚Â‚¢‚Ä","ftp ƒTƒCƒg","ƒA[ƒeƒBƒXƒg","ƒAƒ‹ƒoƒ€","‹È","ƒWƒƒƒ“ƒ‹","ƒŒ[ƒxƒ‹","¿–â‚Ü‚½‚ÍƒRƒƒ“ƒg","Powered by #a version ##","ŒfÚ¡“ú","ŒfÚğ“ú","ŒfÚ“ú—j“ú","ŒfÚŒ—j“ú","ŒfÚ‰Î—j“ú","ŒfÚ…—j“ú","ŒfÚ–Ø—j“ú","ŒfÚ‹à—j“ú","ŒfÚ“y—j“ú","ŒŸõŒ‹‰Ê","ƒL[ƒ[ƒh‚Í2•¶šˆÈã‚É‚µ‚Ä‚­‚¾‚³‚¢","‚İ‚Â‚©‚è‚Ü‚¹‚ñ‚Å‚µ‚½","ƒtƒ@ƒCƒ‹‚ÍŒ©‚Â‚©‚è‚Ü‚¹‚ñ‚Å‚µ‚½","©“®“I‚ÉƒTƒCƒg‚ÖˆÚ“®‚µ‚Ü‚·","‚±‚±‚ğƒNƒŠƒbƒN‚µ‚Ä‚­‚¾‚³‚¢","‘±‚­","Ä¶ƒŠƒXƒg","Ä¶ƒŠƒXƒg‚ğŒ©‚é");
  $rosetta["KO"] = array("Korean\teuc-kr\tKorean","ÇÑ±¹¾î","ÆÄÀÏ","ÆÄÀÏ","Æú´õ","Æú´õ","¸ğµÎ ¼±ÅÃ","¼±ÅÃ ÇØÁ¦","Àç»ı ¸ñ·Ï¿¡ Ãß°¡","Àç»ı ¸ñ·Ï¿¡¼­ »èÁ¦","¿¬¼Ó µè±â","¸ğµÎ µè±â","ÀÌ¿ë °¡´ÉÇÑ Àç»ı ¸ñ·Ï¿¡¼­ ##% »ç¿ë Áß ÀÔ´Ï´Ù","°Ë»ö","·Î±×ÀÎ ÇÏ¼¼¿ä","·Î±×ÀÎ","ÆĞ½º¿öµå","Ã³À½À¸·Î","¼³Á¤","#a¿¡ ´ëÇÏ¿©","FTP »çÀÌÆ®","¾ÆÆ¼½ºÆ®","¾Ù¹ü","°î¸ñ","Àö¸£","·¹ÀÌºí","À½¾Ç°ú °ü·ÃµÈ ¹®ÀÇ»çÇ×Àº ¸ŞÀÏÁÖ¼¼¿ä","Powered by #a version ##","(Ãß°¡)¿À´Ã","(Ãß°¡)¾îÁ¦","(Ãß°¡)ÀÏ¿äÀÏ","(Ãß°¡)¿ù¿äÀÏ","(Ãß°¡)È­¿äÀÏ","(Ãß°¡)¼ö¿äÀÏ","(Ãß°¡)¸ñ¿äÀÏ","(Ãß°¡)±İ¿äÀÏ","(Ãß°¡)Åä¿äÀÏ","°Ë»ö °á°ú","°Ë»ö¾î´Â ÃÖ¼Ò 2ÀÚ ÀÌ»ó ÀÌ¾î¾ß ÇÕ´Ï´Ù","ÀÏÄ¡ÇÏ´Â ÀÚ·á°¡ ¾ø½À´Ï´Ù","ÆÄÀÏÀ» Ã£À» ¼ö ¾ø½À´Ï´Ù","´Ù½Ã ½Ãµµ ÇØ ÁÖ¼¼¿ä","Å¬¸¯ÇÏ¼¼¿ä","¿©±â¸¦","Àç»ı ¸ñ·Ï","Àç»ı ¸ñ·Ï º¸±â");
  $rosetta["HU"] = array("Hungarian\tiso-8859-2\tMagyar","Magyar","fájl","fájl","könyvtár","könyvtár","mind kiválaszt","semmi","hozzáadás a listához","törlés a listából","kiválasztottak lejátszása","minden lejátszása","a lista ##%-ig tele","Keresés:","Kérem lépj be","Felhasználónév","Jelszó","Kezdõoldal","Beállítások","Az #a-ról","FTP tárhely","Elõadók","Albumok","Dalok","Stílusok","Feliratok","Kérdések vagy megjegyzések","Az oldal az #a ## verzióval készült","Mai újdonságok","Tegnapi újdonságok","Vasárnapi újdonságok","Hétfôi újdonságok","Keddi újdonságok","Szerdai újdonságok","Csütörtöki újdonságok","Pénteki újdonságok","Szombati újdonságok","A keresés eredménye","A keresendô szónak legalább 2 betûbôl kell állni","Nincs találat","A fájl nem található","Mindjárt átirányítunk az oldalunkra","kattints ide","A folytatáshoz","Dalok listája","Lista megtekintése");
  $rosetta["NL"] = array("Dutch\tiso-8859-1\tNederlands","Nederlands","bestand","bestanden","map","mappen","alles selecteren","niets","aan playlist toevoegen","van playlist verwijderen","selectie afspelen","speel alles","de playlist is voor ##% vol","zoek in","Inloggen a.u.b.","gebruikersnaam","wachtwoord","home pagina","instellingen","over #a","ftp site","artiesten","albums","nummers","genres","labels","vragen of opmerkingen","Powered by #a versie ##","nieuw vandaag","nieuw gisteren","nieuw zondag","nieuw maandag","nieuw dinsdag","nieuw woensdag","nieuw donderdag","nieuw vrijdag","nieuw zaterdag","zoekresultaten","de zoekterm moet uit minimaal 2 tekens bestaan","geen zoekresultaten gevonden","Bestand niet gevonden","U wordt naar de site doorgestuurd","klik hier","Om door te gaan","playlist","playlist bekijken");
  $rosetta["NO"] = array("Norwegian\tiso-8859-1\tNorsk","Norsk","fil","filer","mappe","mapper","velg alle","ingen","legg til i spillelisten","fjern fra spillelisten","spill valgte","spill alle","spillelisten er ##% full","Søk","Vennligst logg inn","Brukernavn","Passord","hjem","innstillinger","om #a","ftp side","artister","album","sanger","sjangere","plateselskaper","spørsmål eller kommentarer","Drevet av #a versjon ##","ny i dag","ny i går","ny på søndag","ny på mandag","ny på tirsdag","ny på onsdag","ny på torsdag","ny på fredag","ny på lørdag","søkeresultater","søkestrengen må være på minst 2 tegn","ingen treff","Finner ikke filen","Du burde bli videresendt til siden","klikk her","For å fortsette","spillelisten","se på spillelisten");
  $rosetta["PL"] = array("Polish\tiso-8859-2\tPolski","Polski","plik","plików","folder","folderów","zaznacz wszystko","nic","dodaj do listy","usuñ z listy","odtwórz zaznaczone","odtwórz wszystko","wype³nienie listy ##%","szukaj","zaloguj siê","u¿ytkownik","has³o","strona g³ówna","preferencje","o #a","serwer FTP","wykonawca","albumy","utwory","gatunek","tytu³","pytania lub komentarze","Powered by #a version ##","dzisiejsze nowo¶ci","wczorajsze nowo¶ci","nowo¶æ z niedzieli","nowo¶æ z poniedzia³ku","nowo¶æ z wtorku","nowo¶æ ze ¶rody","nowo¶æ z czwartku","nowo¶æ z pi±tku","nowo¶æ z soboty","wyniki szukania","szukana fraza musi sk³adaæ siê z min. 2 liter","nie znaleziono","Brak pliku","Musisz byæ przekierowany do strony","kliknij tutaj","Kontynuacja","lista odtwarzania","widok listy odtwarzania");
  $rosetta["PT"] = array("Portuguese\tiso-8859-1\tPortugu&ecirc;s","Português","ficheiro","ficheiros","pasta","pastas","seleccionar todos","nenhum","juntar à playlist","remover da playlist","tocar selecção","tocar todos","a playlist está ##% cheia","procure no","por favor identifique-se","utilizador","palavra-passe","homepage","preferências","acerca do #a","site ftp","artistas","álbums","canções","géneros","editoras","questões ou comentários","Powered by #a versão ##","novo hoje","novo ontem","novo domingo","novo segunda-feira","novo terça-feira","novo quarta-feira","novo quinta-feira","novo sexta-feira","novo sábado","resultados da pesquisa","o termo da pesquisa deve ter pelo menos 2 caracteres","nenhum resultado encontrado","Ficheiro não encontrado","Deverá ser redirigido para este site","clique aqui","Para continuar","playlist","ver playlist");
  $rosetta["PT-br"] = array("Portuguese (Brazil)\tiso-8859-1\tPortugu&ecirc;s (Brasil)","Português (Brasil)","arquivo","arquivos","pasta","pastas","selecionar todos","nenhum","adicionar ao playlist","remover do playlist","tocar seleção","tocar todas","o playlist está ##% cheio","procure no","por favor identifique-se","usuário","senha","homepage","preferências","sobre o #a","site ftp","artistas","álbums","músicas","estilos","selos","perguntas ou comentários","Powered by #a versão ##","novo hoje","novo ontem","novo domingo","novo segunda-feira","novo terça-feira","novo quarta-feira","novo quinta-feira","novo sexta-feira","novo sábado","resultados da pesquisa","o termo da pesquisa deve ter pelo menos 2 caracteres","nenhum resultado encontrado","Arquivo não encontrado","Deverá ser redirecionado para este site","clique aqui","Para continuar","playlist","ver o playlist");
  $rosetta["RU"] = array("Russian\tWindows-1251\tPycckuu","Ğóññêèé","ôàéë","ôàéëîâ","ïàïêà","ïàïîê","âûáğàòü âñå","íè÷åãî","äîáàâèòü â ñïèñîê","óäàëèòü èç ñïèñêà","èãğàòü âûäåëåííîå","èãğàòü âñå","ñïèñîê ïîëîí íà ##%","èñêàòü íà","âõîä â ñèñòåìó","èìÿ","ïàğîëü","äîìàøíÿÿ ñòğàíèöà","íàñòğîéêè","îá #a","ñàéò ftp","èñïîëíèòåëè","àëüáîìû","ïåñíè","æàíğû","íàçâàíèÿ","âîïğîñû èëè çàìå÷àíèÿ","ğàáîòàåò íà #a âåğñèè ##","äîáàâëåíî ñåãîäíÿ","äîáàâëåíî â÷åğà","äîáàâëåíî â âîñêğåñåíüå","äîáàâëåíî â ïîíåäåëüíèê","äîáàâëåíî â âòîğíèê","äîáàâëåíî â ñğåäó","äîáàâëåíî â ÷åòâåğã","äîáàâëåíî â ïÿòíèöó","äîáàâëåíî â ñóááîòó","ğåçóëüòàòû ïîèñêà","ñëîâî äëÿ ïîèñêà äîëæíî áûòü áîëåå 2 ñèìâîëîâ â äëèíó","íè÷åãî íå íàéäåíî","Ôàéë íå íàéäåí","Ïğîèñõîäèò ïåğåíàïğàâëåíèå íà ñàéò","ùåëêíèòå çäåñü","Äëÿ ïğîäîëæåíèÿ","ñïèñîê","ïğîñìîòğ ñïèñêà");
  $rosetta["RO"] = array("Romanian\tiso-8859-2\tRom&acirc;na","Românã","fiºier","fiºiere","director","directoare","selecteazã toate","nici unul","adaugã la listã","ºterge din listã","redã selecşia","redã toate","lista de piese este ##% plinã","cautã pe","vã rog conectaşi-vã","utilizator","parola","pagina principalã","preferinşe","despre #a","locaşie ftp","artiºti","albume","piese","stiluri","etichete","întrebãri sau comentarii","creat de #a versiunea ##","adãugat astãzi","adãugat ieri","adãugat Duminicã","adãugat Luni","adãugat Marşi","adãugat Miercuri","adãugat Joi","adãugat Vineri","adãugat Sîmbãtã","rezultatul cãutãrii","cuvîntul de cãutare trebuie sa aibã cel puşin 2 caractere","nu am gãsit nimic","Fiºierul nu existã","Trebuie sã reintri în site","apasã aici","Pentru a continua","lista","vizualizeazã lista");
  $rosetta["SQ"] = array("Albanian\tiso-8859-1\tShqip","Shqip","Fajl-i","Fajl-at","Dosja","Dosjet","zgjedh të gjitha","asnjë","shto ne listë","largo nga lista","dëgjo të zgjedhurën","dëgjo të gjitha","Lista ështe e mbushur ##%","Kërko","Lajmëroheni ju lutem","Emri","Fjalëkalimi","Homepage-i","Konfigurimi","lidhur me #a","ftp faqja","Artistët","Albumet","Këngët","Zhanret","Emërtimet","Pyetjet ose Komentet","Powered by #a version ##","Risi nga sot","Risi nga dje","Risi nga e Diela","Risi nga e Hëna","Risi nga e Marta","Risi nga e Mërkura","Risi nga e Enjtja","Risi nga e Premtja","Risi nga e Shtuna","Rezultatet e kërkimit","Termi që kërkoni duhet të ketë më së paku 2 shkronja","nuk u gjetë asnjë rezultat","Fajli nuk është gjendur","Do te duhej te ridrejtoheshit ne faqen","kliko këtu","për të vazhduar","Lista","shiqo Listën");
  $rosetta["SL"] = array("Slovenian\tiso-8859-2\tSlovenscina","Sloven¹èina","datoteka","datotek","mapa","map","izberi vse","niè","dodaj na seznam","zbri¹i s seznama","predvajaj izbrano","predvajaj vse","seznam je ##% poln","i¹èi","prosim prijavi se","prijava","geslo","domaèa stran","preference","o #a","ftp server","izvajalci","albumi","skladbe","¾anr","zalo¾be","vpra¹anja ali pripombe","Powered by #a version ##","novo danes","novo od vèeraj","novo od nedelje","novo od ponedeljka","novo od torka","novo od srede","novo od èetrtka","novo od petka","novo od sobote","i¹èi po zadetkih","iskani termin naj vsebuje vsaj 2 znaka","ni zadetkov","Datoteka ni najdena","Preusmerjeni bi morali biti na stran","klikni tukaj","Za nadaljevanje","seznam","poglej seznam");
  $rosetta["SK"] = array("Slovak\tiso-8859-2\tSlovensky","Slovensky","súbor","súbory","zlo¾ka","zlo¾ky","vybra» v¹etko","zma¾ vıber","prida» do playlistu","odstráni» z playlistu","prehra» vybrané","prehra» v¹etko","playlist je z ##% plnı","hµada» v","prihláste sa prosím","meno","heslo","titulná strana","nastavenie","o Andromede","ftp server","umelci","albumi","piesne","¾ánre","labely","otázky alebo komentáre","pou¾íva Andromedu verzie ##","novinka dnes","novinka vèera","novinka Nedele","novinka Pondelka","novinka Utorka","novinka Stredy","novinka ©tvrtka","novinka Piatku","novinka Soboty","vısledky vyhµadávania","zadejte aspoò 2 znaky","niè nenájdené","Súbor nenájdenı","Budete presmerovánı na","kliknite tu","Pokraèova»","playlist","prohliadnu» playlist");
  $rosetta["SR"] = array("Serbian\tiso-8859-2\tSrpski","Srpski","fajl","fajla","direktorijum","direktorijuma","selektuj sve","ni¹ta","dodaj u listu","izbri¹i iz liste","slu¹aj selektovano","slu¹aj sve","lista je ##% puna","pretraga","molimo da se ulogujete","logovanje","¹ifra","glavna strana","pode¹avanja","#a","ftp strana","umetnici","albumi","pesme","¾anrovi","labele","pitanja ili komentari","Powered by #a version ##","novi danas","novi juèe","novi Nedelja","novi Ponedeljak","novi Utorak","novi Sreda","novi Èetvrtak","novi Petak","novi Subota","rezultati pretrage","morate uneti najmanje 2 slova za pretragu","ni¹ta nije pronağeno","Fajl nije pronağen","Trebalo bi da budete poslani na sajt","kliknite ovde","Da nastavite","lista","pogledaj listu");
  $rosetta["FI"] = array("Finnish\tiso-8859-1\tSuomi","Suomi","tiedosto","tiedostoa","kansio","kansiota","valitse kaikki","poista valinnat","lisää soittolistaan","poista soittolistasta","soita valitut","soita kaikki","soittolistan tilasta on käytössä ##%","etsi palvelimelta","kirjaudu järjestelmään","käyttäjätunnus","salasana","kotisivu","asetukset","tietoja #a:sta","ftp-palvelin","artistit","albumit","kappaleet","musiikkityylit","levy-yhtiöt","kysymykset tai kommentit","järjestelmä on toteutettu #a versiolla ##","uusi tänään","uusi eilen","uusi sunnuntai","uusi maanantai","uusi tiistai","uusi keskiviikko","uusi torstai","uusi perjantai","uusi lauantai","haun tulokset","hakusanan tulee olla vähintään 2 kirjaimen pituinen","hakusanalla ei löytynyt tiedostoja","Tiedostoa ei löydy","Selaimesi pitäisi ohjautua uudelle sivulle","paina tästä","Jatkaaksesi","soittolista","näytä soittolista");
  $rosetta["SV"] = array("Swedish\tiso-8859-1\tSvenska","Svenska","fil","filer","mapp","mappar","välj alla","inga","lägg till spellistan","radera från spellistan","spela urvalet","spela alla","spellistan är till ##% full","sök i","Logga in tack","loggin","lösenord","hemsida","inställningar","om #a","ftp adress","artist","album","sånger","kategori","skivmärke","frågor och kommentarer","skapad av #a version ##","ny idag","ny igår","ny Söndag","ny Måndag","ny Tisdag","ny Onsdag","ny Torsdag","ny Fredag","ny Lördag","sök resultat","sökordet måste vara minst 2 tecken","inga träffar funna","inga filer funna","du blir vidarbefodrad till sidan","tryck här","fortsätt","spellistan","visa spellista");
  $rosetta["TR"] = array("Turkish\tiso-8859-9\tT&uuml;rk&ccedil;e","Türkçe","dosya","dosya","dizin","dizin","hepsini seç","hiçbiri","listeye ekle","listeden çıkar","seçimi çal","hepsini çal","liste ##% dolu","ara","lütfen giriş yapın","kullanıcı","şifre","ana sayfa","ayarlar","#a hakkında","ftp site","artistler","albümler","şarkılar","türler","etiketler","sorular veya öneriler","destekleyen; #a versiyon ##","yeni bugün","yeni dün","yeni Pazar","yeni Pazartesi","yeni Salı","yeni Çarşamba","yeni Perşembe","yeni Cuma","yeni Cumartesi","arama sonuçları","arama kriteri en az 2 karakterli olmalı","aranan kayıt bulunamadı","Dosya bulunamadı","Siteye gönderilebilirsiniz","buraya tıklayın","Devam için","liste","listeye gözat");
  $rosetta["VI"] = array("Vietnamese\tUTF-8\tViet Ngu","Vi&#7879;t Ng&#7919;","H&#7891; s&#417;","H&#7891; s&#417;","T&#7853;p nh&#7841;c","T&#7853;p nh&#7841;c","Ch&#7885;n t&#7845;t c&#7843;","kh&#244;ng","Th&#234;m v&#224; danh s&#225;ch","X&#243;a t&#7915; danh s&#225;ch","Nghe b&#7843;n nh&#7841;c","Nghe danh s&#225;ch nh&#7841;c","Danh s&#225;ch nh&#7841;c ##% &#273;&#7847;y","T&#236;m","Xin &#273;&#259;ng nh&#7853;p","&#272;&#259;ng nh&#7853;p","M&#7853;t m&#227;","Trang ch&#7911;","&#221; th&#237;ch","V&#224;i n&#233;t v&#7873; #a","Th&#432; vi&#7879;n FTP","Ca s&#297;","albums","b&#7843;n nh&#7841;c","th&#7875; lo&#7841;i nh&#7841;c","trung t&#226;m","C&#226;u h&#7887;i / &#253; ki&#7871;n","Thi&#7871;t k&#7871; b&#7903;i #a ##","B&#224;i m&#7899;i h&#244;m nay","B&#224;i m&#7899;i h&#244;m qua","B&#224;i m&#7899;i Ch&#7911; nh&#7853;t","B&#224;i m&#7899;i th&#7913; Hai","B&#224;i m&#7899;i th&#7913; Ba","B&#224;i m&#7899;i th&#7913; T&#432;","B&#224;i m&#7899;i th&#7913; N&#259;m","B&#224;i m&#7899;i th&#7913; S&#225;u","B&#224;i m&#7899;i th&#7913; B&#7843;y","D&#242; t&#236;m nh&#7841;c","T&#7915; t&#236;m ki&#7871;m ph&#7843;i h&#417;n 2 ch&#7919;","Kh&#244;ng t&#236;m th&#7845;y","T&#236;m kh&#244;ng th&#7845;y b&#7843;n nh&#7841;c","B&#7841;n s&#7869; &#273;&#432;&#7907;c &#273;&#432;a v&#224;o th&#432; vi&#7879;n","B&#7845;m v&#224;o &#273;&#226;y","Ti&#7871;p t&#7909;c","Danh s&#225;ch nh&#7841;c","Coi danh s&#225;ch nh&#7841;c");
  loadConstants();
  loadDefaults();
  loadPrefs();
  if ($andromedaPrefs["timeout"] != "") {
    set_time_limit($andromedaPrefs["timeout"]);
  }
  if ($andromedaPrefs["rootName"] == "") {
    $andromedaPrefs["rootName"] = displayName($andromedaPrefs["mediaPhysicalPath"],false);
  }
  if ($andromedaPrefs["rootName"] == "") {
    $andromedaPrefs["rootName"] = "root";
  }
  $sck = !(!$andromedaConst["moduleMode"] && $andromedaPrefs["moduleOnly"]);
  if ($sck) {
    $sck = !((substr(__FILE__,-1) == "\\") || (substr(__FILE__,-1) == "/"));
  }
  if ($sck) {
    $sck = !strpos(strtolower($PHP_SELF), substr(__FILE__,strrpos(__FILE__,".")) . "/");
  }
  if (!$sck) {
    exit();
  }
  if (($andromedaPrefs["coreInclude"] != "") && (!$andromedaConst["moduleMode"])) {
    include($andromedaPrefs["coreInclude"]);
  }
  if ($andromedaPrefs["useExtLogon"]) {
    if (function_exists("is_user")) {
      if (!is_user($user)) {
	Header("Location: user.php");
      }
    } else {
      if (!isset($user)) {
	Header("Location: user.php");
      }
    }
  }
  if ($andromedaConst["moduleMode"]) {
    $andromedaPrefs["disableHTMLheaders"] = true;
  }
  for ($rpi = 1; $rpi <= $andromedaPrefs["cBlockCount"]; $rpi++) {
    $rtmp2 = "playlist" . $rpi;
    if ($$rtmp2 == "") {
      $$rtmp2 = $HTTP_COOKIE_VARS["playlist" . $rpi];
    }
  }
  if ($logon == "") {
    $logon = $HTTP_COOKIE_VARS["logon"];
  }
  if ($password == "") {
    $password = $HTTP_COOKIE_VARS["password"];
  }
  if ($clang == "") {
    $clang = $HTTP_COOKIE_VARS["clang"];
  }
  if ($f == "") {
    $f = $HTTP_GET_VARS["f"];
  }
  if ($f == "") {
    $f = $HTTP_POST_VARS["f"];
  }
  if ($m == "") {
    $m = $HTTP_GET_VARS["m"];
  }
  if ($m == "") {
    $m = $HTTP_POST_VARS["m"];
  }
  if ($p == "") {
    $p = $HTTP_GET_VARS["p"];
  }
  if ($p == "") {
    $p = $HTTP_POST_VARS["p"];
  }
  if ($q == "") {
    $q = $HTTP_GET_VARS["q"];
  }
  if ($q == "") {
    $q = $HTTP_POST_VARS["q"];
  }
  if ($s == "") {
    $s = $HTTP_GET_VARS["s"];
  }
  if ($s == "") {
    $s = $HTTP_POST_VARS["s"];
  }
  if ($sm == "") {
    $sm = $HTTP_GET_VARS["sm"];
  }
  if ($sm == "") {
    $sm = $HTTP_POST_VARS["sm"];
  }
  if ($y == "") {
    $y = $HTTP_GET_VARS["y"];
  }
  if ($y == "") {
    $y = $HTTP_POST_VARS["y"];
  }
  if ($t == "") {
    $t = $HTTP_GET_VARS["t"];
  }
  if ($t == "") {
    $t = $HTTP_POST_VARS["t"];
  }
  if ($flogon == "") {
    $flogon = $HTTP_POST_VARS["flogon"];
  }
  if ($fpassword == "") {
    $fpassword = $HTTP_POST_VARS["fpassword"];
  }
  $fttmpa = explode(",",strtolower($andromedaPrefs["audioFileTypes"]));
  for ($fti = 0; $fti < count($fttmpa); $fti++) {
    $fileTypes[$fttmpa[$fti]] = "audio";
  }
  $fttmpa = explode(",",strtolower($andromedaPrefs["videoFileTypes"]));
  for ($fti = 0; $fti < count($fttmpa); $fti++) {
    $fileTypes[$fttmpa[$fti]] = "video";
  }
  $fttmpa = explode(",",strtolower($andromedaPrefs["playlistFileTypes"]));
  for ($fti = 0; $fti < count($fttmpa); $fti++) {
    $fileTypes[$fttmpa[$fti]] = "playlist";
  }
  $fttmpa = explode(",",$andromedaPrefs["folderSkipNames"]);
  for ($fti = 0; $fti < count($fttmpa); $fti++) {
    $folderSkipNames[$fttmpa[$fti]] = true;
  }
// This appears to check that certain constants have not changed
// It does this by changing the array to a string - the first one
// equals "edition" - then getting that out of $andromedaConst.
// The second transformation evaluates to "EVALUATION COPY".
// Not too sneaky - easily defeated...
//  if ($andromedaConst[ca2s(array(101,100,105,116,105,111,110))] != ca2s(array(69,86,65,76,85,65,84,73,79,78,32,67,79,80,89))) {
//    exit();
//  }
  loadSkin();
  loadLogons();
  $totalrowcount = 0;
  $filerowcount = 0;
  $plrpre = "";
  if ($andromedaPrefs["permitTranslation"]) {
    if ($t != "") {
      $currentLanguage = $t;
    } else {
      if ($clang != "") {
	$currentLanguage = $clang;
      } else {
	$currentLanguage = $andromedaPrefs["defaultLanguage"];
      }
    }
  } else {
    $currentLanguage = $andromedaPrefs["defaultLanguage"];
  }
  $clangCodes = explode("\t",$rosetta[$currentLanguage][0]);
  if (!($andromedaPrefs["requireLogon"]) || $andromedaConst["localUser"]) {
    $permitAccess = true;
  } else {
    $permitAccess = (($andromedaLogons[$logon] == $password) && ($logon != "") && ($q != "l"));
  }
  if (($andromedaConst[ca2s(array(97,112,112,97,117,116,104))] != ca2s(array(83,99,111,116,116,32,77,97,116,116,104,101,119,115))) || ($andromedaConst[ca2s(array(97,112,112,99,111,114,112))] != ca2s(array(84,117,114,110,115,116,121,108,101))) || ($andromedaConst[ca2s(array(97,112,112,110,97,109,101))] != ca2s(array(65,110,100,114,111,109,101,100,97))) || ($andromedaConst[ca2s(array(97,112,112,114,111,111,116))] != ca2s(array(104,116,116,112,58,47,47,119,119,119,46,116,117,114,110,115,116,121,108,101,46,99,111,109,47,97,110,100,114,111,109,101,100,97)))) {
    exit();
  }
  if (!$permitAccess) {
    if ($q == "l") {
      $permitAccess2 = (($andromedaLogons[$flogon] == $fpassword) && ($flogon != "") && ($fpassword != ""));
      if (!$permitAccess2) {
	if (($t != "") && $andromedaPrefs["permitTranslation"]) {
	  setcookie("clang", $currentLanguage);
	}
	andromedaHeader(trans(14));
	echo "<table cellspacing=0 cellpadding=4 border=0 width=\"" . $andromedaPrefs["siteWidth"] . "\" bgcolor=\"" . $andromedaPrefs["bodyFgColor"] . "\" height=220><tr><td align=center>";
	if ($andromedaPrefs["logonMessage"] != "") {
	  echo "<font size=\"2\">" . $andromedaPrefs["logonMessage"] . "</font>";
	  addvpad(12);
	}
	echo "<table cellspacing=0 cellpadding=1 border=0 bgcolor=\"" . $andromedaPrefs["menubarColor"] . "\"><form method=post action=" . andrLink("","") . "><input type=hidden name=q value=l><tr><td><table cellspacing=0 cellpadding=2 border=0 bgcolor=\"" . $andromedaPrefs["rowColor1"] . "\" width=100%><tr><td><font face=\"helvetica,arial\" size=\"1\" color=\"" . $andromedaPrefs["rowTextColor"] . "\">" . trans(14) . "</font></td></tr></table>";
	colorbar("100%","1",$andromedaPrefs["menubarColor"]);
	echo "<table cellspacing=0 cellpadding=0 border=0 bgcolor=\"" . $andromedaPrefs["rowColor2"] . "\" width=100%><tr><td><table cellspacing=0 cellpadding=2 border=0 width=100%><tr><td align=right><font size=\"1\" face=\"helvetica,arial\" color=\"" . $andromedaPrefs["rowTextColor"] . "\">" . trans(15) . ":</font></td><td><input name=flogon size=16 value=\"" . htmlspecialchars($flogon) . "\" style=\"font-size:9pt;\"></td></tr><tr><td align=right><font size=\"1\" face=\"helvetica,arial\" color=\"" . $andromedaPrefs["rowTextColor"] . "\">" . trans(16) . ":</font></td><td><input name=fpassword type=password size=16 style=\"font-size:9pt;\"></td></tr></table></td><td>";
	ipad(4,1);
	echo "</td><td>";
	imagetag("g","f","");
	echo "</td><td>";
	ipad(2,1);
	echo "</td></tr></table></td></tr></form></table></td></tr></table>";
	colorbars($andromedaPrefs["bodyFgDiv"]);
	andromedaFooter();
      } else {
	setcookie("logon", fixgpc($flogon));
	setcookie("password", fixgpc($fpassword));
	andromedaHeaderCore(trans(41),true);
	echo "<table cellspacing=0 cellpadding=4 border=0 width=\"" . $andromedaPrefs["siteWidth"] . "\" bgcolor=\"" . $andromedaPrefs["bodyFgColor"] . "\" height=220><tr><td align=center>";
	if ($andromedaPrefs["disableHTMLheaders"]) {
	  echo "<font color=" . $andromedaPrefs["bodyTextColor"] . ">";
	}
	echo trans(41) . ". " . trans(43) . ", ";
	if ($andromedaPrefs["disableHTMLheaders"]) {
	  echo "<a href=" . andrLink("","") . " style=\"color:" . $andromedaPrefs["bodyLinkColor"] . "\"><font color=\"" . $andromedaPrefs["bodyLinkColor"] . "\">" . trans(42) . "</font></a>";
	} else {
	  echo "<a href=" . andrLink("","") . ">" . trans(42) . "</a>";
	}
	echo ".";
	if ($andromedaPrefs["disableHTMLheaders"]) {
	  echo "</font>";
	}
	echo "</td></tr></table>";
	colorbars($andromedaPrefs["bodyFgDiv"]);
	andromedaFooter();
      }
    } else {
      if (($t != "") && $andromedaPrefs["permitTranslation"]) {
	header("Location: " . andrLink("?q=l&t=" . $t,""));
      } else {
	header("Location: " . andrLink("?q=l",""));
      }
    }
  } else {
    if (($t != "") && $andromedaPrefs["permitTranslation"]) {
      setcookie("clang", fixgpc($currentLanguage));
    }
    $ckplaylist = readPlaylist("playlist");
    if (($q == "f") && vpath(fixgpc($f))) {
      showfolder(fixgpc($f));
    } elseif (($q == "p") && vpath(fixgpc($p)) && $andromedaPrefs["playLinks"]) {
      playFolder(fixgpc($p));
    } elseif (($q == "m") && vpath(fixgpc($m)) && $andromedaPrefs["playLinks"]) {
      playPrepList("i" . fixgpc($m) . "\n");
    } elseif (($q == "s") && $andromedaPrefs["permitSearch"]) {
      search(fixgpc($s),$sm);
    } elseif (($q == "y") && ($andromedaPrefs["permitPlaylists"])) {
      switch ($y) {
	case "p":
	  if ($andromedaPrefs["playLinks"]) {
	    playPrepList($ckplaylist);
	  }
	  break;
	case trans(10):
	  if ($andromedaPrefs["playLinks"]) {
	    if ($m == 1) {
	      for ($i=0; $i < count($f); $i++) {
		$pftmp = $pftmp . fixgpc($f[$i]) . "\n";
	      }
	      playPrepList($pftmp);
	    } else {
	      $selectlist = " ";
	      for ($i=0; $i < count($f); $i++) {
		$selectlist = $selectlist . "[" . $f[$i] . "]";
	      }
	      $xtmpa = explode("\n",$ckplaylist);
	      for ($xi = 0; $xi < count($xtmpa)-1; $xi++) {
		if (strpos($selectlist,"[" . ($xi + 1) . "]") != 0) {
		  $xtmp = $xtmp . $xtmpa[$xi] . "\n";
		}
	      }
	      playPrepList($xtmp);
	    }
	  }
	  break;
	case trans(8):
	  $xtmp = readPlaylist("playlist");
	  for ($i=0; $i < count($f); $i++) {
	    if (vpath(substr($f[$i],1))) {
	      $xtmp = $xtmp . fixgpc($f[$i]) . "\n";
	    }
	  }
	  $xtmp = substr($xtmp,0,$andromedaPrefs["cBlockSize"] * $andromedaPrefs["cBlockCount"] = 1);
	  $xtmp = substr($xtmp,0,strrpos($xtmp,"\n")+1);
	  $ckplaylist = $xtmp;
	  writePlaylist("playlist");
	  displayPlaylist("playlist");
	  break;
	case trans(45):
	  displayPlaylist("playlist");
	  break;
	case trans(9):
	  $removelist = " ";
	  for ($i=0; $i < count($f); $i++) {
	    $removelist = $removelist . "[" . $f[$i] . "]";
	  }
	  $xtmpa = explode("\n",$ckplaylist);
	  for ($xi = 0; $xi < count($xtmpa)-1; $xi++) {
	    if (strpos($removelist,"[" . ($xi + 1) . "]") == 0) {
	      $xtmp = $xtmp . $xtmpa[$xi] . "\n";
	    }
	  }
	  $ckplaylist = $xtmp;
	  writePlaylist("playlist");
	  displayPlaylist("playlist");
	  break;
	default:
	  showfolder("");
      }
    } else {
      showfolder("");
    }
  }
}
?>
