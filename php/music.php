<?php
$base = "/web/Music";
$http_base="/Music";

function GetAlbumArt ($path) {
  if ($handle = opendir ("$path")) {
    while (false !== ($element = readdir ($handle))) {
      if (strpos ($element, "AlbumArt") == 0 &&
	  strpos ($element, "Large")    != 0) {
	return $element;
      } // if
    } // while

    closedir ($handle);
  } // if
} // GetAlbumArt
      
function Banner ($path) {
  global $http_base;
  global $base;

  $orig_path = $path;

  print "<h2>";
  while ($component = substr ($path, 0, strpos ($path, "/"))) {
    $component_path = isset ($component_path)
      ? $component_path . "/" . $component : $component;
    print "<a href=\"$http_base/index.php?path=$component_path\">$component</a>:&nbsp;";
    $path = substr ($path, strpos ($path, "/") + 1);
  } // while
  print "$path</h2>\n";

  if ($albumart = GetAlbumArt ("$base/$orig_path")) {
    print "<img src=\"$orig_path/$albumart\">\n";
  } // if
} // Banner

function DisplayItem ($path, $element) {
  if ($element == "." || $element == "..") {
    return false;
  } elseif (is_dir ($path . "/" . $element)) {
    if ($element == "My Playlists") {
      return false;
    } else {
      return true;
    } // if
  } elseif (strpos ($element, ".wma") ||
	    strpos ($element, ".mp3")) {
    return true;
  } else {
    return false;
  } // if
} // DisplayItem
    
function DisplayFolders ($path) {
  global $http_base;
  global $base;

  Banner ($path);

  if ($path != "") {
    $path = $path . "/";
  } // if

  $folder_array	= array ();
  $song_array	= array ();

  if ($handle = opendir ("$base/$path")) {
    while (false !== ($element = readdir ($handle))) {
      if (!DisplayItem ("$base/$path", $element)) {
	continue;
      } // if
      if (is_dir ("$base/$path/$element")) {
	array_push ($folder_array, $element);
      } else {
	array_push ($song_array, $element);
      } // if

    } // while
    closedir ($handle);
  } // if

  sort ($folder_array);
  sort ($song_array);

  print "<table border=1 width=100% cellspacing=0 cellpadding=5>\n";
  print "  <tbody>\n";
  print "    <tr>\n";
  print "      <th bgcolor=blue><font color=white>Folders<font></th>\n";
  print "      <th bgcolor=blue><font color=white>Songs at this level</font></th>\n";
  print "    </tr>\n";

  $song_index	= 0;
  $folder_index	= 0;

  while (isset ($song_array   [$song_index]) ||
	 isset ($folder_array [$folder_index])) {
    $song	= $song_array	[$song_index];
    $folder	= $folder_array [$folder_index];
    print "    <tr>\n";
    if (isset ($folder)) {
      print "<td><a href=\"$http_base/index.php?path=$path" . $folder .	"\">$folder</a></td>\n";
      $folder_index++;
    } else {
      print "<td>&nbsp;</td>\n";
    } // if
    if (isset ($song)) {
      print "<td><a href=\"$http_base/$path";
      $song_name = $song;

      if (strpos ($song, ".wma") != 0) {
	$song_name = substr ($song, 0, strpos ($song, ".wma"));
      } elseif (strpos ($song, ".mp3") != 0) {
	$song_name = substr ($song, 0, strpos ($song, ".mp3"));
      } // if

      print $song . "\">$song_name</a></td>\n";
      $song_index++;
    } else {
      print "<td>&nbsp;</td>\n";
    } // if
    print "    </tr>\n";
  } // while

  print "  </tbody>\n";
  print "</table>\n";
} // DisplayFolders
?>
