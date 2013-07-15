<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <meta name="GENERATOR" content="Mozilla/4.61 [en] (Win98; U) [Netscape]">

  <title>ClearSCM: Environment</title>

  <link rel="stylesheet" type="text/css" media="screen" href="/css/Article.css">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Code.css">
  <link rel="stylesheet" type="text/css" media="print"  href="/css/Print.css">
  <link rel="SHORTCUT ICON" href="http://clearscm.com/favicon.ico" type="image/png">

  <!-- Google Analytics
  <script src="http://www.google-analytics.com/urchin.js" type="text/javascript">
  </script>
  <script type="text/javascript">
    _uacct = "UA-89317-1";
    urchinTracker ();
  </script>
  Google Analytics -->

  <?php
  include "php/clearscm.php";
  menu_css ();
  ?>
</head>

<body>

<?php heading ();?>

<div id="page">
  <div id="content">

<h2>Your Environment Can Make or Break You</h2>

<p>It's often no wonder that mere morals shudder at the site of a
command prompt and scream bloody murder when asked to drop into the
command line. It's a baren and unfamilar place for most people filled
with all the potential pitfalls of actually getting work done! But it
doesn't have to be that way.</p>

<p>Indeed the basic shell presented by Unix, and Windows for that
matter, is pretty bleak, harsh and forboding configured with default
settings. But shells and shell languages are wonderfully configureable
and customizable as well as extremely powerful. Often error messages
come out in command line executions that are never caught by the GUIs
and displayed. And you can often get and manipulate a lot of
information given the rich set of commands and piping techniques
afforded by most modern shells. Nevermind you can easily set up quick
loops to itterate through the information in ways that will quite
frankly dazzle your friends... well your geek friends at least.</p>

<p>All that said this document is to describe a set of start up
scripts that I've developed over the years that I find extremely
useful. The environment is easily installable yet quite sophisticated
at the same time.</p>

<blockquote><b>Note:</b> For Windows I use Cygwin as it provides a
full, Linux like environment such that most stuff runs the same on
Unix, FreeBSD, Solaris, Linux and Windows without change. There are
additional <a href="#Cygwin Tweaks">Cygwin Tweaks</a> to be described
later that make the Windows environment further normalized and make
productived.</blockquote>

<h3>The Package</h3>

<p>For quite some time now I have packaged up my stuff to reside under
~/.rc. This allows me to easily grep for the occurances of things in
one convienent place. I've even places my XEmacs customizations under
~/.rc too. All of this is in CVS on my corporate site and I keep
things up to date and documented there. You can obtain the package as
a tarball <a href="/clearenv.tar.gz">clearenv.tar.gz</a>. Unpack the
tar image and simply run ~/.rc/setup_rc:</p>

<div class="code">$ cd ~
$ tar -zxf rc.tar.gz
$ .rc/setup_rc
$
</div>

<h3>History</h3>

<p>Full version history can be viewed <a
href="http://clearscm.com/viewvc/clearscm.com/rc/">here</a>.</p>

<p>I now have separated out client customizations, i.e. startup
functionality particular to different clients or employers, into the
~/.rc/client_scripts directory. The start up scripts will source all
executable scripts under that directory.</p>

<p>A set of Clearcase functions exist under ~/.rc/clearcase and a set
of Multisite scripts under ~/.rc/multisite. By and large these serve
to set up the Clearcase environment and mostly change common Clearcase
commands from cleartool lsview to simply lsview. Where appropriate
additional functionality has been added such as lsview &lt;part of
view name&gt; which effectively does a cleartool lsview piped to grep
to find views with &lt;part of view name&gt; in their names. An lsview
by itself will do cleartool lsview piped to your $PAGER and lsviews
will generate a list of views useful in constructs such as:</p>

<div class="code">$ for view in $(lsviews); do
>   echo "Processing view $view"
>   # Do some thing with $view
> done
</div>

<p>Other functions are provided like cm (an alias for cleartool -
stands for configuration management), cdiff (do a clearcase diff),
clist (list all checkouts), etc. Note this has been named cm because
I'm starting to integrate other CM systems such as CVS. So a cdiff
does a cleartool diff if we are on a machine that has Clearcase
whereas if we are in a diretory that has a CVS directory a cvs diff
will be done instead. Similarly clist works for both CM systems
too. Further development of this is ongoing.</p>

<p>Finally there are some environment variables that are available for
handy reference such as $RGY which points to where the Clearcase
registry files are, etc.</p>

<h3>Functions</h3>

<p>Most shell functions are defined in ~/.rc/functions. Most of these
functions deal with setting it up such that the title bar of the
terminal contains an indication of whether or not you are in a view or
a cvs work area, what portion of the vob or directory you are
currently in and whether or not you are root (called Wizard). These
functions seek to maintain the proper titlebar such that if you say
ssh'ed to another machine the titlebar would change - if you exit that
ssh session the titlebar should change back.</p>

<p>Another handy function is sj - stands for Show Job. It's basically
a ps -ef | grep -i &lt;str&gr;. How many times to do you that? Why not
make it shorter? There is also user and group functions which
essentially do ypcat [passwd|group] | grep -i &lt;str&gt;. This allows
you to easily search the passwd and group NIS maps (Note I have not
implemented this for Windows yet but the thought would be to make it
function the same).</p>

<h3>bash_login</h3>

<p>This whole start up environment is oriented for the bash(1)
shell. It used to be ksh(1) but I've moved on to bash. As such the
~/.rc/base_login is where most stuff gets sourced and set up. It also
mitigates some of the differences between the various supported OSes
as well as sets up aliases, etc.</p>

<h3>set_path</h3>

<p>This script sets up the PATH from scratch. The idea was if your
PATH ever gets hosed you can get it all back with
~/.rc/set_path. There is a list of paths to places where applications
may or may not exist. These are fed into a function that appends to
the PATH variable but only if the directory actually exists. So while
you might see /usr/local/mysql/bin but not have mysql installed, the
append_to_path function will recognize that /usr/local/mysql/bin does
not exist and not append it to the path.</p>

<a name="Cygwin Tweaks"></a><h3>Cygwin Tweaks</h3>

<p>In order to help out the start up scripts I mount the Clearcase
view drive (by default M) to /view. Now /view/&lt;viewname&gt; is the
same between Unix and Cygwin. Also I mount C:\Program Files ->
/apps. Just makes more sense and is easier to type.</p>

<h2>Clearcase Functions</h2>

<h3>General function - scm = cleartool</h3>

<p>The scm function calls cleartool (and possibly cvs). It also gets
rid of the problem with Clearcase under Windows sending extra carriage
returns. If you wish to do a Clearcase cleartool command and it is not
short circuted then you can use scm instead. Short circuted commands
are basically cleartool command that you don't need to even specify scm
for. Examples include lsview, lsstream, pwv, etc.</p>

<p><b>Note:</b> The ct command has been aliased to the scm command.</p>

<p>Clearcase commands, using either the scm function of the familiar scm
function, also provide full command line completion! This means that if
you do scm lsview ad and then type tab, bash will complete your ad string
to expand to all of the views that start with the letters "ad". In other
words, bash completion for Clearcase commands means that hitting tab
in scm commands will complete the command line much like file name 
completion currently works in bash, except it's smart in that if the
context of the scm command calls for a view name here then bash 
completes view names. If the context of a scm command calls for a vob name
then completion will complete vob names, or baselines or labels, etc.
Even options are completed (type scm lsview - then tab) or even command
names themselves (type scm &lt;space&gt; then tab twice and you'll be 
given a list of all Clearcase commands!</p>

<h3>ci</h3>

<p>The ci short circut stands for check in. This will use your
~/.clearcase_profile to specify the -nc if that is your default. So
then the common action of check in goes from cleartool checkin ->
ci</p>

<h3>co</h3>

<p>Same as ci but stands for checkout.</p>

<h3>unco</h3>

<p>Undo checkout</p>

<h3>Setview</h3>

<p>This is the regular setview command for Unix. Setview is not
supported under Windows but we fake it by doing a startview then
mounting /view/&lt;viewname&gt; to /vobs and start a new bash
shell. We are attempting to emulate the setview of Unix but we can't
fully because in Unix you are chrooted and /view is what is called a
<i>super root</i>. when we exit the setview under Windows we then
umount /vobs. The problem here is that we can only have one view set
on the system because the /vobs mount point contains that view's
name. So if terminal 1 setview view1 and terminal 2 setview view2,
terminal 1 would see things as of the last mount of /vob which is
view2. Further if either terminal exists the mount is unmounted and
the other terminal now has no current working directory. This is a
known bug and... I'm working on it!</p>

<h3>startview</h3>

<p>Stgarts a view then cd's the /view/&lt;viewname&gt;</p>

<h3>endview</h3>

<p>Does cm endview</p>

<h3>killview</h3>

<p>Does endview with -server</p>

<h3>mkview</h3>

<p>Short circut of cm mkview</p>

<h3>makeview (experimental)</h3>

<p>Attempts to create or reuse a view. It takes one parameter - the
stream. The stream you say? Yes! This is UCM. It takes the stream name
and attempts create a view on that stream. First it checks to see if
that view has already been made and if so it does a setview. If not it
attempts to make the view. If it's unsuccessful it tries to do an
lsstream by first lopping off a few characters of the stream name and
searching for that hoping that the stream name you provided was
"close".</p>

<p><b>Note:</b> The view tag composed will be ${USER}_$STREAM.</p>

<h3>rmview</h3>

<p>Short circut for cm rmview</p>

<h3>lsview</h3>

<p>Lists views. If no parameters are given then it does an cm lsview
-short | $PAGER. This lists all viewnames and pages it. If you give it
one parameter then it pipes the output to grep, grepping for that
string case insensitive. If you give it more parameters it just short
circuts to cm lsview &lt;parms&gt;.</p>

<h3>myviews</h3>

<p>Lists views that have $USER in them assuming they are UCM oriented
and getting the headline of UCM activity set in the view, if any. Note
that this is a little slow to talk to UCM to get the headlines. If you
just want to see what views are yours (i.e. have your userid in their
names) then do lsview $USER.</p>

<h3>llview</h3>

<p>One of the "ll" commands. When you see ll think "list long". This
does a cm lsview -l.</p>

<h3>lsviews</h3>

<p>Easy way to get a list of all views (remember lsview by itself will
use $PAGER). Useful for loops.</p>

<h3>lsvob</h3>

<p>Short circut for cm lsvob. Functions like lsview (pages, searches, etc).

<h3>llvob</h3>

<p>Long vob listing</p>

<h3>setcs</h3>

<p>Short circut for cm setsc</p>

<h3>edcs</h3>

<p>Short circut for cm edsc</p>

<h3>catcs</h3>

<p>Short circut for cm catsc</p>

<h3>pwv</h3>

<p>Prints the current view (-short)</p>

<h3>rmtag</h3>

<p>Short circut for cm rmtag</p>

<h3>mktag</h3>

<p>Short circut for cm mktag</p>

<h3>describe</h3>

<p>Short circut for cm describe</p>

<h3>vtree</h3>

<p>Display version tree (cm lsvtree -g)</p>

<h3>merge</h3>

<p>Short circut for cm merge</p>

<h3>cdiff</h3>

<p>Performs graphical diff for Clearcase or with two non-Clearcase
files or does a cvs diff if in CVS mode.</p>

<h3>space</h3>

<p>Short circut of cm space</p>

<h3>register</h3>

<p>Short circut of cm register</p>

<h3>unregister</h3>

<p>Short circut of cm unregister</p>

<h3>hostinfo</h3>

<p>Short circut of cm hostinfo</p>

<h3>lstrig</h3>

<p>Lists the trigger type if two parms are given (trtype and pvob)
otherwise alias for cm lstype -kind trtype | $PAGER.</p>

<h3>lltrig</h3>

<p>Lists long the trigger type if two parms are given (trtype and pvob)
otherwise alias for cm lstype -long -kind trtype | $PAGER.</p>

<h3>lsbr</h3>

<p>Lists lbtype's</p>

<h3>lsstream</h3>

<p>Lists all streams to $PAGER to alias for cm lsstream if parameters
are specified.</p>

<h3>llstream</h3>

<p>Lists long all streams to $PAGER to alias for cm lsstream -lif
parameters are specified.</p>

<h3>rebase</h3>

<p>Short circut for cm rebase.</p>

<h3>deliver</h3>

<p>Short circut for cm deliver.</p>

<h3>lsbl</h3>

<p>Short circut for cm lsbl.</p>

<h3>lsproject</h3>

<p>Lists all projects to your $PAGER or alias for cm lsproject.</p>

<h3>llproject</h3>

<p>Lists long all projects to your $PAGER or alias for cm lsproject -long.</p>

<h3>lsstgloc</h3>

<p>Lists all stglocs to your $PAGER or alias for cm lsstgloc.</p>

<h3>llstgloc</h3>

<p>Lists long all stglocs to your $PAGER or alias for cm lsstgloc -long.</p>

<h3>lsstream</h3>

<p>Lists all streams to your $PAGER or alias for cm lsstream.</p>

<h3>llstream</h3>

<p>Lists long all streams to your $PAGER or alias for cm lsstream -long.</p>

<h3>lsact</h3>

<p>Lists all activities to your $PAGER or alias for cm lsactivity.</p>

<h3>llact</h3>

<p>Lists long all activities to your $PAGER or alias for cm lsactivity -long.</p>

<h3>setact</h3>

<p>Short circut for cm setactivity</p>

<h3>clist</h3>

<p>Lists all currently checked out elements or locally modified cvs entries.</p>

<h3>ciwork</h3>

<p>Check in all checked out work.</p>
  </div> <!-- content -->

  <?php copyright ();?>
</div>

<script language="JavaScript" src="/JavaScript/Menus.js" type="text/javascript"></script>

</body>
</html>
