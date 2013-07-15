<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <meta name="GENERATOR" content="Mozilla/4.61 [en] (Win98; U) [Netscape]">
  <title>ClearSCM: Open Source Builds</title>
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Article.css">
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
  include "../php/clearscm.php";
  menu_css ();
  ?>
</head>

<body id="homepage">
<?php heading ();?>

<div id="page">
  <div id="content">
    <?php start_box ("cs2");?>
      <h2>Open Source Builds</h2>
    <?php end_box ();?>

    <p>More and more organizations are using Open Source in their
    product builds but is the Open Source build mechanisms efficient?
    This article approaches this subject and shows how often Open
    Source can be more trouble than it's worth.</p>

    <h3>Open Source Model</h3>

    <p>Much hype has been given to the Open Source movement and
    rightfully so. Developers can leverage off of Open Source
    development and modules. This article will not address Open Source
    in general nor will it go into the legalities of using Open Source
    in your product. It will instead focus on common Open Source
    building mechanisms in light how efficient or inefficient they may
    be when included in your own build mechanisms.</p>

    <h3>Problems with code sharing</h3>

    <p>Unless you employ people who are active in the Open Source
    community, people who not only participate in using Open Source
    but also contributing to Open Source, you will enevitably come
    face to face with a real problem. If you try to improve the Open
    Source code in any way, unless you donate your changes back to the
    community at large <b>and</b> those changes are accepted, you will
    run into the fact that when the next version of the Open Source in
    question comes out you will have porting work to do. You will need
    to incorporate your changes with changes from the whole
    community. In some cases these changes may be done by the
    community in a similar manner as you had done them. In such cases
    you can abandon your changes and take the communities solution and
    then there is one less conflict for you to worry about.</p>

    <p>Other times the communities change is similar to your change
    but differs enough that you still have to make some minor
    adjustments. Sometimes you can come up with a more generic way to
    doing something that will make everybody happy. In such cases you
    should really consider donating your changes back under the "what
    comes around goes around" principal. Then next update your generic
    solution will not need to be merged again.</p>

    <p>Still other times what you need to do is not like what anybody
    else needs to do or wants. Or it maybe that while your solution is
    brilliant for the limited set of architectures that you are
    considered about the community needs to be concerned about a large
    or different set of architectures and thus cannot accept your
    solution as a general solution that is good for all. In such cases
    you are stuck with maintaining your solution for each iterration
    of the module in question.</p>

    <p>Most developers can relate to the above few paragraphs from an
    "inside the code" level. But what is often overlooked is that part
    above the "inside the code" level - at the build and release
    level.</p>

    <h3>Building Software Efficiently (AKA Build Avoidance)</h3>

    <table border=0 width=50% align=right>
      <tr>
        <td>
          <?php start_box ("cs4");?> 
            <p><i>In the beginning there was make(1) and it was
            good...</i></p>
          <?php end_box ();?>
        </td>
      </tr>
    </table>

    <p>Earlier on most software was built using the standard Unix
    make(1) utility. Make seeks to build only that which need to be
    build. Make uses a number of assumptions in order to perform its
    magic. For example, make assumes that you are using 3rd generation
    languages such as C, FORTRAN, etc. Further make assume you have
    all of the source contained in files in the file system and that
    the source code transforms into object code of some kind using
    some process (e.g. foo.o is derived from foo.c using the C
    complier).</p>

    <p>As more and more languages evolved luckily make was able to
    adapt and you could add new transformation rules and tell make how
    to transform these newer language source files into their
    respective derived object files and how to piece everything
    together. Further you could enhance and automatically define
    dependencies in order to have your build system remain efficient
    and continue to try to achieve that all elusive "rebuild only that
    which requires rebuilding".</p>

    <p>However make is easily thwarted if an eye on how make works and
    how to use it efficiently and effectively is not paid mine. For
    example, since make uses files and their timestamps in order to
    determine if a target needs to be rebuild, putting a bunch of
    functions into one large file is not a good idea since any change
    to any of those functions will result in that whole file being
    recompiled. However, one file per function is the other extreme of
    this. In most software projects related functions comprising some
    group of related software, a module, is a good compromise between
    these two extremes.</p>

    <h3>Using Source RPMs</h3>

    <p>One popular construct in the Open Source world is that of
    source RPMs. RPM stands for Redhat Package Manager and was
    Redhat's answer to the question of how to install software on a
    Linux system. But rpm when farther than that to include what it
    calls Source RPMs. The concept is simple but also beautiful. While
    an rpm is considered a binary install package a source rpm (AKA
    rpms) contains all of the source and related other files like
    makefiles, installation scripts, etc. In short everything is in
    there for you to build the package from scratch. This is usual on
    Linux systems as there are many systems on different architectures
    where a package needs to be compiled before it is installed on the
    system.</p>

    <p>Many companies are taking Redhat Source RPMs and then modifying
    only those packages that they wish to change. Other packages are
    rebuilt from source untouched. This allows developers to
    essentially build their own complete system with their changes
    incorporated. A pretty ideal setup - but are RPM Source builds
    efficient?</p>

    <h3>RPM Source Builds</h3>

    <p>Turns out that RPM source builds are not efficient at all. In
    most cases everything gets recompiled everytime. One reason for
    this is that source rpms are distributed as one large
    file. Another is that a source rpm is really the <b>derived
    file</b> not the set of source files before compilation. Because
    of this make's assumptions have been violated and make is forced
    to recompile everything.<p>

    <p>The rpm -b or rpmbuild execution itself highlights the
    problem. In the normal execution of rpm -b or rpmbuild the
    following actions happen:</p>

    <ol>
      <li>In the %prep section the standard %setup macro's first job
      is to remove any old copies of the build tree</li>

      <li>The next step of the standard %setup macro is to untar the
      source from the embedded tarball</li>

      <li>The final step is to cd to the build directory and set
      permissions appropriately</li>
    </ol>

    <p>So even before we get a chance to build anything we have a
    "fresh" environment which is also an environment where make has no
    chance of doing any build avoidance! Open Source source RPMs that
    use the %setup macro will always build everything every time.</p>

    <h3>The configure redundancy</h3>

    <p>Additionally most Open Source packages first run configure to
    interrogate the environment and configure the package so that it
    can successfully build. In theory it's a good idea. In practice
    it's slow. Also, each module performs this long configure step
    again and again. Configure itself is smart enough to create a
    cache of its findings so running it a second time <b>in the same
    directory or module</b> will not have to go through all that work
    again but remember, because of how source rpms work we are always
    going through configure for the first time. Plus configure does
    not create the cache for the system as a whole but the module
    itself. Descend into another directory representing a module and
    you'll be running configure, again and again...</p>
  </div>

  <?php copyright ();?>
</div>

<script language="JavaScript" src="/JavaScript/Menus.js" type="text/javascript"></script>
v
</body>
</html>
