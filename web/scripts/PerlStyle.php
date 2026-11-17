<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
  <title>ClearSCM: Perl Coding Style</title>
  <link rel="SHORTCUT ICON" href="/clearscm/favicon.ico" type="image/x-icon">
  <?php
  include "clearscm.php";
  menu_css ();
  ?>
</head>

<body id="homepage">
<?php heading (); ?>

<div id="page">
  <div id="content">
    <?php start_box ("cs4"); ?>
      <h2>ClearSCM Perl Coding Style</h2>
    <?php end_box (); ?>

    <p>Consistent, readable, and maintainable Perl code is enforced across ClearSCM modules and scripts using <code>perltidy</code> and <code>perlcritic</code>.</p>

    <h3>PerlTidy Configuration (<code>rc/perltidyrc</code>)</h3>
    <?php display_code ("rc/perltidyrc"); ?>

    <h3>PerlCritic Configuration (<code>rc/perlcriticrc</code>)</h3>
    <?php display_code ("rc/perlcriticrc"); ?>
  </div>

  <?php copyright (); ?>
</div>

</body>
</html>
