<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	$RCSfile: clearscm.php,v $
// Revision:	$Revision: 1.23 $
// Description:	Reports large files
// Author:	Andrew@DeFaria.com
// Created:	Wed Apr 11 18:37:09 2007
// Modified:	$Date: 2013/03/18 22:46:55 $
// Language:	Php
//
// (c) Copyright 2007, ClearSCM Inc., all rights reserved
//
////////////////////////////////////////////////////////////////////////////////
include_once "scm.php";

date_default_timezone_set('America/Los_Angeles');

$base = $_SERVER['DOCUMENT_ROOT'];

function menu_css () {
  global $base;

  $lines = @file ("$base/css/Menus.css")
    or die ("Unable to open $base/css/Menus.css");

  print "<style type=\"text/css\">\n";

  foreach ($lines as $line) {
    print $line;
  } // foreach

  print "</style>";
} // menu_css

function menu () {
  print <<<END
<div class="imrcmain0 imgl" style="width:100%;z-index:999999;position:relative;">
  <div class="imcm imde" id="imouter0">
    <ul id="imenus0">
    <li class="imatm" style="width:100px;"><a href="/"><span class="imea imeam"></span>Home</a></li>

    <li class="imatm" style="width:145px;">
      <a class="" href="/services"><span class="imea imeam"><span></span></span>Services</a>

      <div class="imsc">
        <div class="imsubc" style="width:145px;top:0px;left:0px;">
          <ul style="">
            <li><a href="/services/consultancy.php">Consultancy</a></li>
            <li><a href="/services/custom_software.php">Custom Software Solutions</a></li>
            <li><a href="/services/sysadmin.php">Systems Adminsitration</a></li>
            <li><a href="/services/web.php">Web Applications</a></li>
            <li><a href="/services/customers.php">Customers</a></li>
          </ul>
        </div>
      </div>
    </li>

    <li class="imatm" style="width:145px;">
      <a class="" href="/services/scm"><span class="imea imeam"><span></span></span>SCM</a>

      <div class="imsc">
        <div class="imsubc" style="width:145px;top:0px;left:0px;">
          <ul style="">
            <li><a href="/clearcase"><span class="imea imeas"><span></span></span>Clearcase</a>
              <div class="imsc">
                <div class="imsubc" style="width:140px;top:-23px;left:132px;">
                  <ul style="">
                    <li><a href="/clearcase/triggers.php">Triggers</a></li>
                    <li><a href="/php/scm_man.php?file=cc/etf.pl">Evil Twin Finder</a></li>
                    <li><a href="/php/scm_man.php?file=cc/diffbl.pl">GUI DiffBL</a></li>
                    <li><a href="/php/scm_man.php?file=clearadm/viewager.cgi">View Ager</a></li>
                    <li><a href="/clearcase/OpenSourceBuild.php/">Open Source Builds</a></li>
                  </ul>
                </div>
              </div>
            </li>
            <li><a href="/clearquest"><span class="imea imeas"><span></span></span>Clearquest</a>
              <div class="imsc">
                <div class="imsubc" style="width:140px;top:-23px;left:132px;">
                  <ul style="">
                    <li><a href="/clearquest/cqd">Clearquest Daemon</a></li>
                    <li><a href="/clearquest/db.php">DB Conversions</a></li>
                  </ul>
                </div>
              </div>
            </li>
            <li><a href="/scm"><span class="imea imeas"><span></span></span>Git</a>
              <div class="imsc">
                <div class="imsubc" style="width:140px;top:-23px;left:132px;">
                  <ul style="">
                    <li><a href="/gitweb/?p=clearscm.git">Repository</a></li>
                  </ul>
                </div>
              </div>
            </li>
          </ul>
        </div>
      </div>
    </li>

    <li class="imatm" style="width:145px;"><a href="/scripts"><span class="imea imeam"><span></span></span>Scripting</a>
      <div class="imsc">
        <div class="imsubc" style="width:146px;top:0px;left:0px;">
          <ul style="">
            <li><a href="/scripts/perl.php">Perl</a></li>
            <li><a href="/scripts/ecrd">ECRDig</a></li>
          </ul>
        </div>
      </div>
    </li>

    <li class="imatm" style="width:145px;"><a href="/sysadm"><span class="imea imeam"><span></span></span>Sysadm</a>
      <div class="imsc">
        <div class="imsubc" style="width:146px;top:0px;left:0px;">
          <ul style="">
            <li><a href="/sysadm/env">Environment</a></li>
          </ul>
        </div>
      </div>
    </li>

    <li class="imatm" style="width:145px;"><a href="#"><span class="imea imeam"><span></span></span>About</a>
      <div class="imsc">
        <div class="imsubc" style="width:146px;top:0px;left:0px;">
          <ul style="">
            <li><a href="/services">Services</a></li>
            <li><a href="/people.php">Our People</a></li>
            <li><a href="/contact.php">Contact Us</a></li>
          </ul>
        </div>
      </div>
    </li>
  </ul>

  <div class="imclear">&nbsp;</div>
  </div>
</div>
END;
} // menu

function heading () {
  print "<div id=head>";
  menu ();
  print <<<END
  <h1 style="color:#fff;text-align:center;font-size:3em">ClearSCM Inc.</h1>

  <div class="filtered">
    <p><strong>You are viewing an unstyled version of this
    page.</strong> Either your browser does not support Cascading
    Style Sheets (CSS) or CSS styling has been disabled.</p>
  </div>
END;
} // heading

function start_box ($type) {
  print <<<END
<!--B-->  <div class="rcbox"><div class="$type"><b class="xtop"><b class="xb1"></b><b class="xb2"></b><b class="xb3"></b><b class="xb4"></b></b><div class="xboxcontent">
END;
} // start_box

function end_box () {
  print <<<END
<!--A-->  </div><b class="xbottom"><b class="xb4"></b><b class="xb3"></b><b class="xb2"></b><b class="xb1"></b></b></div></div>
END;
} // end_box

function search_box () {
  print <<<END
<div id="search">
  <!-- Start: Search my site with Google -->
  <form method="get" action="http://www.google.com/search" name="search">
  <div>Search my site
  <input type="text" name="q" size="15" id="q" maxlength=255 value=""
    onclick="document.search.q.value='';">
  <input type="hidden" name="domains" value="clearscm.com">
  <input type="hidden" name="sitesearch" value="clearscm.com">
  </div>
  </form>
  <!-- End: Search my site with Google -->
</div>
<br>
END;
} // search_box

function copyright ($start_year	= "",
		    $author	= "Andrew DeFaria",
	            $email	= "info@clearscm.com",
		    $home       = "") {
  global $base;

  $today	= getdate ();
  $current_year	= $today ["year"];

  $this_file = $base . "/" . $_SERVER['PHP_SELF'];

  $mod_time  = date ("F d Y @ g:i a", filemtime ($this_file));

  print <<<END
<div id="foot"><p>
  Last modified: $mod_time<br>
  Copyright &copy;&nbsp;
END;

  if ($start_year != "") {
    print "$start_year-";
  } // if

print <<<END
$current_year, ClearSCM Inc. - All rights reserved
</p></div>
END;
} // copyright

function display_contents_as_code ($contents) {
  print "<div class=code>";
  print "<table id=listing cellspacing=0 cellpadding=2 border=0 width=90%>";

  $line_number = 1;

  foreach ($contents as $line) {
    print "<tr>";
    print "  <td id=line-number><a name=line_$line_number></a>" .
      $line_number++ . "</td>";
    print "  <td id=code><tt>";

    for ($i = 0; $i < strlen ($line); $i++) {
      if ($line [$i] == " ") {
	if ($i == 0 && $line_number == 2) {
	  continue;
	} // if
	echo "&nbsp;";
      } else if ($line [$i] == "\t") {
	echo "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
      } else if ($line [$i] != "\n") {
	echo $line [$i];
      } // if
    } // for

    print "</tt></td>";
    print "</tr>\n";
  } // foreach

  print "</table>";
  print "</div>";
} // display_contents_as_code

function display_contents_as_snippet ($contents) {
  print "<div class=code>";

  foreach ($code as $line) {
    for ($i = 0; $i < strlen ($line); $i++) {
      if ($line [$i] == " ") {
	echo "&nbsp;";
      } else if ($line [$i] == "\t") {
	echo "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
      } else if ($line [$i] != "\n") {
	echo $line [$i];
      } // if
    } // for
  } // foreach

  print "</div>";
} // display_contents_as_snippet

function display_code ($file) {
  display_contents_as_code (getSCMFile ($file));
} # display_code

function scm_man ($file) {
  $desc_spec = array (
    0 => array ("pipe", "r"), // stdout
    1 => array ("pipe", "w"), // stdin
    2 => array ("pipe", "w"), // stderr
  );

  $pod2html = proc_open ("pod2html -cachedir /tmp -noindex -htmlroot=http://perldoc.perl.org", $desc_spec, $pipes);

  if (!is_resource ($pod2html)) {
    die ("Unable to start pod2html");
  } // if

  $stdin	= $pipes [0];
  $stdout	= $pipes [1];
  $stderr	= $pipes [2];

  $contents = getSCMFile ($file);

  // Write to stdin
  foreach ($contents as $line) {
    fwrite ($stdin, $line);
  } // foreach
  fclose ($stdin);

  $end_of_index	  = 0;
  $pre_just_ended = 0;
  $url            = "/gitweb/?p=clearscm.git;a=blob_plain;f=$file;hb=HEAD";
  $history        = "/gitweb/?p=clearscm.git;a=history;f=$file;hb=HEAD";

  // Now get the output and write it out
  while (!feof ($stdout)) {
    $line = fgets ($stdout);

    // Filter some CVS keywords properly
    $line = preg_replace ("/\\\$Revision\:\s*(\S*)\s*\\\$/",
    			  "Revision <a href=\"$history\">$1</a>",
			  $line);
    $line = preg_replace ("/\\\$Date\:\s*(.*)\s*\\\$/",
    			  "Modifed $1",
			  $line);
    $line = preg_replace ("/\\\$RCSfile\:\s*(\S*),v\s*\\\$/",
    			  "$1",
			  $line);

    // Collapse adjacent <pre> sections to instead have a simple blank
    // line
    if (preg_match ("/<\/pre>$/", $line)) {
      $line = preg_replace ("/<\/pre>/", "", $line);
      print "$line\n";
      $pre_just_ended = 1;
      continue;
    } // if

    if (preg_match ("/^<pre>$/", $line)) {
      if ($pre_just_ended) {
        $pre_just_ended = 0;
	continue;
      } // if
    } else {
      if ($pre_just_ended) {
        $pre_just_ended = 0;
	echo "</pre></div>$line";
	continue;
      } // if
    } // if

    $line = preg_replace ("/<pre>/",
			  "<div class=code><pre>",
			  $line);
    $line = preg_replace ("/<\/pre>/",
			  "</pre></div>",
			  $line);
    $line = preg_replace ("/<a name=.*>(.*)<\/a>/",
			  "$1",
			  $line);
    $line = preg_replace ("/NAME (\S*)<\/h1>/",
    			  "NAME $1 <a href=\"$url\"><img src=\"/Icons/Download.jpg\" border=0 title=Download></a></h1>",
			  $line);
    $line = preg_replace ("/NAME (\S*)<\/h2>/",
    			  "NAME $1 <a href=\"$url\"><img src=\"/Icons/Download.jpg\" border=0 title=Download></a></h2>",
			  $line);
    echo $line;
  } // while

  fclose ($stdout);
  fclose ($stderr);

  proc_close ($pod2html);
} // scm_man
?>
