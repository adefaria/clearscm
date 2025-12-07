<?php
  // Obtain an image only if we are here on this server....

$img_name = isset ($_GET ["img"]) ? $_GET ["img"] : "";
$img_path = "/web/Pictures";
$server   = $_SERVER ["SERVER_NAME"];

function GetImage ($img_name) {
  global $server;
  global $img_path;

  if (isset ($img_name)) {
    $fp = @fopen ("$img_path/$img_name", "r");

    if ($fp) {
      header ("Content-Type: image/jpeg\nContent-Transfer-Encoding: binary");
      fpassthru ($fp);
    } else {
      header ("Content-Type: text/html\n");
      print "<font color=\"red\"<b>Error:</b></font> Unable to find image $img_name<br>";
    } // if
  } // if
} // GetImage

if (isset ($_POST ["magic"])) {
  print "It's magic!" . $_POST ["magic"];
  return;
}

if ($server == "defaria.com") {
  GetImage ($img_name);
} else {
  header ("Content-Type: text/html\n");
  print "<font color=\"red\"<b>Error:</b></font> You don't have authorization to link to this image";
} // if
?>