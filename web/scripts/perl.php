<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <meta name="GENERATOR" content="Mozilla/4.61 [en] (Win98; U) [Netscape]">
  <title>ClearSCM: Perl</title>
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Article.css">
  <link rel="stylesheet" type="text/css" media="print"  href="/css/Print.css">
  <link rel="SHORTCUT ICON" href="http://clearscm.com/favicon.ico" type="image/png">
  <?php
  include "clearscm.php";
  menu_css ();
  ?>
</head>

<body id="homepage">
<?php heading ();?>

<div id="page">
  <div id="content">
    <?php start_box ("cs4")?>
      <h2>Perl</h2>
    <?php end_box ();?>

    <p>Perl is an extremely versitle language that is widely used. A
    quick Perl script can be conjured up in a snap or you can utilize
    an elaborate set of Perl Modules from <a href="http://cpan.org">CPAN</a>
    or create your own modules, packages and objects. Perl supports many
    advanced language concepts.</p>

    <p>With any langauge there comes a style that is developed by users
    of that lanaguage. Styles sometime vary widely - other times beginners
    to the language have little if any. Over the years we have developed
    our own <a href="PerlStyle.php">style</a>.</p>

    <h3>Perl Modules</h3>

    <p>Another thing we have developed is a set of modules of often used
    functionality. Oh sure, there are tons of modules in CPAN, often more
    comprehensive than ours. However such modules are written to cover each
    and every aspect of their topic of focus, often including many constructs
    and subroutines, parameters and the like as to make them more unweildy
    and difficult to work with. Our modules are for "commonly used" things
    to be used in a way so as to simply, not complicate, programming. Some of
    the more basic modules are under GPL and available for download as <a
    href="/clearlib.tar.gz">clearlib.tar.gz</a> and they are desribed here:</p>

    <dl>
      <dt><a href="../php/scm_man.php?file=lib/CmdLine.pm">CmdLine.pm</a></dt>

      <dd>Adds command history stack to command line oriented programs</dd>

      <dt><a href="../php/scm_man.php?file=lib/DateUtils.pm">DateUtils.pm</a></dt>

      <dd>Simple date/time utilities</dd>

      <dt><a href="/php/scm_man.php?file=lib/Display.pm">Display.pm</a></dt>

      <dd>Simple and consistant display routines for Perl</dd>

      <dt><a href="/php/scm_man.php?file=lib/GetConfig.pm">GetConfig.pm</a></dt>

      <dd>Simple config file parsing</dd>

      <dt><a href="/php/scm_man.php?file=lib/Logger.pm">Logger.pm</a></dt>

      <dd>Object oriented interface to handling logfiles</dd>

      <dt><a href="/php/scm_man.php?file=lib/Mail.pm">Mail.pm</a></dt>

      <dd>A simplified approach to sending email</dd>

      <dt><a href="/php/scm_man.php?file=lib/OSDep.pm">OSDep.pm</a></dt>

      <dd>Isolate OS dependencies</dd>

      <dt><a href="/php/scm_man.php?file=lib/Rexec.pm">Rexec.pm</a></dt>

      <dd>Execute commands remotely</dd>

      <dt><a href="/php/scm_man.php?file=lib/TimeUtils.pm">TimeUtils.pm</a></dt>

      <dd>Time utilities</dd>

      <dt><a href="/php/scm_man.php?file=lib/Utils.pm">Utils.pm</a></dt>

      <dd>Simple and often used utilities</dd>
    </dl>

    <h3>Clearcase Perl Modules</h3>

    <p>These modules are &copy; ClearSCM, Inc. If you wish to use them then
    please contact us.</p>

    <dl>
      <dt><a href="/php/scm_man.php?file=lib/Clearcase.pm">Clearcase.pm</a></dt>

      <dd>Object oriented interface to Clearcase</dd>

      <dt><a href="/php/scm_man.php?file=lib/Clearcase/Vobs.pm">Clearcase::Vobs.pm</a></dt>

      <dd>Object oriented interface to Clearcase VOBs</dd>

      <dt><a href="/php/scm_man.php?file=lib/Clearcase/Vob.pm">Clearcase::Vob.pm</a></dt>

      <dd>Object oriented interface to a Clearcase VOB</dd>

      <dt><a href="/php/scm_man.php?file=lib/Clearcase/Views.pm">Clearcase::Views.pm</a></dt>

      <dd>Object oriented interface to Clearcase Views</dd>

      <dt><a href="/php/scm_man.php?file=lib/Clearcase/View.pm">Clearcase::View.pm</a></dt>

      <dd>Object oriented interface to a Clearcase View</dd>

      <dt><a href="/php/scm_man.php?file=lib/Clearcase/Element.pm">Clearcase::Element.pm</a></dt>

      <dd>Object oriented interface to a Clearcase Element</dd>

      <dt><a href="/php/scm_man.php?file=lib/Clearcase/UCM/Activity.pm">Clearcase::UCM::Activity.pm</a></dt>

      <dd>Object oriented interface to a Clearcase UCM Activity</dd>

      <dt><a href="/php/scm_man.php?file=lib/Clearcase/UCM/Stream.pm">Clearcase::UCM::Stream.pm</a></dt>

      <dd>Object oriented interface to a Clearcase UCM Stream</dd>
    </dl>

    <h3>Clearquest Perl Modules</h3>

    <p>These modules are &copy; ClearSCM, Inc. If you wish to use them then
    please contact us.</p>

    <dl>
      <dt><a href="/php/scm_man.php?file=lib/Clearquest.pm">Clearquest.pm</a></dt>

      <dd>Object oriented interface to Clearquest</dd>

      <dt><a href="/php/scm_man.php?file=lib/Clearquest/Client.pm">Clearquest::Client.pm</a></dt>

      <dd>Client interface to Clearquest Daemon</dd>

      <dt><a href="/php/scm_man.php?file=lib/Clearquest/DBService.pm">Clearquest::DBService.pm</a></dt>

      <dd>Clearquest Database Service module</dd>

      <dt><a href="/php/scm_man.php?file=lib/Clearquest/LDAP.pm">Clearquest::LDAP.pm</a></dt>

      <dd>Interface to LDAP info for Clearquest</dd>

      <dt><a href="/php/scm_man.php?file=lib/Clearquest/Server.pm">Clearquest::Server.pm</a></dt>

      <dd>Clearquest Server Module</dd>
      <dt><a href="/php/scm_man.php?file=lib/Clearquest/REST.pm">Clearquest::REST.pm</a></dt>
      <dd>Clearquest REST Module</dd>
    </dl>
  </div>

  <?php copyright ();?>
</div>

<script language="JavaScript" src="/JavaScript/Menus.js" type="text/javascript"></script>

</body>
</html>
