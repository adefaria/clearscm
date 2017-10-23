<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <meta name="GENERATOR" CONTENT="Mozilla/4.04 [en] (WinNT; U) [Netscape]">
  <title>Jokes</title>
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Default.css">
  <link rel="stylesheet" type="text/css" media="print" href="/css/Print.css">
  <link rel="SHORTCUT ICON" href="http://defaria.com/favicon.ico" type="image/png">
  <?php include "site-functions.php"?>
  <?php include "oneliner.php"?>
</head>
<body>

<div class="heading">
  <h1 class="centered">Taglines</h1>
</div>

<div id="content">
  <?php 
  navigation_bar ("yes");
  ?>

  <h2>Taglines</h2>

  <p>I like those funny one liners. You've probably seen many <i>Jokes
  lists</i> emailed from friends and family before. I collect
  them.</p>

  <p>At some point I had found a Perl script to generate a random
  funny line from a list kept in a datafile. Later I found <a
  href="http://tagzilla.mozdev.org/">Tagzilla</a> which works in
  conjunction with <a href="http://mozilla.org">Mozilla</a> (and <a
  href="http://www.mozilla.org/products/thunderbird/">Thunderbird</a>,
  which is what I use) to tack on a <i>tagline</i> to and outgoing
  email or news posting.</p>

  <p>Now I've organized my taglines in to a Tagzilla file
  format. Tagzilla also allows you to simply highlite a tagline that
  you see in email or on a web page and easily <i>steal</i> it into
  your Tagzilla file. Thus my taglines will grow over time. I also
  rewrote the Perl script to a PHP script called oneliner.php. It's
  what generates the oneliner's that you see on my site. For
  example:</p>

  <div class="box">
    <?php oneliner ("no")?>
  </div>

  <p>So when I steal a tagline it's automatically eligible to be
  selected by the PHP script and my website. A simple parameterization
  allows me to dump all my taglines here:</p>

  <?php
  oneliner ("yes");
  copyright ();
  ?>
</div>
</body>
</html>
