<?php
$baseDir = getcwd();
$songs   = glob ($baseDir . "/Songs/*.pro");

function songsDropdown () {
  global $songs;

  print "<form method=\"post\" action=\"webchord.cgi\" name=\"song\">";
  print "Songs:&nbsp;&nbsp;";
  print "<select name=\"chordpro\">";

  sort ($songs);
  foreach ($songs as $song) {
    $title = basename ($song, ".pro");
    $artist = getArtist ($song);

    if ($artist != "") {
      $title .= "&nbsp;($artist)";
    } // if

    print "<option value=\"$song\">$title</option>";
  } // foreach

  print "<input type=\"submit\" value=\"Go\">";
  print "</select>";
  print "</form>";
} // songsDropdown

function artistsDropdown () {
  global $songs;

  $artists = getArtists ($songs);

  print "<form method=\"post\" action=\"displayartist.php\" name=\"artist\">";
  print "Artists:&nbsp;&nbsp;";
  print "<select name=\"artist\">";

  sort ($artists);
  foreach ($artists as $artist) {
    print "<option>$artist</option>";
  } // foreach

  print "<input type=\"submit\" value=\"Go\">";
  print "</select>";
  print "</form>";
} // artistsDropdown

function getArtist ($song) {
  $lyrics = file_get_contents ($song);

  if (preg_match ("/\{(st|subtitle):(.*)\}/", $lyrics, $matches)) {
    return trim ($matches[2]);
  } else {
    return "";
  } // if
} // getArtist

function getArtists ($songs) {
  $artists = array();

  foreach ($songs as $song) {
    $artist = getArtist ($song);

    if ($artist != '') {
      $artists[$artist] = 1;
    } // if
  } // foreach

  return array_keys ($artists);
} // getArtists

function formatTable ($songs) {
  echo "<ol>";

  foreach ($songs as $song) {
    $artist = getArtist ($song);

    $title = basename ($song, ".pro");

    echo "<li><a href=\"webchord.cgi?chordpro=$song\">$title</a>";

    if ($artist != "") {
    echo "&nbsp;($artist)";
    } // if
  } // foreach

  echo "</ol>";
} // formatTable
