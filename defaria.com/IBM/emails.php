<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Letter.css">
  <script src="randomize.js" type="text/javascript"></script>
  <title>IBM Correspondence</title>
<?php
function logAccess () {
  $timestamp = date ('Y-m-d H:i:s');
  $line = <<<END
Somebody tried to access $_SERVER[REQUEST_URI] on $timestamp

IP Address: $_SERVER[REMOTE_ADDR]
Host:       $_SERVER[REMOTE_HOST]
URL:        $_SERVER[REQUEST_URI]

END;

  $access = fopen ("access.log", "a");

  fwrite ($access, $line);

  fclose ($access);

  return $line;
} // logAccess

function SendNotification () {
  $domain  = "DeFaria.com";
  $to      = "Andrew@DeFaria.com";
  $subject = "Somebody's probing $_SERVER[REQUEST_URI] page";
  $message = logAccess ();

  $extra_headers .= "From: Andrew DeFaria <Andrew@DeFaria.com>\n";

  if (mail ($to, $subject, $message, $extra_headers)) {
    print "
<p>The following information has been logged:</p>

<pre>
$message
</pre>
";
  } // if
} // SendNotification
?>
  <?php include "site-functions.php"?>
<style>
blockquote[type=cite] {
  margin:       0em 0em 0em 0em         !important;
  padding:	0em .5em .5em .5em	!important;
  border-right:	2px  solid blue		!important;
  border-left:	2px solid blue		!important;
}
blockquote[type=cite]
blockquote[type=cite] {
  border-right:	2px solid maroon	!important;
  border-left:	2px solid maroon	!important;
}
blockquote[type=cite]
blockquote[type=cite]
blockquote[type=cite] {
  border-right:	2px solid teal		!important;
  border-left:	2px solid teal		!important;
}
blockquote[type=cite]
blockquote[type=cite]
blockquote[type=cite]
blockquote[type=cite] {
  border-right:	2px solid purple	!important;
  border-left:	2px solid purple	!important;
}
blockquote[type=cite]
blockquote[type=cite]
blockquote[type=cite]
blockquote[type=cite]
blockquote[type=cite] {
  border-right:	2px solid green		!important;
  border-left:	2px solid green		!important;
}
</style>
</head>

<body>

<p>Here are the emails exchanged where IBM, or specifically Naomi
Guerrero, and her boss Ralph Bosco attempt to bully me into abandoning
my free speech rights:</p>

<hr>

<p>Good Morning Andrew,</p>

<p>Please <script>r(remove)</script> my name from your blog site <script>r(immediately)</script>. I <script>r(respect)</script>
your opinion about support, you are obviously <script>r(entitled)</script>. However, I
should not be publicly chastised for re-stating IBM guidelines and
rules that are set forth by my management. Your case was <script>r(escalated)</script> and
I merely stated to you the response from my escalation/development
team.</p>

<p>Again, please <script>r(remove)</script> my name.</p>

<p>http://defaria.com/blogs/Status/archives/cat_broadcom.html</p>

<p>thank you and have a great day!</p>

<p>Naomi Guerrero<br>
IBM Rational Support Engineer<br>
Direct:520-638-5494<br>
Email: naomimg@us.ibm.com</p>

<p>We value your feedback -- <script>r(satisfied)</script> customers are my top
priority. If at any time you would like to provide feedback about the
quality of service, please contact my manager,Ralph Bosco at
Ralph_Bosco@us.ibm.com."</p>

<hr>

<p>And here was my response:</p>

<hr>

<blockquote type="cite">

<p>Good Morning Andrew,</p>

<p>Please <script>r(remove)</script> my name from your blog site <script>r(immediately)</script>. I <script>r(respect)</script>
your opinion about support, you are obviously <script>r(entitled)</script>. However, I
should not be publicly chastised for re-stating IBM guidelines and
rules that are set forth by my management. Your case was <script>r(escalated)</script> and
I merely stated to you the response from my escalation/development
team.</p>

<p>Again, please <script>r(remove)</script> my name.</p>

<p>http://defaria.com/blogs/Status/archives/cat_broadcom.html</p>
</blockquote>

<p>Rummaging around on my site eh?</p>

<p>I don't think I chastised you <script>r(personally)</script> at all - I was talking
about support organizations in general and IBM in this specific
case. I don't believe that anybody would read my posting and think
anything other than you were not speaking <script>r(personally)</script> but rather you
were speaking for IBM. I'm a firm believer in the first amendment and
for giving credit and blame when it's due. My web site is a place
where I state my personal opinions. You should believe what you say
and stand behind your words - I do.</p>

<p>If you want to add your own statement to that posting then let me
know and I'll add it.</p>

<p>-- <br>
Andrew DeFaria</p>

<hr>

<p>So now this bitch sicks her boss on me:</p>

<hr>

<p>Hi Andrew,</p>

<p>While I certainly <script>r(respect)</script> your first amendment rights, I believe you
can maintain the <script>r(accuracy)</script> and intent of your post without including
Naomi's name.  Besides the fact that she's obviously <script>r(uncomfortable)</script>
having her name on a public forum, there are other <script>r(issues)</script> to <script>r(consider)</script>
from the business side.</p>

<p>As you've already stated, she was not speaking <script>r(personally)</script> but on
behalf of IBM policy, and that is where the credit should remain.</p>

<p>Please <script>r(remove)</script> her name from your blog <script>r(immediately)</script>.  You can easily
replace it with the more generic "IBM/Rational Technical Support
Engineer" without <script>r(compromising)</script> your message and actually make it more
accurate, as IBM is standing behind her words.</p>

<p>I trust I can <script>r(consider)</script> this matter closed.</p>

<p>Thanks,<br>
Ralph Bosco<br>
Support Delivery Manager - ClearQuest, Rational Client Support<br>
IBM Software, Rational<br>
(978) 899-3657 (office) T/L 276-3657<br>
ralph_bosco@us.ibm.com</p>

<blockquote type="cite">
<p>---- Forwarded by Ralph Bosco/Cambridge/IBM on 02/15/2013 09:17 AM -----</p>

<p>From: Andrew DeFaria &lt;Andrew@defaria.com&gt;<br>
To: Naomi Guerrero/Lexington/IBM@IBMUS,<br>
Date: 02/14/2013 11:03 AM<br>
Subject: Please <script>r(remove)</script> my name from your blog</p>

<blockquote type="cite">

<p>Good Morning Andrew,</p>

<p>Please <script>r(remove)</script> my name from your blog site <script>r(immediately)</script>. I <script>r(respect)</script>
your opinion about support, you are obviously <script>r(entitled)</script>. However, I
should not be publicly chastised for re-stating IBM guidelines and
rules that are set forth by my management. Your case was <script>r(escalated)</script> and
I merely stated to you the response from my escalation/development
team.</p>

<p>Again, please <script>r(remove)</script> my name.</p>

<p>http://defaria.com/blogs/Status/archives/cat_broadcom.html</p>

</blockquote>

<p>Rummaging around on my site eh?</p>

<p>I don't think I chastised you <script>r(personally)</script> at all - I was talking
about support organizations in general and IBM in this specific
case. I don't believe that anybody would read my posting and think
anything other than you were not speaking <script>r(personally)</script> but rather you
were speaking for IBM. I'm a firm believer in the first amendment and
for giving credit and blame when it's due. My web site is a place
where I state my personal opinions. You should believe what you say
and stand behind your words - I do.</p>

<p>If you want to add your own statement to that posting then let me
know and I'll add it.</p>

<p>-- <br>
Andrew DeFaria</p>
</blockquote>

<hr>

<p>I didn't have the heart to tell Bosco man that in my mind this
matter was over before it started so I wrote him this:</p>

<hr>

On 02/15/2013 07:15 AM, ralph_bosco@us.ibm.com wrote:

<blockquote type="cite">

<p>Hi Andrew,</p>

<p>While I certainly <script>r(respect)</script> your first amendment rights, I believe
you can maintain the <script>r(accuracy)</script> and intent of your post without
including Naomi's name.  Besides the fact that she's obviously
<script>r(uncomfortable)</script> having her name on a public forum, there are other
<script>r(issues)</script> to <script>r(consider)</script> from the business side.</p>
</blockquote>

<p>Such as? I'm curious...</p>

<p>This is my personal web site and is unrelated to my business,
ClearSCM, Inc. (http://clearscm.com).</p>

<p>-- <br>
Andrew DeFaria</p>

<hr>

<p>Now Buttco man tries to come up with a plausible issue to <script>r(consider)</script>
from the business side but falls miserably:</p>

<hr>

<p>Well, for one I can think of right off the bat, it gives anyone who
is searching for <script>r(solutions)</script> to CQ <script>r(issues)</script> access <script>r(directly)</script> to Naomi,
which could <script>r(negatively)</script> impact her ability to support <script>r(entitled)</script>
customers such as yourself.</p>

<p>The point is moot.  She obviously is <script>r(uncomfortable)</script> having her name
in a public blog, and with a very simple change, that can be
remediated.</p>

<p>Thanks,<br>
Ralph Bosco<br>
Support Delivery Manager - ClearQuest, Rational Client Support<br>
IBM Software, Rational<br>
(978) 899-3657 (office) T/L 276-3657<br>
ralph_bosco@us.ibm.com</p>

<hr>

<p>Undeterred, I quickly put him in place and they then conspire to
have my contract terminated. Nice move there IBM. Fuck you!</p>

<hr>

On 02/15/2013 07:31 AM, ralph_bosco@us.ibm.com wrote:

<blockquote type="cite">

<p>Well, for one I can think of right off the bat, it gives anyone who
is searching for <script>r(solutions)</script> to CQ <script>r(issues)</script> access <script>r(directly)</script> to Naomi,
which could <script>r(negatively)</script> impact her ability to support <script>r(entitled)</script>
customers such as yourself.</p>

</blockquote>

<p>How exactly does one get direct access to somebody from just having
a name? Seriously, they'd have to call up and you guys are pretty
strict about having "rights" to call IBM support. You don't take
support calls from just anybody. And how does that <script>r(negatively)</script> impact
her ability to provide support? Sorry, I don't buy it...</p>

<blockquote type="cite">

<p>The point is moot.  She obviously is <script>r(uncomfortable)</script> having her name
in a public blog, and with a very simple change, that can be
remediated.</p>

<p>I've heard that she's <script>r(uncomfortable)</script> - you've said it twice now. I'm
sorry she is. I don't believe she should be. Her comfort is not my
duty.</p>

<p>-- <br>
Andrew DeFaria</p>

<hr>

<font color="#999">Note the above emails have been slightly modified. To see what has been modified click <a href="emails.php?debug">here</a>.

<?php copyright ();?>
<?php SendNotification ();?>

</body>
</html>
