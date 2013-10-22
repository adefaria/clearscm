<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
  <meta name="GENERATOR" content="Mozilla/4.61 [en] (Win98; U) [Netscape]">

  <title>ClearSCM: Clearcase: Triggers: Evil Twin</title>

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
  include "clearscm.php";
  menu_css ();
  ?>
</head>

<body>

<?php heading ();?>

<div id="page">
  <div id="content">
    <?php start_box ("cs5");?>
      <h2>Evil Twin Trigger</h2>

      <p>This trigger prevents the creation of <i>Evil Twins</i>. An
      evil twin is where a user attempt to create a new Clearcase
      element with the same name as an element that was previously
      created, perhaps on another branch of the parent
      directory.</li></p>
    <?php end_box ();?>

    <h3>What are Evil Twins?</h3>

    <p>Simply put, an evil twin is a condition that can be caused in
    Clearcase when a user attempts to add an element to source control
    that has a name that is the same as an element on another
    branch. If it is allowed to be created it will be difficult if not
    impossible to merge in the future. You don't want evil twins to be
    created to start with.</p>

    <p>Let's look a little bit deeper into how this can happen. Let's
    assume that a user adds the element named "foo" to the directory
    bin. Sometime later that element name is removed with
    rmname. Finally assume that it is decided that foo is again
    needed. When it is recreated the second time you will be creating
    an evil twin because Clearcase will get confused between foo in
    say version 3 of the parent directory and this new foo destined
    for say version 7 of the parent directory.</p>

    <p>Here's a few steps to create the evil twin scenario:</p>

    <div class="code"><pre>
$ # First check out the current directory and create foo
$ ct co -nc .
$ echo "bar" > foo
$ ct mkelem -nc foo
$ # Now check it all in
$ ct ci -nc foo .
$ # Now check out the parent directory and rmname foo
$ ct co -nc .
$ ct rmname foo
$ ct ci -nc .
    </pre></div>

    <p>At this point we have a directory with foo in it and then the
    next version of the directory has foo rmnamed
    (i.e. uncataloged). Now let's attempt to create an evil twin:</p>

    <div class="code"><pre>
$ # Let's create foo's evil twin
$ ct co -nc .
$ echo "Evil Twin" > foo
$ ct mkelem -nc foo
    </pre></div>

    <p>At this point we should see the following dialog box preventing
    the creation of the evil twin:</p>

    <p><i>Insert dialog box here</i></p>

    <p>This is telling us that we are about to create an evil
    twin. Note that it also tells us where it found the first twin in
    the view extended syntax (the part starting with @@). There is
    another dummy in the bin directory in "andys_branch" version
    1.</p>

    <h3>Merging the Original Elements Back</h3>

    <p>The preferred way to resolve this problem is to merge the
    original elements back from the proper directory version of the
    parent directory into the current branch. To do this you must
    first locate the branch where the evil twin existed. From the
    above example that would be
    \main\Andrew_Integration\adefaria_Andrew\3. Locate that version of
    the parent directory (e.g. the adm\bin directory of andy vob in
    the above example) in the Clearcase Version Tree Browser. To be
    clear, locate the parent directory for the element dummy in the
    Clearcase Explorer, right click on it and select Version Tree then
    look in the version tree for the
    \main\Andrew_Integration\adefaria_Andrew\3 version.</p>

    <p><b>Note:</b> A good way to find this directory version in
    directory elements that have large or complicated verion trees is
    to use the Locate toolbar button (the button with the "flashlight"
    icon). You can search for versions by version name, branch,
    etc).</p>

    <p>Next right click on that version (the version of the parent
    directory that has the original elements) and select Merge
    to. Your mouse cursor will change to a little "target" icon. Next
    select the version of the directory that your view selects (this
    can be found by locating the little "eye" icon).</p>

    <p>Just before you select OK to start the merge make sure you
    toggle on the Merge the element graphically toggle. This will
    start cleardiffmrg and prompt you to select each merge.</p>

    <p>This will bring up cleardiffmrg and allow you to confirm each
    merge of the diredtory. During the merge choose the entries from
    the parent directory for the elements that you wish to "recover"
    or "reinstate" .</p>

    <p>Another way to resolve this condition is to hardlink to the
    previous version of this element but this is not always what you
    want to do. For one it can be confusing. In any event if you need
    help because you've hit and evil twin be sure to contact the Help
    Desk and we'll help you out.</p>

    <?php display_code ("cc/triggers/EvilTwin.pl");?>

  <?php copyright ();?>
  </div>
</div>

<script language="JavaScript" src="/JavaScript/Menus.js" type="text/javascript"></script>

</body>
</html>
