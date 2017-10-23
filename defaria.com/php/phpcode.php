<?php
////////////////////////////////////////////////////////////////////////////////
// 
// phpcode: Displays or returns an HTML'ized version of a php file
//
////////////////////////////////////////////////////////////////////////////////
function phpcode ($file, $funclink = true, $return = false) {
  $data = @highlight_file ($file, true)
    or die ("Unable to open file $file");

  // Init
  $data = explode ('<br />', $data);
  $start = '<span style="color: #aaa;">';
  $end   = '</span>';
  $i = 1;
  $text = '';
 
  // Loop
  foreach ($data as $line) {
    $nbr = $i;
    if ($i < 10000) {
      $nbr = "&nbsp;$i";
    } elseif ($i < 1000) {
      $nbr = "&nbsp;&nbsp;$i";
    } elseif ($i < 100) {
      $nbr = "&nbsp;&nbsp;&nbsp;$i";
    } elseif ($i < 10) {
      $nbr = "&nbsp;&nbsp;&nbsp;&nbsp;$i";
    } // if      
    $text .= sprintf("%s %s:%s %s<br>\n",
		     $start, $nbr, $end, str_replace("\n", '', $line));
    ++$i;
  } // foreach

  // replace <code><span>... with <pre><span>... to justify numbers
  $html_col = ini_get('highlight.html');
  $text = preg_replace("/(<code><span style=\"color: $html_col\">)?/",
		       "", $text);
  $text = preg_replace("/(<\/span><\/code>)?/",
		       "", $text);
  $text = "<font family=fixed><span style=\"color: $html_col\">".$text."</span></font>"; 

  // Wrap with div class=code
  $text = '<div class="code">' . $text . '</div>';
  // Optional function linking
  if ($funclink === true) {
    $keyword_col = ini_get('highlight.keyword');
    $manual = 'http://www.php.net/function.';
    $text = preg_replace(
      // Match a highlighted keyword
      '~([\w_]+)(\s*</font>)'.
      // Followed by a bracket
      '(\s*<font\s+color="' . $keyword_col . '">\s*\()~m',
      // Replace with a link to the manual
      '<a href="' . $manual . '$1">$1</a>$2$3', $text); 
  } // if
    
  // Return mode
  if ($return === false) {
    echo $text;
  } else {
    return $text;
  } // if
} // phpcode
?>