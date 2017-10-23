<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Letter.css">
  <title>IBM</title>
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

<h1>The IBM Issue</h1>

<p>I run a personal web site, <a href="defaria.com">defaria.com</a>
that is located in my apartment and have been running that site since
around 1998. I do it to keep my Unix/Linux system administration
skills sharp, to learn web technologoies, develop applictions, provide
myself with my own "cloud storage" and to serve as my home on the
web.</p>

<p>On my site I run several blogs of a personal nature. One blog, my
status blog, started out as a way for me to simply make bullet items
to copy and paste into what most managers settle for as status
reporting - just a bulleted list of what I had been doing lately. Then
I started using the extended section to put in the technical details
of the problems I had been facing and how I solve them. This turned
out to be a valuable resource for me as I could now easily search the
status blog to see if I encountered a problem like this before and how
did I solve it.</p>

<p>But as time went by more of my clients stopped requiring weekly or
monthly status reports and I have written articles in the status blog
that were of simply opinionated commentary. For example, Outlook Top
Posting was an opinion piece about how Outlook messes up quoting.</p>

<p>On February 4, 2013 I posted an opinioon piece on my blog entitled
"File this one under Paid Support vs Open Source". The piece's theme
is about how I'm seeing a trend towards Open Source Software (OSS) and
people claiming that OSS is often supported better than closed
source's paid support. I used a recent conversation with IBM support,
which is paid support and which is expensive.  I even said that often
IBM support is excellent. Also note I never mentioned my client's
name:</p>

<blockquote>
  <h2>February 04, 2013</h2>

  <h3>File this one under Paid Support vs Open Source</h3>

  <p>I use both proprietary software as well as open source
  software. One would think that when you pay for your software and
  pay a lot for support, then obviously you must be in a better
  situation should something not work correctly. But my experience has
  been the opposite. Not always but often. I can only attribute this
  to the fact that when dealing with OSS you often are talking
  directly with the developer who has pride in his work and wants it
  to work correctly. He is bothered when people report problems in his
  software and motivated to try and fix it.</p>

  <p>On the other hand we've all had our "experiences" with so called
  front line support people who sometimes barely know how the software
  they support operates or even how to spell its name correctly, who
  ask their customers to reboot their Linux server that's been up for
  the last 3 years to see if that will "help".</p>

  <p>IBM/Rational Support is far from that bad - often they are
  excellent. But it does seem that sometimes when the problem is a
  little thorny they will punt and say this is "outside of scope" -
  whatever that means.</p>

  <p>I must admit my process is slightly complicated - a CQPerl script
  which serves as a multiprocess server which forks off a copy of
  itself to handle request to process Clearquest data. For anybody who
  has written such server processes they can be tricky at first to
  program and get right, but soon turn into just another programming
  task like any other.</p>

  <p>The problem arises in an odd way in which a request comes in to
  add a record. BuildEntity is called and the record is successfully
  added. But when a second process later attempts to do a similar
  thing - add a record - the BuildEntity fails stating:</p>

  <blockquote>
    <p>Status: 1 unknown exception from CQSession_BuildEntity in
    CQPerlExt at cqserver.pl line 31.</p>
  </blockquote>

  <p>The support engineer eventually responded with:</p>

  <blockquote>
    <p>On 1/25/2013 10:40 AM, Naomi Guerrero wrote:</p>

    <p>Hi Andrew,</p>

    <p>I'm following up on escalated PMR#16866,227,000. After escalating
    this PMR to L3 support, and Development having discussions about
    this issue, this request goes outside the scope of support. This
    is not something we can assist you with in support. Instead, I
    would recommend you reach out to your Sales agent at IBM (or I
    can) so that someone from the Rational Services team can further
    assist you.</p>
  </blockquote>

  <p>To which I responded:</p>

  <blockquote>
    <p>On 1/25/2013 11:00 AM, Andrew DeFaria wrote:</p>

    <p>How can you possibly say that this goes outside the scope of
    support?!? We have a situation here where your software returns
    the words "unknown exception", fails to do what it's advertised to
    do (Build and entity) and even stops my script from continuing!
    This is clearly an error in IBM's software. I have a reproducible
    test case (you'll need our schema, which I supplied). There's is
    nothing in my code that is outside of a supported situation - I'm
    using regular CQPerl stuff and every call is supported. It's on
    supported hardware, with supported versions of OS, Clearquest,
    CQPerl, etc. Why BuildEntity returning "unknown exception"? Surely
    this is in the code for BuildEntity. Somebody should examine it
    and report back! This is clearly an error and I fail to see how it
    goes outside of the scope of support at all. If the problem is
    difficult to solve that does not put it into the realm of "outside
    of support".</p>

    <p>My client pays IBM big $$$ for support every year if I remember
    how IBM support contracts go. We want our money's worth. While I
    fail to see how a "Sales" agent will be able to assist (I
    personally think a knowledgable software developer like the guy
    who's responsible for the BuildEntity code - you do have somebody
    like that no? - should look into the code and see exactly what
    circumstances causes BuildEntity to emit such an error) if that's
    the next step then by all means take it and reach out to whoever
    is next in line to assist. But from where I sit this is indeed a
    bug and is not outside the scope of support. If you believe it is
    then please explain yourself. Why is this "outside the scope of
    support"?</p>
  </blockquote>

  <p>Now granted it appears that this happens only with out schema
  (Works fine with the SAMPL database) but that seems to point to
  either a problem somewhere with action hook code being executed
  (which would also be deemed a bug as action hook code should never
  cause unknown exceptions to happen or it could be caused by some
  corruption in my client's database - something that should be
  pursued - not dropped to "Sales"!</p>

  <p>Problem report 16866,227 000: unknown exception from
  CQSession_BuildEntity</p>
</blockquote>

<p>Later I got an email from Naomi:</p>

  <blockquote>
    <p>On 02/14/2013 06:06 AM Naomi Guerrero wrote:</p>

    <p>Please remove my name from your blog site immediately. I
    respect your opinion about support, you are obviously
    entitled. However, I should not be publicly chastised for
    re-stating IBM guidelines and rules that are set forth by my
    management. Your case was escalated and I merely stated to you the
    response from my escalation/development team.</p>

    <p>Again, please remove my name.</p>

    <p>http://defaria.com/blogs/Status/archives/cat_broadcom.html</p>
  </blockquote>

<p>I responded with:</p>

  <blockquote>
    <p>On 02/14/2013 08:01 AM Andrew DeFaria wrote:</p>

    <p>Rummaging around on my site eh?</p>

    <p>I don't think I chastised you personally at all - I was talking
    about support organizations in general and IBM in this specific
    case. I don't believe that anybody would read my posting and think
    anything other than you were not speaking personally but rather
    you were speaking for IBM. I'm a firm believer in the first
    amendment and for giving credit and blame when it's due. My web
    site is a place where I state my personal opinions. You should
    believe what you say and stand behind your words - I do.</p>

    <p>If you want to add your own statement to that posting then let
    me know and I'll add it.</p>
  </blockquote>

<p>As you can see I was firm in saying that this was my personal web
site. I also offerred to the chance include her own statement,
something I don't have to do.</p>

<p>So Naomi got her boss to essentially harass me:</p>

  <blockquote>
    <p>On 02/15/2013 07:15 AM Ralph Bosco wrote:</p>

    <p>Hi Andrew,</p>

    <p>While I certainly respect your first amendment rights, I
    believe you can maintain the accuracy and intent of your post
    without including Naomi's name.  Besides the fact that she's
    obviously uncomfortable having her name on a public forum, there
    are other issues to consider from the business side.</p>

    <p>As you've already stated, she was not speaking personally but
    on behalf of IBM policy, and that is where the credit should
    remain.</p>

    <p>Please remove her name from your blog immediately.  You can
    easily replace it with the more generic "IBM/Rational Technical
    Support Engineer" without compromising your message and actually
    make it more accurate, as IBM is standing behind her words.</p>

    <p>I trust I can consider this matter closed.</p>

    <p>Thanks,<br>
    Ralph Bosco<br>
    Support Delivery Manager - ClearQuest, Rational Client Support<br>
    IBM Software, Rational</p>
  </blockquote>

<p>So I responded:</p>

  <blockquote type="cite">
    <p>On 02/15/2013 07:23 AM Andrew DeFaria wrote:</p>

    <blockquote type="cite">
      <p>Besides the fact that she's obviously uncomfortable having
      her name on a public forum, there are other issues to consider
      from the business side.</p>
    </blockquote>

    <p>Such as? I'm Curious...</p>

    <p>This is my personal web site and is unrelated to my business,
    ClearSCM, Inc. (http://clearscm.com).</p>
  </blockquote>

<p>Again I mention this is my personal web site and demonstrate that
my business site is at http://clearscm.com which is not in my
apartment but at an ISP. So now Mr. Bosco has to justify his
statement:</p>

  <blockquote>
    <p>On 02/15/2013 07:31 AM Ralph Bosco wrote:</p>

    <p>Well, for one I can think of right off the bat, it gives anyone
    who is searching for solutions to CQ issues access directly to
    Naomi, which could negatively impact her ability to support
    entitled customers such as yourself.</p>

    <p>The point is moot.  She obviously is uncomfortable having her
    name in a public blog, and with a very simple change, that can be
    remediated.</p>
  </blockquote>

<p>My response:</p>

  <blockquote>
    <p>On 02/15/2013 07:39 AM Andrew DeFaria wrote:</p>

    <p>How exactly does one get direct access to somebody from just
    having a name? Seriously, they'd have to call up and you guys are
    pretty strict about having "rights" to call IBM support. You don't
    take support calls from just anybody. And how does that negatively
    impact her ability to provide support? Sorry, I don't buy
    it...</p>

    <p>I've heard that she's uncomfortable - you've said it twice
    now. I'm sorry she is. I don't believe she should be. Her comfort
    is not my duty.</p>
  </blockquote>

<p>Additionally on 02/15/2013 @ 09:36 AM I created an .htaccess file
that secures this section of my personal web site to only users who
have a username and password and the only user is mine.</p>

<blockquote>
  <pre>
    <b><font color="blue">Defaria:</font></b><u>ll /web/blogs/Status/.htaccess</u><br>
    -r-xr--r-- 1 andrew users 99 Feb 15 09:36 .htaccess<br>
  </pre>
</blockquote>

<p>So while I did not tell IBM that I complied, I did comply, within a
few hours.</p>

<h3>Broadcom and HR involvement</h3>

<p>On 03/13/2013 I received a meeting invitation from Sue Johnson, an
HR rep from Broadcom and Mohammed Ansari about a "Possible Social
Media Issue":</p>

<table>
  <tr>
    <th colspan="2">Sue (Susan) Johnson has invited you to Possible Social Media Issue</th>
  </tr>

  <tr>
    <th>Title:</th>
    <td>Possible Social Media Issue</td>
  </tr>

  <tr>
    <th>Location:</th>
    <td>Sue's Office D3040</td>
  </tr>

  <tr>
    <th>When:</th>
    <td>Wed 13 Mar 2013 02:30 PM – 03:00 PM</td>
  </tr>

  <tr>
    <th>Organizer:</th>
    <td>Sue (Susan) Johnson &lt;sue.johnson@broadcom.com&gt;</td>
  </tr>

  <tr>
    <th>Description:</th>
    <td>Hi Andrew: It has been brought to my attention that you may be
    violating BRCM’s social media policy. I am scheduling this meeting
    to gather additional information.</td>
  </tr>

  <tr>
    <th>Attendees:</th>
    <td>Mohammed Ansari &lt;mohammed.ansari@broadcom.com&gt;<br>
        Andrew Defaria &lt;adefaria@broadcom.com&gt;</td>
  </tr>
</table>

<p>During this meeting Sue told me that IBM had complained to upper
management about the issue described above and that I should remove
the name at once. I told her I already secured the site with a
password and again re-itterated that this is my personal site and is
not affliated with either Broadcom nor ClearSCM. I also said that I
don't agree with either Broadcom nor IBM with respect to the privacy
aspect of this issue and you'll note that the word "Broadcom" never
appeared in my status blog in the first place. I did say, however,
that I will do what Broadcom wishes and in fact I have already done
it.</p>

<p>Sue sent the following follow-up:</p>

<blockquote>
  <p>On 03/13/2013 04:12 PM Sue (Susan) Johnson wrote:</p>

  <p>Per our discussion today, this is a summary of our expectations
  regarding closure on the feedback received from the IBM Rational
  Support Delivery group:</p>

  <ul>
    <li>You have confirmed that the name of the IBM employee
    referenced in the blog posting is no longer visible to the public
    and will ensure that it does not become available to the public at
    any time in the future.</li>

    <li>In any communications posted to any public site, you must
    include a disclaimer that makes it clear that you are speaking for
    yourself and not on behalf of Broadcom, unless you have express
    consent from your manager, the Corporate Compliance Officer or
    Broadcom’s Corporate Marketing & Communications Department to
    communicate on behalf of Broadcom.</li>

    <li>You will no longer have direct communications regarding any
    BRCM related issues with IBM as long as you are employed by
    Broadcom.  Instead, you will communicate your
    questions/comments/concerns to a co-worker to be designated by
    Mohammed.  That co-worker will be the intermediary between you and
    IBM throughout the duration of your employment with Broadcom.</li>
  </ul>

  <p>Please let me know if you have questions or if you do not feel
  this accurately represents the expectations which were communicated
  and which you agreed to comply with.</p>
</blockquote>

<p>I thought bullet #2 was overly broad so I wrote Sue back:</p>

<blockquote>
  <p>On 3/13/2013 4:41 PM Andrew DeFaria wrote:</p>

  <p>I agree with all of the above however I think the second bullet
  item is too broad. One could easily take it to mean I cannot even
  post "Good morning" to Facebook without including a disclaimer for
  Broadcom. I don't think you mean that. I take the second bullet item
  to mean "in any communications on any site, if a reasonable man
  might question whether you are speaking for Broadcom then you should
  include a disclaimer or get permission". So then I would have no
  fears of posting things totally unrelated to Broadcom to Google+ or
  Facebook for example, but if I were to post to say IBM's forums I
  should not mention Broadcom at all (I usually just say "my client")
  or if I do, or if it could be reasonably be misconstrued that I'm
  speaking for Broadcom then I must either include a disclaimer or get
  permission. I think that covers it better. But as written this
  second bullet item seems to say I must include a disclaimer for
  anything and everything I post on the net.</p>
</blockquote>

<p>Sue agreed and reworded it to say:</p>

<blockquote>
  <ul>
    <li>In any communications posted to any public site that are in
    any way related to your work with or at Broadcom, you must include
    a disclaimer that makes it clear that you are speaking for
    yourself and not on behalf of Broadcom, unless you have express
    consent from your manager, the Corporate Compliance Officer or
    Broadcom’s Corporate Marketing & Communications Department to
    communicate on behalf of Broadcom.</li>
  </ul>
</blockquote>

<p>to which I promptly agreed.</p>

<h3>Seeing who's visiting my site</h3>

<p>I decided that I would move my whole status blog aside and put
together a little trap so that I could find out who's probing my
site. I configured my personal, home based web server to redirect any
requests for http://defaria.com/blogs/Status to display a page with
the following wording:</p>

<blockquote>
  <h1>You should leave - your presence is unwelcomed here</h1>

  <p>This is my personal web site. While you can look at what's inside
  you assume full responsibilty for what you see. You should leave.
  Should you decide to go forward it's your fault.</p>

  <p>You can hit the back button, close this tab or close your
  browser.</p>

  <p>You have been warned.</p>

  <p>This web page will redirect in a few seconds. Last chance to
  leave...</p>
</blockquote>

<p>The page delayed for 20 seconds before moving onward - plenty of
time for anybody to heed the warning. After the 20 seconds elapsed
another page was displayed basically telling the visitor to fuck off
with lots of colorful language and an explict image depicting what I
thought of this user (avaliable upon request). Additionally the page
logged the access and the IP address of the visitor so that I could
see if IBM was probing my site again.</p>

<p>There have been 8 accesses to my status blog since then. The first
visitor was Google's bot. Not wanting to have these recorded I used
robots.txt to tell Google's search bots not to index this section of
my site.</p>

<p>I got accesses from a couple of places in England, some mobile user
and 3 conspicuous accesses from Broadcom's proxy in Irvine.</p>

<p>Even though this tactic is bold, I still believe it falls within my
free speech rights guaranteed by the US Constitution. Additionally, I
still believe I was in compliance with Broadcom such that "the name of
the IBM employee referenced in the blog posting is not longer visible"
as it isn't.</p>

<p>Even though Broadcom claims my contract was terminated due to some
of my email signature tag lines and told me that it was <b>not</b>
terminated due to this issue, Broadcom never brought me into a meeting
to discuss this problem and waited 5 weeks to terminate the
contract. They did bring me into a meeting for the IBM issue right
around the time they terminated my contract. I don't think this is a
coincidence, rather I think that IBM pressued Broadcom to "do
something" about this "unruly contractor" and brought it up to high
levels. They told me that in the meeting - that IBM complained to
Broadcom and wanted something done (which was already done
anyway). Remember my corporation - ClearSCM Inc, of which I am an
employee, was in contract with Broadcom. IBM made no efforts to
contact ClearSCM but went straight to Braodcom.</p>

<h3>Questions</h3>

<p>I have the following questions:</p>

<ul>
  <li>Do I have anything that is actionable against IBM for lose of contract?</li>

  <li>Can I personally sue either Sue or Mr. Bosco? What right do they have to tell me what I can and connot post on my personal website? And how can they essentially use the big bully tactic to get me fired?</li>
</ul>

<?php copyright ();?>

</body>
</html>
