<?php 
function oneliner ($list) {
  $sigs = $_SERVER["DOCUMENT_ROOT"] . "/Misc/signatures";

  srand ();

  $taglines = @file ($sigs) 
    or die ("Unable to open file ($sigs)");

  if ($list == "yes") {
    print "<ol>";
    foreach ($taglines as $tagline) {
      print "<li>" . chop ($tagline) . "</li>";
    } // while
    print "</ol>";
  } else {
    print $taglines [rand (0, sizeof ($taglines))];
  } // if
} // oneliner
?>
