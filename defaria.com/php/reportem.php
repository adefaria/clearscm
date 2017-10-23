<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <meta name="GENERATOR" content="Mozilla/4.61 [en] (Win98; U) [Netscape]">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Plain.css">
  <title>Your violation has been reported</title>
<?php
$ip=$_SERVER ["REMOTE_ADDR"];

function GetEmails ($ip) {
  $whois_list = array (
    "",
    "whois.arin.net",
    "whois.nsiregistry.net",
    "whois.opensrs.net",
    "whois.networksolutions.com"
  );

  $email_address = array ();

  foreach ($whois_list as $whois_server) {
    $lines = "";

    if ($whois_server == "") {
      $lines = `whois $ip`;
    } else {
      $lines = `whois -h $whois_server $ip`;
    } // if

    preg_match_all ("/\s(\S+\@\S[\.\S]+)/", $lines, $matches, PREG_PATTERN_ORDER);

    foreach ($matches [1] as $match) {
      $email_address [$match] = $match;
    } // foreach

    $count = count ($email_address);
    if (count ($email_address) > 0) {
      break;
    } // if
  } // foreach

  return $email_address;
} // GetEmails

function SendViolation ($email_address) {
  global $ip;

  $domain  = "DeFaria.com";
  $contact = "Andrew@DeFaria.com";
  $subject = "Illegal attempts to break into $domain from your domain ($ip)";
  $message = "
<html>
<head>
  <title>$subject</title>
</head>
<body>
  <h3>$subject</h3>

  <p>Somebody from your domain with an IP Address of $ip has been
  attempting to break into my domain, <a
  href=\"http://$domain\">$domain</a>. Breaking into somebody else's
  computer is <font color=\"red\"><b>illegal</b></font> and <font
  color=\"red\"><b>criminal prosecution can result</b></font>. As a
  responsible ISP it is in your best interests to investigate such
  activity and to shutdown any such illegal activity as it is a
  <u>violation of law</u> and most likely a violation of your user
  level agreement. It is expected that you will investigate this and
  send the result and/or disposition of your investigation back to <a
  href=\"mailto:$contact\">$contact</a>. <font color=\"red\"><b>If you
  fail to do so then criminal prosecution may result!</b></font>
</body>
</html>
";

  // To send HTML mail, the Content-type header must be set
  $extra_headers  = "MIME-Version: 1.0\n";
  $extra_headers .= "Content-type: text/html; charset=iso-8859-1\n";

  // Additional headers
  $extra_headers .= "From: Andrew DeFaria <$contact>\n";
  $extra_headers .= "Cc: $contact\n";

  if (mail ($email_address, $subject, $message, $extra_headers)) {
    print "Sent violation report to $email_address<br>";
  } else {
    print "Error sending violation report to $email_address</br>";
  } // if
} // function
?>
</head>

<body>

<div class="heading">
  <h1 class="centered">Your violation has been reported!</h1>
</div>

<div id="content">
  <p>You have purposely and illegal probed my site to arrive at this page. As a
  result your IP address <?php echo $ip;?> has been logged and a 
  report was sent to your ISP.</p>

<?php
$email_addresses = GetEmails ($ip);

foreach ($email_addresses as $email_address) {
  SendViolation ($email_address);
} // foreach
?>

</div>

</body>
</html>
