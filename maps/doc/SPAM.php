<?php
include "site-functions.php";
include "MAPS.php"
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US">
<head>
  <title>MAPS: What is SPAM?</title>
  <?php MAPSHeader ()?>
</head>
<body>

<div class="heading">
  <h2 class="header" align="center">What is SPAM?</h2>
</div>

<div class="content">
  <?php
  OpenDB ();
  SetContext ($userid);
  NavigationBar ($userid);
  ?>

  <h3>What is SPAM?</h3>

  <p>SPAM, also known as unsolicited email, has many definitions to
  many people. Some people consider it only unsolicited commerical
  email - the kind of email that is trying to sell you
  something. Others consider it any email that you did not wish to
  see. MAPS does not really attempt to define SPAM rather it simply
  classifies email as either permitted or not. Initially all email is
  considered not permitted. It is only when others register for
  permission to email you that MAPS considers email as <i>wanted</i>.</p>

  <p>Initially all email will be returned to the sender with a message
  that describes how to register for permission to email you. Returned
  email is saved for up to 30 days (configurable) so that if the
  sender decides to register their previous email(s) will be
  delivered. If they register then all previous emails will be
  delivered and they will be added to your white list. Future emails
  from them will be delivered instead of returned.</p>

  <p>Typically spammers are really robots or scripts that send
  thousands or millions of emails to address lists. They don't read
  returned messages so they will not register for permission to email
  you. Occasionally a spammer, usually a small operation, will read
  the returned message and may register. If this happens then you can
  easily <i>blacklist</i> that spammer and not be bothered by them
  again. As a MAPS user myself who receives probably more SPAM than
  you will ever see I can say that perhaps one to two real spammers
  will register every other month. So you can easily deal with such
  annoyances.</p>

  <p>Because spammers often use invalid email addresses or email
  address that quickly fill up with "Please don't bother me" return
  messages, often a MAPS register message will be returned by a
  <i>mailer daemon</i> telling you that the spammer's email address
  doesn't exist or is full. You don't want to be bothered with such
  return messages so MAPS seeds your <i>null list</i> with entries to
  prevent this. If you receive emails from such mailer daemons and do
  not wish to receive them simply null list them. The <i>null list</i>
  is also good for other annoying email that you receive that you'd
  rather not be bothered with. For example, you might receive a
  newsletter sort of email from a company you normally wish to deal
  with but are not really interested in their newsletters. Perhaps the
  newsletters are send from an address of
  <i>newsletters@&lt;company I care about&gt;.com</i> where
  other email might come from <i>support@&lt;company I care
  about&gt;.com</i>. In that case you can safely null list
  <i>newsletters@&lt;company I care about&gt;.com</i>. For
  exmaple, I null list <i>discship@netflix.com</i> because I
  do not wish to receive those information emails from <a
  href="http://netflix.com">Netflix.com</a> about shipments.</p>

  <p>Your <i>black list</i> is similar to your <i>null list</i> except
  instead of merely discarding the email, a return message is sent to
  the sender saying that they are blacklisted. This is good for people
  who you wish to make sure know that you are consciously ignoring
  them.</p>

  <?php copyright (2001);?>

  </div>
</body>
</html>
