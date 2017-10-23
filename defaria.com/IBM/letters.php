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

<p>The following are select "discussions" between me and IBM about
support <script>r(issues)</script> with their software. Note that this is very expensive
software and very expensive support that is paid yearly by my clients
for the purposes of resolving, not kicking down the road,
problems. The following is <i>paraphrased</i> from memory and are not
guaranteed to be 100% accurate, however one can sure think that they
might be able to form an opinion about very expensive, closed source
<script>r(solutions)</script>:</p>

<hr>
<p>On 2/22/2013 9:43 AM, Rational Client Support wrote:</p>
</div>
<blockquote type="cite">
<p>Hi Andrew,</p>

<p>So if you follow the links.. and links in the OSLC manual..</p>

<a href="http://open-services.net/bin/view/Main/CmSpecificationV2?sortcol=3Dtable;up=3D#Query_Capabilities">http://open-services.net/bin/view/Main/CmSpecificationV2?sortcol=3Dtable;up=3D#Query_Capabilities</a>

<p>Will lead you to</p>

<a href="http://open-services.net/bin/view/Main/OslcCoreSpecification#Query_Capabilities">http://open-services.net/bin/view/Main/OslcCoreSpecification#Query_Capabilities</a><br>

<p>which leads you to</p>

<a class="moz-txt-link-freetext" href="http://open-services.net/bin/view/Main/OSLCCoreSpecQuery">http://open-services.net/bin/view/Main/OSLCCoreSpecQuery</a>

<p>I believe if you look at the &quot;syntax&quot; section on the last
link that shows you what is <script>r(available)</script> in OSLC.  It looks like some of
the ones you listed might be codeable using the syntax listed.</p>

<p>Since there are no &quot;or&quot; listed in there, he said that you
can use De Morgan's lay to get to an &quot;or&quot;</p>

<a class="moz-txt-link-freetext" href="http://en.wikipedia.org/wiki/De_Morgan%27s_laws">http://en.wikipedia.org/wiki/De_Morgan%27s_laws</a>
</blockquote>
<p>I'm not looking to take a formal class in boolean algebra. AFAICT De
Morgan's law requires a <b>not</b> operator which OSLC doesn't support
from what I can tell. Otherwise I'd have a solution for
IS_NOT_NULL</p>

<p>The IN operator, for example is no substitute for the OR operator in
that IN applies only to the subject field (AKA the left hand side) and
cannot serve to join two <script>r(conditional)</script>s together as in &quot;if
first_name eq 'Andrew' and last_name eq 'DeFaria'). Even SQL does that
and it's how old?</p>

<p>I also fail to see why this matters. Users are used to regular boolean
expressions as are common in just about every programming
language. Even if cra= zy negation and a degree in math could get you
an OR operation running this= is insufficient! Users of this should be
able to to easily expression common boolean expressions and anything
short of that is unacceptable.</p>

<p.Also, the other operators I've mentioned do not seem to be
supported, that being LIKE, NOT_LIKE, BETWEEN, NOT_BETWEEN,
IS_NOT_NULL and NOT_IN.</p>

<p>The <script>r(conditional)</script> querying capabilities of REST needs to at least match those=
 of the native API or exceed it.</p>

<hr>

<div class="moz-cite-prefix">On 2/22/2013 9:26 AM, Rational Client Support wrote:<br>
</div>
<blockquote type="cite">
<p>Hi Andrew,</p>

<p>I spoke with one of our OSLC folks on the CQ <script>r(team)</script> and he said that
you have= to use SPARQL notations for your queries and OSLC only
supports a subset of comparison operators.</p>

<p>He is going to check and verify what is and isn't supported.</p>
</blockquote>

<p>Everything less than the <script>r(conditional)</script> operators specified in the
Clearquest API manual for the native cqperl <script>r(represents)</script> incomplete or
missing functionality. We are looking for functionally complete
software. If it's not complete then this PMR should remain open to
represent the missing functionality if nothing else.</p>

<blockquote type="cite">
<p>What OSLC can do however is to execute an existing CQ query 
by name or a CQ FTS search string.</p>
</blockquote>

<p>We are not looking to do this. We are looking for functionality complete software. Please <script>r(implement)</script> the missing functionality.</p>

<blockquote type="cite">
<p>I will get back with you on what he finds in regards to which operators that OSLC supports and the formatting for them.</p>

</blockquote>
<p>Anything less than all of the operators listed for the native API
is unacceptable.</p>

<hr>

<p>On 2/26/2013 6:31 AM, Rational Client Support wrote:</p>

<blockquote type="cite">
<p>Hi Andrew,</p>

<p>While I agree that it is <script>r(annoying)</script> that you cannot execute the same
query operators using OSLC that you can in regular CQ, the OSLC
guidelines are not set by CQ.  It is an open source committee that
standardizes the input and output for CM tools so that you can
interact with other tools without building <script>r(complex)</script> coding
infrastructure.  The options that are <script>r(available)</script> are set by the OSLC CM
workgroup.</p>

<p>You are free to take a look at the OSLC page and see if you can
join this workgroup or offer suggestions to them etc.</p>

</blockquote>

<p>Why don't <b>you</b> (i.e. IBM) join the group and offer these very
suggestions? Surely I'll carry a lot less weight than IBM. You could
approach it simply by saying &quot;We find our customers want the full
complement of boolean logical operators unavailable in all OSLC specs
to date and that have been in vogue for decades now&quot;... Well,
maybe not as colorfully stated, but the point is the spec isn't even
functionally complete and it's approaching 3.0! V 1.0
(<a class="moz-txt-link-freetext"
href="http://open-services.net/bin/view/Main/CmQuerySyntaxV1">http://open-services.net/bin/view/Main/CmQuerySyntaxV1</a>)
supports only the and operator, has no mention of LIKE or NULL,
thereby rendering certain boolean operations<b>impossible</b>! (AKA
broken).</p>

<p>V 2.0 (<a class="moz-txt-link-freetext"
href="http://open-services.net/bin/view/Main/OSLCCoreSpecQuery?sortcol=table;table=up#oslc_where">http://open-services.net/bin/view/Main/OSLCCoreSpecQuery?sortcol=table;table=up#oslc_where</a>)
does not remedy either of these situations. The sole boolean_op is
still AND and null is not mentioned at all.</p>

<p>Now I've synthesized the IS NULL op by abusing the IN operator as
in &quot;IN ['']&quot; however I'm not sure if that condition is true
for both true null values and empty space values. But there is no way
to do IS NOT NULL, which was one of the queries I requested assistance
with in this
PRM. And <a href="http://www.ibm.com/developerworks/forums/thread.jspa?threadID=467391&amp;tstart=15">
REST Interface, how do you formulate the query &quot;&lt;field&gt; is
not null&quot;</a> describes my attempts to get IS NOT NULL
working. Judging by the number of views (1204) it seems clear to me
that while I may be the lone spokesman here, a lot of people are
interested in this.</p>

<blockquote type="cite">
<p>The ClearQuest <script>r(team)</script> has given you the work arounds for this which
would be to have OSLC execute a CQ Query which has the operators that
you are looking for rather than having OSLC do the query itself.</p>
</blockquote>

<p>This work around is not work<b>able</b>. I do not know beforehand what queries may be made by people calling my subroutine. So unless there's an <script>r(interface)</script> for me to programmatically create CQ Queries on the fly and be able to execute and subsequently delete them there is no work around that works currently.</p>

<blockquote type="cite">

<p>Here is the link to the OSLC website which has their meeting dates
listed.</p>

<a href="http://open-services.net/workgroups/">http://open-services.net/workgroups/</a>

<p>Regards,<br>
Jami</p>

<p>I'll follow up by Thursday, February 28, 2013, should I not hear from
you sooner with an update.</p>

<p>
----------------------------------------------------<br>
Thank you for using IBM.<br>
-----------------------------------------------------<br>
Jami Mitchell<br>
Technical Support Engineer<br>
Rational software<br>
IBM Software Group<br>
</p>
</blockquote>

<hr>

<blockquote type="cite">
<p>Hi Andrew,</p>

<p>I am sorry you feel <script>r(frustrated)</script> with the options <script>r(available)</script> currently in OSLC.</p>
</blockquote>

<p>Where did you get the idea I was <script>r(frustrated)</script>? I don't necessarily
feel <script>r(frustrated)</script>, I feel the implementation is incomplete as it stands
and 2 major revisions have come out without a solution to this at
all. I feel this should be reported and the software fixed to be
functionality complete. <script>r(Personally)</script> I'd do this before 1.0. In my mind
these are all cold, facts with little to no emotion associated with
them.</p>

<p>What I really do feel <script>r(frustrated)</script> about is well paid IBM Support
neglecting to address clear bugs or limitations with their software
with &quot;call your sales rep&quot; answers. I recall a time when
such obvious bugs were simply addressed for what they are - errors
that need correction.</p>

<p>The emotion here is irrelevant so I'd appreciate if we drop that aspect.</p>

<blockquote type="cite">
<p>ClearQuest is working as <script>r(designed)</script> and I've provided you with
 the options that are <script>r(available)</script>.</p>
</blockquote>

<p>So you are admitting that Clearquest was <b><script>r(designed)</script></b> to not
 support &quot;is not null&quot;, the not operator, the or operator,
 the like operator,= etc.? That's amazing.</p>

<p>If so then <script>r(consider)</script> it an enhancement to get the REST
implementation to even par with the CQ API. I, however, will always
<script>r(consider)</script> it a bug by my definition.</p>

<blockquote type="cite">
<p>If you wish IBM to press for more operators in the OSLC
framework,then I would suggest speaking with your IBM sales rep and/or
the IBM product <script>r(management)</script> <script>r(team)</script> so you can express your concerns.</p>
</blockquote>

<p>I don't have an IBM sales rep - my client does I suspect. I don't know who 
that is. By all means, have them call me (858)-521-5691.</p>

<blockquote type="cite">
<p>
Regards,<br>
Jami</p>

<p>I'll follow up by Thursday, February 28, 2013,  should I not hear from you
sooner with an update.</p>

<p>
----------------------------------------------------<br>
Thank you for using IBM.<br>
-----------------------------------------------------<br>
Jami Mitchell<br>
Technical Support Engineer<br>
Rational software<br>
IBM Software Group</p>

<p>We value your feedback -- <script>r(satisfied)</script> customers are my top priority. If
at any time you would like to provide feedback about the quality of
service, please contact my manager, Ralph
Bosco, <a class="moz-txt-link-abbreviated"
href="mailto:ralph_bosco@us.ibm.com">ralph_bosco@us.ibm.com</a></p>

<p>Find answers on the IBM  Support Portal: <a href="http://www.ibm.com/support/">http://www.ibm.com/support/</a></p>

<p>Get social with Rational Client Support at: <a href="http://www.ibm.com/support/docview.wss?uid=swg21410649&amp;rcss=epsall">http://www.ibm.com/support/docview.wss?uid=swg21410649&amp;rcss=epsall</a></p>
</blockquote>

<hr>

<p>On 2/26/2013 12:57 PM, Rational Client Support wrote:</p>

<blockquote type="cite">
<p>Hi Andrew,</p>

<p>As I stated before OSLC doesn't belong to CQ, it is an open-source
life cycle <script>r(method)</script> that we have coded to allow interaction with
ClearQuest.  We (IBM) do not govern what options are <script>r(available)</script> in
it.</p>
</blockquote>

<p>Yes but you surely have influence - much more than I as an
individual do. Why not simply &quot;Do the Right Thing(tm)&quot; and
push for proper completeness? Or perhaps IBM could have chosen and
better implemented back end to hang their hat on. Or gosh, IBM could
write their own!</p>

<p>You know I'd be <script>r(satisfied)</script> (but not necessarily happy) if you simply
said &quot;You're right. We've submitted a bug upstream. We can't say
when or if it will be fixed&quot; but you seem unwilling to even do
that. I can't understand why. If you did then at least you have done
what you could from my viewpoint and I couldn't complain.</p>

<blockquote type="cite">
<p>If you cannot accomplish your goals with OSLC then you will have to
use the API or the clearquest client <script>r(interface)</script>.</p>
</blockquote>

<p>My goal is to provide a library to clients who cannot use the API
natively. In my case these are Linux clients who cannot install
Clearquest to talk to the database because the database uses Visual
Basic code.</p>

<p>I have been trying to attack this problem from two different angles
and have been having problems with both approaches. IBM has just be
passing off these problems as not their problem.</p>

<p>The first approach is using the REST <script>r(interface)</script> so that clients on
said Linux systems can talk to Clearquest through my library. However
the following submitted PMRs impede this:</p>

<ol>
  <li>PMR 43903,227,000: Unable to perform certain queries with
  REST </li>

  <li>PMR 44233,227,000: OSLC REST corrupts data &gt; 1 MB in
  multiline string </li>
</ol>

<p>So with the REST approach I cannot perform certain queries and run
the risk of corrupting data.</p>

<p>Another approach I have is to use a client/server model where the
server would run on Windows, thus avoiding the problem of having
Visual Basic action hook code and the clients can be Linux or Windows
clients. Those clients would not need Clearquest installed
locally. The server should fork to service clients so that it does not
block having other clients waiting for the first client to
finish. However I cannot <script>r(implement)</script> a client/server module that uses
multiprocesses because cqperl does not handle passing the open socket
to the child:</p>

<ol>
  <li>PMR 16855,227,000 CQPerl script questions </li>
</ol>

<p>which describes how one cannot pass an open socket across a
fork/exec. See
also:<a href="http://community.activestate.com/node/9501">http://community.activestate.com/node/9501</a>.</p>

<p>Due to these failures in software delivered in IBM's Clearquest
product I cannot move forward. When I report these as bugs I am told
that they are not bugs and to go talk to other organizations or talk
to my sales rep.</p>

<p>This is not support or at least certainly not worth the support
dollars that my client pays.</p>

<p>I don't think you want professionals who have been working in this
field for decades to go from client to client saying to not purchase
your products because the support often seemingly dismissive. Granted
I understand that you lean on other's code but when a bug is reported
I think it's pretty much incumbent upon you to diligently report the
problem upstream and assist on getting the upstream bug fixed. That's
what I would do.. no, strike that! That's what I do do - especially if
somebody is paying for the support. However the way support seems to
be lately I am becoming more and more convinced that perhaps my
professional opinion should shift more towards other products.</p>

<hr>

<font color="#999">Note the above emails have been slightly modified. To see what has been modified click <a href="letters.php?debug">here</a>.

<?php copyright ();?>
<?php SendNotification ();?>

</body>
</html>
