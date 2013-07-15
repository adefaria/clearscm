<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <meta name="GENERATOR" content="Mozilla/4.61 [en] (Win98; U) [Netscape]">

  <title>ClearSCM: Services</title>

  <link rel="stylesheet" type="text/css" media="screen" href="/css/FrontPage.css">
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

<body id="homepage" class="sm-r"> <!-- try r-sm, sm-r, ms-r or r-ms -->

<?php heading ()?>

<div id="page">
  <div id="content">
    <div id="contentWrapper2">
      <div id="main">
	<h2>Customers</h2>

	<p>Some of our previous clients:</p>

        <?php start_box ("cs3");?>
	<table border=0>
          <tbody>
            <tr>
              <td style="text-align:center">
                  <a href     = "http://ameriquest.com/">
                  <img src    = "/Logos/Ameriquest.gif"
                       alt    = "Ameriquest Mortgage"
                       title  = "Ameriquest Mortgage"
                       border = 0>
                  </a>
              </td>
              <td style="text-align:center">
                  <a href     = "http://broadcom.com/">
                  <img src    = "/Logos/Broadcom.gif"
                       alt    = "Broadcom"
                       title  = "Broadcom"
                       border = 0>
                  </a>
              </td>
            </tr>
            <tr>
              <td style="text-align:center">
                  <a href    = "http://cisco.com/">
                  <img src   = "/Logos/Cisco.gif"
                       alt   = "Cisco Systems"
                       title = "Cisco Systems"
                       border = 0>
                  </a>
              </td>
              <td style="text-align:center">
                  <a href     = "http://hp.com/">
                  <img src    = "/Logos/HPLogo.gif"
                       alt    = "Hewlett Packard"
                       title  = "Hewlett Packard"
                       border = 0>
                  </a>
              </td>
            </tr>
            <tr>
              <td style="text-align:center">
                  <a href     = "http://lynuxworks.com/">
                  <img src    = "/Logos/LynuxWorks.gif"
                       alt    = "LynuxWorks"
                       title  = "LynuxWorks"
                       border = 0>
                  </a>
                </td>
              <td style="text-align:center">
                  <a href     = "http://salira.com/">
                  <img src    = "/Logos/Salira.gif"
                       alt    = "Salira Optical Network Systems"
                       title  = "Salira Optical Network Systems"
                       border = 0>
                  </a>
               </td>
            </tr>
            <tr>
              <td style="text-align:center">
                  <a href     = "http://sun.com/">
                  <img src    = "/Logos/Sun.jpg"
                       alt    = "Sun Microsystems"
                       title  = "Sun Microsystems"
                       border = 0>
                  </a>
                </td>
              <td style="text-align:center">
                  <a href     = "http://ti.com/">
                  <img src    = "/Logos/TexasInstruments.jpg"
                       alt    = "Texas Instruments"
                       title  = "Texas Instruments"
                       border = 0>
                  </a>
               </td>
            </tr>
          </tbody>
        </table>
        <?php end_box ();?>

        <p>We'd love to make you our next client.</p>

      </div> <!-- main -->

      <div id="supporting">
        <?php start_box ("cs3");?>

          <h2><a href="/services/consultancy.php">Consultancy</a></h2>

          <p>Our core service is <a href="/people.php">our people</a>
          and their years of experience in the field.</p>

        <?php end_box ();?>

        <?php start_box ("cs2");?> 

          <h2><a href="/services/custom_software.php">Custom Software
          Solutions</a></h2>

          <p>In addition to SCM, we build custom software solutions
          using:</p>

          <ul>
            <li>Web Site Design</li>

            <li>Web Application Design and Implementation</li>

            <li>Custom Build Automation</li>

            <li>Test Automation</li>
          </ul>

        <?php end_box ();?>

        <?php start_box ("cs4");?> 

          <h2><a href="/services/sysadmin.php">Systems Administration</a></h2>

          <p>Whether large or small, today's software is more
          complex. Many resources are brought to bear to get your code
          from inception to release....<a href="/sysadm">(more)</a>

        <?php end_box ();?>

      </div> <!-- supporting -->
    </div> <!-- contentWrapper2 -->

    <div id="contentWrapper1">
      <div id="related">
        <?php start_box ("cs2");?> 

          <h2><a href="/services/scm.php">SCM</a></h2>

          <p>Managing the complexities of modern software requires
          professional methodologies, professional tools and, well,
          professionals. That's where we come in. We apply solid
          configuration management practices to your software to
          insure a smooth flow from design through deployment.</p>

        <?php end_box ();?>

        <?php start_box ("cs3");?> 

          <h2><a href="/services/web.php">Web Applications</a></h2>

	  <p>We also specialize in customer web applications to suit
	  your business needs</p>

        <?php end_box ();?>

        <?php start_box ("cs5");?> 

          <h2><a href="/services/customers.php">Customers</a></h2>

          <p>We've worked with many, well known, fortune 500
          companies. Let us work for you!</p>
        <?php end_box ();?>
      </div> <!-- related -->
    </div> <!-- contentWrapper1 -->
  </div> <!-- content -->
  <?php copyright();?>
</div> <!-- page -->

<script language="JavaScript" src="/JavaScript/Menus.js" type="text/javascript"></script>

</body>
</html>
