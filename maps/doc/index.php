<?php 
include "site-functions.php";
include "MAPS.php"
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head>
  <title>MAPS: Help</title>
  <?php MAPSHeader ()?>
</head>
<body>

<div class="heading">
  <h2 class="header" align="center">
  <font class="standout">MAPS</font> Spam Elimination System!</h2>
</div>

<div class="content">
  <?php 
  OpenDB ();
  SetContext ($userid);
  NavigationBar ($userid);
  ?>

  <h3>What is MAPS?</h3>

  <p>MAPS - which the observant might notice is SPAM spelt backwards -
  works on a simple principal that is commonly used with Instant
  Messenger (IM) clients such as AOL's Instant Messenger or
  Microsoft's Messenger. That is that with most IM clients you need to
  get the permission of the person you want to message before you can
  send them an instant message. MAPS considers all email spam and
  returns it to the sender unless the email is from somebody on your
  white list.</p>

  <p>Now white lists are not new but maintaining a white list is a
  bother. So MAPS automates the maintaining of the that white list by
  putting the responsibility of maintaining it on the people who wish
  to email you. MAPS also seeks to make it easy for real people, not
  spammers, to request permission to email you. Here's how it
  works....</p>

  <p>Email that is delivered to you is passed through a filter (maps
  filter) which processes your email like so:</p>

  <ol>

    <li>Extract senders email address - no sender address (and no
    envelope address)? Discard the email</li>

    <li>Check to see if the sender is on your null list - if so
    discard the email</li>

    <li>Check to see if the sender is on your black list - if so
    return a message telling the sender that s/he is blocked from
    emailing you.</li>

    <li>Check to see if the sender is on your white list - if so
    deliver the mail</li>

    <li>Otherwise send the sender a message with a link for them to
    quickly register. Also, save their email so it can be delivered
    when they register</li>

  </ol>

  <p>As you can see this algorithm will greatly reduce your
  spam. Also, it's easy for real people to register. Spammers
  typically do not read any email returning to them so they never
  register!</p>

  <h3>Other topics</h3>

  <ul>

  <li><a href="Requirements.php">Requirements</a></li>

  <li><a href="/maps/SignupForm.html">Signup for MAPS</a></li>
  
  <li><a href="Using.php">Using MAPS</a></li>

  </ul>  

  <?php copyright (2001);?>

  </div>
</body>
</html>
