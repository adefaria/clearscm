<?php
function menu () {
  $main_links	= "/web/index.links";
  $local_links	= "index.links";

  if (is_readable ($local_links)) {
    $links = @file ($local_links)
      or die ("Unable to open local links file ($local_links)");
  } else {
    $links = @file ($main_links)
      or die ("Unable to open main links file ($main_links)");
  } // if

  print "<div id=menu>\n";

  foreach ($links as $link) {
    $link_desc = explode ("|", chop ($link));
    print "<a href=\"" . $link_desc[0] . "\">" . $link_desc[1] . "</a><br>\n";
  } // foreach
  print "</div>\n";
} // menu

function search_box () {
  print <<<END
<div id="search">
  <!-- Start: Search my site with Google -->
  <form method="get" action="https://www.google.com/search" name="search">
  <div>Search my site
  <input type="text" name="q" size="15" id="q" maxlength=255 value=""
    onclick="document.search.q.value='';">
  <input type="hidden" name="domains" value="defaria.com">
  <input type="hidden" name="sitesearch" value="defaria.com">
  </div>
  </form>
  <!-- End: Search my site with Google -->
</div>
<br>
END;
} // search_box

function navigation_bar ($validated = "no") {
  print "<div class=leftbar>\n";
  search_box ();
  menu ();
  print <<<END
  <script src="/maps/JavaScript/CheckAddress.js" type="text/javascript"></script>
  <div id="emailsearch">
  <form "method"=post action="javascript://" name="address" onsubmit="checkaddress(this,'andrew');">
    <a href="/maps/doc">Can you email me?</a>
    Type in your email address and hit enter to see.
    <input type="text" class="searchfield" id="emailsearchfield" name="email"
     size="18" maxlength="255" value="" onclick="document.address.email.value = '';">
  </form>
  </div>
</div>
END;
} // navigation_bar

function copyright ($start_year	= "",
		    $author	= "Andrew DeFaria",
	            $email	= "Andrew@DeFaria.com",
		    $home       = "") {
  $today	= getdate ();
  $current_year	= $today ["year"];

  $this_file = $_SERVER['PHP_SELF'];

  // Handle user home web pages
  if (preg_match ("/\/\~/", $this_file)) {
    $this_file= preg_replace ("/\/\~(\w+)\/(\s*)/", "/home/$1/web$2/", $this_file);
  } else {
    $this_file = "/web" . $this_file;
  } // if

  $mod_time  = date ("F d Y @ g:i a", filemtime ($this_file));

  print <<<END
<div class="copyright">
Last modified: $mod_time<br>
Copyright &copy; 
END;

  if ($start_year != "") {
    print "$start_year-";
  } // if

print <<<END
$current_year - All rights reserved<br>
<a href="$home/"><img src="/Icons/HomeSmall.gif" alt="Home">&nbsp;$author</a> &lt;<a
href="mailto:$email">$email</a>&gt;
</div>
END;
} // copyright

function display_code ($file) {
  $code = @file ($file) 
    or die ("Unable to open file ($file)");

  print "<div class=code>\n<table id=listing cellspacing=0 cellpadding=2 border=0>\n";

  $line_number = 1;

  foreach ($code as $line_of_code) {
    print "<tr>\n  <td align=right id=line-number><a name=line_$line_number></a>" . 
          $line_number++ . "</td>\n";
    print "  <td id=code><tt>\n";
    for ($i = 0; $i < strlen ($line_of_code); $i++) {
      if ($line_of_code [$i] == " ") {
	echo "&nbsp;";
      } else if ($line_of_code [$i] == "\t") {
	echo "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
      } else if ($line_of_code [$i] != "\n") {
	echo $line_of_code [$i];
      } // if
    } // foreach 
    print "</tt></td>\n</tr>\n";
  } // foreach

  print "</table>\n</div>";
} // display_code
?>
