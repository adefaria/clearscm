<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <meta name="GENERATOR" content="Mozilla/4.61 [en] (Win98; U) [Netscape]">
  <title>ClearSCM: Our People: Andrew DeFaria - President</title>
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Article.css">
  <link rel="stylesheet" type="text/css" media="print"  href="/css/Print.css">
  <link rel="SHORTCUT ICON" href="http://clearscm.com/favicon.ico" type="image/png">

<script type="text/javascript">
function blink () {
  if (!document.getElementById('blink').style.color) {
    document.getElementById('blink').style.color="white";
  } // if

  if (document.getElementById('blink').style.color=="white") {
    document.getElementById('blink').style.color="red";
  } else {
    document.getElementById('blink').style.color="white";
  } // if

  timer = setTimeout ("blink()", 450);
} // blink

function stoptimer () {
  clearTimeout (timer);
} // stoptimer
</script>

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

  // Record hit
  $dir = dirname(__FILE__);

  if (file_exists("$dir/.resumehits")) {
    $resumeHit = fopen("$dir/.resumehits", 'r');

    fscanf($resumeHit, "%d\n", $count);
  } else {
    $count = 0;
  } // if

  $count++;

  fclose($resumeHit);

  $resumeHit = fopen ('.resumehits', 'w');

  fwrite($resumeHit, $count);
  fclose($resumeHit);

  $resumeHist = fopen('.resume.hist', 'a');
  $date = date(DATE_RFC822);

  fwrite($resumeHist, "$_SERVER[REMOTE_ADDR] read resume at $date\n");
  fclose($resumeHist);

  $msg  = '<html><body>';
  $msg .= '<h1>Somebody just visited your resume.</h1>';
  $msg .= "<p>Here's what I know about them:</p>";

  $me = false;

  foreach ($_SERVER as $key => $value) {
    if (preg_match("/^REMOTE/", $key)) {
      $msg .= "$key: $value<br>";

      if ($key == 'REMOTE_ADDR') {
        // Skip me...
        if ($value == '184.182.63.133') {
	  $me = true;

	  break;
	} // if

        exec("whois $value", $output, $result);

        foreach ($output as $line) {
         $msg .= "$line<br>";
        } // foreach
      } // if
    } // if
  } // foreach

  if (!$me) {
    $msg     .= '</body></html>';
    $headers  = "MIME-Version: 1.0\r\n";
    $headers .= "Content-type: text/html; charset=iso-8859-1\r\n";
    $headers .= "From: Andrew DeFaria <Andrew@DeFaria.com>";

    mail("andrew@defaria.com", "Somebody visited your resume", $msg, $headers);
  } // if
?>
</head>

<body onload="blink()" onunload="stoptimer()" id="homepage">

<?php heading ();?>

<div id="page">
  <div id="content">
    <?php start_box ("cs2")?>
      <h2 align=center><a href="http://defaria.com">Andrew P. DeFaria</a></h2>
      <address style="text-align:center">
      14435 South 48th Street #2083<br>
      Phoenix, Arizona 85044-6448<br>
      </address>
      <p style="text-align:center">
      Phone: 408-596-4937</a><br>
      Email: <a href="mailto:Andrew@DeFaria.com">Andrew@DeFaria.com</a><br>
<table align="center" width="400">
  <tr>
    <td>
      <marquee behavior="alternate" onmouseover="this.stop()" onmouseout="this.start()"><a id="blink" href="Resume.odt">Download an MS Word copy!</a></marquee><br>
    </td>
  </tr>
    <td align="center">
      <center>
      <font size=-1 class="dim">Sorry for the blink but for some reason recruiters can't find this link!</font></p>
      </center>
    </td>
  </tr>
  <tr>
    <td align="center">
      <center>
      <font size=-1>For the most up to date copy of this resume see <a href="http://clearscm.com/Resumes/Andrew">http://clearscm.com/Resumes/Andrew</a></font>
      </center>
    </td>
  </tr>
</table>
    <?php end_box ();?>

    <table cellspacing="0" cellpadding="0" width="300" border="0" align="center">
      <tbody>
        <tr>
         <td valign="top" align center>
            <a href="AWS Certified Solutions Architect - Associate certificate.pdf" target="_blank">
            <div>
                <img src="AWS_Certified_Logo_SAA_294x230_Color.png" alt="AWS Certified Solutions Architect"><br>
              <br>
                <img src="AWS_Certified_Tag__SAA_294x230-Color.png" alt="Associate">
              <br>
              <b>Validation Number:</b> 4Q2XDJDCK1EE1HC5
            </div>
            </a>
          </td>
        </tr>
      </tbody>
    </table>


  <h3>Objective</h3>

  <p>To work with state of the art operating systems and networks to
  insure the smooth running of an organization's information flow.</p>

  <h3>Hardware</h3>

  <p>Workstations and servers from Sun, HP, Microsoft Windows as well as various
  other manufactures of Linux systems.</p>

  <h3>Operating Systems</h3>

  <p><span class="standout">Linux</span> (Redhat, Centos, Ubuntu),
  <span class="standout">Windows</span>, <span class="standout">Unix</span>
  (Solaris, HP-UX), <span class="standout"><a href="http://cygwin.com">Cygwin</a></span></p>

  <h3>Networking</h3>

  <p>TCP/IP, Windows and Unix Networking, <span
  class="standout">Active Directory/LDAP</span>, <span
  class="standout">Samba</span></p>

  <h3>Software</h3>

  <table align=center border=1 cellspacing=0 cellpadding=2 width="60%">
    <tbody>
      <tr>
        <th>Version Control Systems</th>
        <td>
          <span class="standout">Git</span>, <span class="standout">Perforce</span>,
          <span class="standout">Clearcase</span>
        </td>
      </tr>
      <tr>
        <th>Issue Tracking</th>
        <td>
          <span class="standout">JIRA</span>, <span class="standout">Clearquest</span>,
          <span class="standout">Bugzilla</span>
        </td>
      </tr>
      <tr>
        <th>Languages</th>
        <td>
          <span class="standout">Perl</span>, <span class="standout">Bash</span>,
          <span class="standout">PHP</span>, <span class="standout">C++</span>,
          <span class="standout">C</span>, <span class="standout">Ada</span>,
          <span class="standout">TCL</span>
        </td>
      </tr>
      <tr>
        <th>Configuration Management</th>
        <td>
          <span class="standout">Puppet</span>, <span class="standout">Ansible</span>
        </td>
      </tr>
      <tr>
        <th>Middleware</th>
        <td>
          <span class="standout">Apache</span>, <span class="standout">Tomcat</span>,
          <span class="standout">Samba</span>, <span class="standout">Winbind</span>,
          <span class="standout">LDAP</span>, <span class="standout">REST</span>
        </td>
      </tr>
      <tr>
        <th>Web Apps</th>
        <td>
          <span class="standout">JIRA</span>, <span class="standout">Confluence</span>,
          <span class="standout">Swarm</span>
        </td>
      </tr>
      <tr>
        <th>Databases</th>
        <td>
          <span class="standout">MySQL</span>, <span class="standout">Oracle</span>
        </td>
      </tr>
      <tr>
        <th>Coninuous Integration</th>
        <td>
          <span class="standout">Build Forge</span>, <span class="standout">Electric Commander</span>,
          <span class="standout">Jenkins</span>
        </td>
      </tr>
      <tr>
        <th>Virtualization</th>
        <td>
          <span class="standout">VMWare</span>, <span class="standout">VirtualBox</span>,
          <span class="standout">vSphere</span>, <span class="standout">vCenter</span>
        </td>
      </tr>
      <tr>
        <th>Cloud Computing (<span class="standout">Classroom Only</span>)</th>
        <td>
          <span class="standout">EC2</span>, 
          <span class="standout">IAM</span>, 
          <span class="standout">S3</span>, 
          <span class="standout">Glacier</span>, 
          <span class="standout">CloudFront</span>, 
          <span class="standout">Route53, 
          <span class="standout">VPC</span>
        </td>
      </tr>
    </tbody>
  </table>

  <h3>Education</h3>

  <p>
    A.A.S. in Computer Science from Union County College in Scotch Plains, New
    Jersey. Continued studies at Fairleigh Dickenson University,  San Jose State

    University, Mission College and Chico State in pursuit of my degree.</p>

  <h3>References</h3>

  <table align=center border=1 cellspacing=0 cellpadding=2 width="90%">
    <tbody>
      <tr>
        <td><a href="https://www.linkedin.com/in/charles-clarke-30853132/">Charles Clarke</a></td>
        <td>(770) 252-1500</td>
        <td><a href="mailto:charles@abs-consulting.com">charles@abs-consulting.com</a></td>
        <td>Owner ABS Consulting</td>
      </tr>
      <tr>
        <td><a href="https://www.linkedin.com/in/tom-connor-285114/">Tom Connor</a></td>
        <td>(512)-422-1172</td>
        <td><a href="mailto:tomhillconnor@yahoo.com">tomhillconnor@yahoo.com</a></td>
        <td>Coworker, Consultant</td>
      </tr>
      <tr>
        <td><a href="https://www.linkedin.com/in/specware/">James Chen</a></td>
        <td>(408)-845-5360</td>
        <td><a href="mailto:jchen@salira.com">jchen@salira.com</a></td>
        <td>Consultant at Specware & 2Opp, LLC</td>
      </tr>
      <tr>
        <td><a href="https://www.linkedin.com/in/shivdutt-jha-032414/">Shivdutt Jha</a></td>
        <td>(408)-806-3476</td>
        <td><a href="mailto:shivdutt_jha@hotmail.com">shivdutt_jha@hotmail.com</a></td>
        <td>Coworker, Consultant</td>
      </tr>
    </tbody>
  </table>

  <br>

  <h2>Clients</h2>

  <hr noshade>

  <p><a href="https://gdmissionsystems.com/en/satellite-ground-systems/mobile-user-objective-system">
  <img src="General_Dynamics_logo.jpg" alt="General Dynamics" border="0"></a></p>

  <p>March 2018 - Present<br>
  <font class=dim>Contract</font><br>
  <a href="https://defaria-status.blogspot.com/search/label/General%20Dynamics">General Dynamics</a></font>

  <p>For this technology refresh of over a decade ago, I was instrumental in 
  setting up and maintain dozens of Solaris 5.11 zone systems and served as the
  primary Solaris System Administrator. This includes setup of many services
  like NIS, DNS, NTP, SMTP, AutoFS as well as a standard set of tools.

  <p>Introduced <span class="standout">Puppet</span> to the group and served as
  the <span class="standout">Puppet Master</span>.</p>

  <p>Created Windows based <span class="standout">VMs</span> for specific roles
  such as <span class="standout"BuildForge Console</span>, Application server,
  Domain Controllers, etc. These were managed under <span
  class="standout">vCenter</span>.</p>

  <p>Developed <span class="standout">Perl</span> scripts for validation testing
  of <span class="standout">Clearcase</span> and <span class="standout">Clearquest</span>.
  Developed a Clearcase enhanced monitoring tool to monitor servers, loadavg and
  filesystems as well as Clearcase objects like VOBs and views.</p>

  <hr noshade>

  <p><a href="http://www.broadcom.com"><img src="Broadcom.gif" alt="Broadcom/Avago" border="0"></a></p>

  <p>August 2016 - January 2018<br>
  <font class=dim>Contract</font><br>

  <p>Converted an internal project from a <span class="standout">Jenkins</span>/
  <span class="standout">Perforce</span> build system to the Broadcom/Avago 
  standard of <span class="standout">Electric Commander</span>/
  <span class="standout">Git</span>. Developed Perl scripts to sign executables
  and remotely execute commands on Windows systems using <span 
  class="standout">Cygwin/ssh</span> thus streamlining and standardizing remote
  building and signing of executables.</p>

  <hr noshade>

  <p><a href="http://icann.org"><img alt="ICANN" src="ICANN.png" border="0"></a><br></p>

  <p>May 2016 - July 2016<br>
  <font class=dim>Contract</font><br>

  <p>Developed <a 
  href="https://en.wikipedia.org/wiki/Registration_Data_Access_Protocol">RDAP</a>
  server for testing SLA compliance of various TLD registrars around the world.</p>

  <hr noshade>

  <p><a href="http://audience.com"><img alt="Audience" src="Audience.png" border="0"></a><br><b>A Knowles Company</b></p>

  <p>March 2014 - April 2016<br>
  <font class=dim>Contract</font><br>
  <a href="https://defaria-status.blogspot.com/search/label/Audience">Audience</a></p>

  <p>Initially wrote scripts to import data from
  <span class="standout">Bugzilla</span> and other sources to
  <span class="standout">JIRA</span> thus automating the migration of several
  projects. Also administered <span class="standout">Linux</span> servers
  (<span class="standout">Centos</span>/<span
  class="standout">Ubuntu</span>/<span class="standout">Redhat Enterprise</span>)
  managing VM images in vSphere,
  <span class="standout">Perforce</span>, <span class="standout">Swarm</span>, 
  <span class="standout">Git Fusion</span>.</p>

  <p>Added functionality to custom build system that utilized <span 
  class="standout">Perl</span>/<span class="standout">PHP</span>/<span 
  class="standout">Apache</span>/<span class="standout">Linux</span>/<span 
  class="standout">Windows</span> servers to allow engineers in the field to 
  remotely perform customized builds. Integrated Bugzilla and Perforce (P4DTG). 
  Assisted with JIRA setup and integration of <span 
  class="standout">Salesforce</span> with JIRA. Assisted in the migration
  for users to new Knowles domain.</p>

  <hr noshade>

  <p><a href="http://www.axcient.com"><img src="Axcient.png" alt="Axcient" border="0"></a></p>

  <p>July 2013 - Dec 2013<br>
  <font class=dim>Contract</font><br>
  <a href="http://defaria.com/blogs/Status/archives/cat_axcient.html">Axcient</a></p>

  <p>Worked as a <span class="standout">Build and Release Engineer</span> for
  AxOS. The Axcient product is a customized derivative of <span 
  class="standout">Ubuntu</span>. The SCM system being used is <span 
  class="standout">git</span>. Developed and standardized procedures for 
  performing builds.</p>

  <hr noshade>

  <p><a href="http://www.broadcom.com"><img src="Broadcom.gif" alt="Broadcom" border="0"></a></p>

  <p>December 2011 - April 2013<br>
  <font class=dim>Contract</font><br>
  <a href="https://defaria-status.blogspot.com/search/label/Broadcom">Broadcom</a></p>

  <p><span class="standout">Clearquest Designer</span>: Maintained Clearquest 
  instances implementing functionality with <span class="standout">Visual Basic</span>. 
  Using ClearSCM's <a 
  href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase.pm">Clearquest</a>, 
  <a href="http://clearscm.com/php/scm_man.php?file=lib/Clearquest/Server.pm">Clearquest::Server</a>,
  <a href="http://clearscm.com/php/scm_man.php?file=lib/Clearquest/Client.pm">Clearquest::Client</a>
  and <a href="http://clearscm.com/php/scm_man.php?file=lib/Clearquest/REST.pm">Clearquest::REST</a>
  modules created <span class="standout">Perforce</span> and <span class="standout">Git</span>
  triggers to automate builds updating Clearquest in the process.</p>

  <p>Migrated a project from their unsupported build environment into the standard
  <span class="standout"><a
  href="http://www.electric-cloud.com/products/electriccommander.php">Electric 
  Commander</a></span>/<span class="standout">Perforce</span> based solution 
  using <span class="standout">Cygwin</span>, <span class="standout">bash</span>
  and <span class="standout">LSF</span> to farm builds out to a pool of <span 
  class="standout">Windows</span> servers to perform builds. Builds were done 
  using <span class="standout">Visual Studio</span> 8.0, 9.0 and 10.0 on Windows
  Servers triggered by Perforce triggers at code checkin.</p>

  <hr noshade>

  <p><a href="http://www.tellabs.com"><img src="Tellabs.gif" alt="Tellabs" border="0"></a></p>

  <p>March 2011 - December 2011<br>
  <font class=dim>Contract</font><br>
  <a href="https://defaria-status.blogspot.com/search/label/Tellabs">Tellabs</a></font>

  <p>Automated various informational systems using <span 
  class="standout">Perl</span>/<span class="standout">MySQL</span>/<span 
  class="standout">Oracle</span>, and the web.</p>

  <p>Developed a command line debugger called <a 
  href="http://clearscm.com/php/scm_man.php?file=bin/raid">RAID</a> (a Real
  Aid In Debugging) which provided a consistent interface with complete command 
  history and variable substitution courtesy of a Perl module that I wrote 
  called <a 
  href="http://clearscm.com/php/scm_man.php?file=lib/CmdLine.pm">Cmdline.pm</a>.
  This Perl process utilized <span class="standout">Inline::C</span> to 
  interface to the developer libraries and provide a consistent interface for 
  the various command line debuggers developed by various different groups.</p>

  <hr noshade>

  <p><a href="https://www2.gehealthcare.com/portal/site/usen"><img src="GEHealthcare.gif" alt="General Electric" border="0"></a></p>

  <p>January 2010 - October 2010<br>
  <font class=dim>Contract</font><br>
  <a href="https://defaria-status.blogspot.com/search/label/General%20Electric">General Electric</a></font>

  <p>Performed <span class="standout">Clearcase</span>/<span 
  class="standout">Clearquest UCM</span> administration. Developed an <a 
  href="http://clearscm.com/php/scm_man.php?file=cc/etf.pl">Evil Twin Finder</a>
  in Perl. Worked with <span class="standout">Build Forge</span> (IBM's CI tool
  similar to <span class="standout">Jenkins</span>) jobs to automate work flow.
  Assisted in consultations with UCM concepts such as component/composite
  baselines and projects. Wrote Perl scripts for conversions of Clearquest data
  with other systems (Siebel).</p>

  <hr noshade>

  <p><a href="http://www.gdc4s.com"><img src="General_Dynamics_logo.jpg" alt="General Dynamics" border="0"></a></p>

  <p>June 2007 - October 2009<br>
  <font class=dim>Contract</font><br>
  <a href="https://defaria-status.blogspot.com/search/label/General%20Dynamics">General Dynamics</a></font>

  <p><span class="standout">Clearcase</span>/<span class="standout">Clearquest</span>
  Administrator, <span class="standout">Build Release</span> and 
  <span class="standout">Automation</span> using <span 
  class="standout">Perl</span> scripts. Updated <span 
  class="standout">C++</span>/<span class="standout">Qt</span> application that
  integrates <span class="standout">UCM</span>/Clearquest integrated environment
  into one tool and ported it to Linux.</p>

  <p>Instrumental in establishment of Perl standards and introduction of Perl
  tools such as <a href="http://perlcritic.com/">Perl::Critic</a>
  and <a href="http://perltidy.sourceforge.net/">Perl::Tidy</a>.
  Worked at promoting usage of CPAN modules.</p>

  <p>Developed an extensive test driver application in Perl to interface and
  drive tests using <a href="https://www.nethawk.fi/products/nethawk_simulators/">NetHawk
  EAST Simulators</a> as well as interfacing to other simulators and external
  hardware. The system automates the running of regression tests, official
  testing before the customer, assists with validation of test results,
  collecting of log files, checking log files into Clearcase and records status
  into a MySQL database. Developed a PHP web page to present the data in various
  forms including graphs, reports, exporting to CSV files and emailing of
  reports. Implemented maintenance programs to scrub and keep the data clean.
  This system was instrumental in Functional Quality Testing for the <a 
  href="http://en.wikipedia.org/wiki/Mobile_User_Objective_System">MUOS</a>
  program. This reduced the time it took to certify testing with the military several
  fold.</p>

  <p>Worked on many enhancements to the extensive Clearquest system in use at
  GD. Designed and developed the record set implementing node configurations.
  Implemented required forms and action hook code. Designed and developed Perl
  scripts to initially load data into the new records.</p>

  <p>Developed a server process (daemon) to process baseline records that were
  then tracked by Clearquest. Implemented scripts to create baseline records
  from other automated process such as Build Forge. Tied together baseline
  records with node configurations through action hook code.</p>

  <hr noshade>

  <p><a href="http://ti.com"><img src="TexasInstruments.jpg"
  alt="Texas Instruments" title="Texas Instruments" border=0></a></p>

  <p>October 2006 - June 2007<br>
  <font class=dim>Contract</font><br>
  <a href="https://defaria-status.blogspot.com/search/label/Texas%20Instruments">Texas Instruments</a></font>

  <p><span class="standout">Clearcase</span>/<span 
  class="standout">Clearquest</span> Administrator. Wrote a <span 
  class="standout">Perl</span>/<span class="standout">Oracle</span>
  application to track information about projects worldwide. Automated Clearcase
  license usage reporting and load balancing of Clearquest web servers.</p>

  <hr noshade>

  <p><a href="http://hp.com"><img src="HPLogo.gif" alt="Hewlett
  Packard Company" title="Hewlett Packard Company" border=0></a></p>

  <p>February 2006 - October 2006<br>
  <font class=dim>Contract</font><br>
  <a href="https://defaria-status.blogspot.com/search/label/HP">Hewlett Packard</a></p>

  <p>Managed and executed day to day build and release duties. Served as
  <span class="standout">Clearcase/Clearquest</span> Administrator as well as 
  overall support of systems. Assisted with creating UCM streams and handling of
  rebase and delivery issues for engineers and the build/release process. Wrote
  <span class="standout">UCM triggers</span> to notify users of deliveries from
  UCM development streams. Created baselines for official builds. Took over day
  to day build and release duties. Created a build script that united the
  various quick and dirty build scripts that were oriented per stream and per
  build option. This standardized the build process. Augmented this build script
  to be a daemon that continually builds software when deliveries are detected.
  Wrote a build status web page that tracks and monitors the continuous
  building. Created a dynamic web page to show Junit test history. Converted
  Windows build from bat files and scheduled tasks -> Cygwin and cron thus
  making the build script identical on both Linux and Windows. Wrote triggers
  to notify users of deliveries. Baselined official builds. Automated the build
  process to perform simple continuous integration. Created a dynamic web page
  to show Junit test history.

  <hr noshade>

  <p><a href="http://www.broadcom.com"><img src="Broadcom.gif"
  alt="Broadcom" title="Broadcom" border="0"></a></p>

  <p>September 2005 - January 2006<br>
  <font class=dim>Contract</font><br>
  <a href="https://defaria-status.blogspot.com/search/label/Broadcom">Broadcom</a></p>

  <p>Served as <span class="standout">Clearcase/Clearquest</span> Administrator
  as well as overall support of systems. Developed several <a href="http://clearscm.com/clearcase/triggers.php">triggers</a>
  as well as ported my <a href="http://clearscm.com/clearcase/triggers.php">mktriggers</a>
  script which automates the maintenance of triggers.</p>

  <p>Developed a complex <a hef="http://clearscm.com/clearquest/db.php">Perl script</a>
  to merge two Clearquest databases to a new database with many schema changes.
  This script handled all aspects of the conversion including changing non US
  ASCII characters found in the data to their HTML equivalents, dynamic creation
  of dynamic lists, field renaming and dynamically creating new stateless
  records as needed.</p>

  <p>Developed a script to better handle merging from UCM deliveries and rebases
  by delaying any non automatic merges to the end of the process as well as
  handle binary element merge. This process, written in Perl, utilized PerlTk to
  present the user with a GUI dialog box to choose which version of the binary
  file to merge.</p>

  <p>Designed and developed another Clearquest database for the Mobile
  Multimedia group.</p>

  <p>Wrote several other scripts including one to interface CVS to IMS (a defect
  tracking system) recording the change set at commit time, a script to strip
  out MIME/HTML and attachments for defects submitted to GNATS (another defect
  tracking system). Also implemented several script to log Clearcase activity,
  check Clearcase's pulse and gather site and vob statistics. These scripts were
  the start for creation of a set Object Oriented Perl modules to encapsulate
  Clearcase in a Perl like manner (still in development).</p>

  <hr noshade>

  <p><a href="http://www.lynuxworks.com"><img src="Lynuxworks.png"
  alt="Lynuxworks" title="Lynuxworks" border="0"></a></p>

  <p>December 2004 - September 2005<br>
  <a href="https://defaria-status.blogspot.com/search/label/LynuxWorks">LynuxWorks</a></p>

  <p>Served as a build engineer in the Integration Group responsible for
  building LynxOS (Linux RTOS) as well as tool chains, testing, releasing and
  process improvement. LynuxWorks uses CVS for version control.</p>

  <p>Developed a process of providing full text search of the company's defect
  database using Perl and Htdig (See <a href="http://clearscm.com/scripts/ecrd">ECRDig</a>).
  Developed a web based report to show CVS activity as well as several other CVS
  related utilities(See <a href="http://defaria.com/Resume/cvs_utilities">CVS
  Utilities</a>) as well as report on the differences between two CVS tags.</p>

  <p>Automated the build process so that nightly builds could be performed.
  Developed a web application that allows one to maintain CVS account
  information including account creation, setting/resetting of password, etc.</p>

  <hr noshade>

  <p><a href="https://www.ameriquestcorp.com/"><img src="Ameriquest.png"
  alt="Ameriquest" title="Ameriquest" border="0"></a></p>

  <p>March 2004 - December 2005<br>
  <font class=dim>Contract</font><br>
  <a href="https://defaria-status.blogspot.com/search/label/Ameriquest">Ameriquest</a></p>

  <p>Served as Clearcase/Clearquest administrator to this major mortgage
  company. As Ameriquest is just starting out I have been busy with importing
  source code from flat file systems as well as PVCS and Visual Source Safe.
  Also setting up vobs and regions taking into account security restrictions
  and concerns. Assisted with designing of the Multisite scheme to India.
  Participated in design of UCM model to be used for Ameriquest.</p>

  <hr noshade>

  <p><a href="http://krldesign.com/saliraweb/"><img src="Salira.png"
  alt="Salira" title="Salira" border="0"></a></p>

  <p>August 2001 - February 2004<br>
  <a href="https://defaria-status.blogspot.com/search/label/Salira">Salira</a></p>

  <p>After consulting briefly with Salira Optical Network Systems I joined this
  startup company serving in the role of Clearcase/Clearquest Administrator for
  this mostly Windows shop. I helped others in setting up the 
  Clearcase/Clearquest environment as well as provided Training.</p>

  <p>I also served in the role of Release Engineer managing the build process.
  I employed wide usage of <a href="http://cygwin.com/">Cygwin</a>, which is a
  product that provides an extremely workable Unix like environment and
  engineered a build environment around that using GNU make and other standard
  Unix and GNU utilities. When users complained that building remotely was slow
  I performed an analysis on build performance. I also performed Build Stress 
  Testing where I characterized the effect of multiple simultaneous builds
  performed on the server.</p>

  <p>I also setup and developed their Clearquest bug tracking system as well
  as served as an advisor/expert on Clearcase issues, branching strategies,
  labeling and release management.</p>

  <p>While working at Salira I designed and developed a tool in C that packaged
  the product into a more compact form.</p>

  <p>I designed and implemented a <a href="http://clearscm.com/clearquest/cqd">Clearquest
  Daemon</a> which served as an interface between processes and Clearquest data.
  This daemon serviced requests from web pages and triggers in order to get and
  validate data from Clearquest.</p>

  <p>Developed release web pages that managed releases and produced release
  notes for every release.</p>

  <p>Developed process automation scripts to perform automatic branch merging
  and syncing.</p>

  <p>Performed product installation testing for the web component on Linux
  (SuSE) and Solaris as well as browser testing (Netscape).</p>

  <p>Implemented test scaffolding in TCL/TK for test automation.</p>

  <hr noshade>

  <p><a href="http://hp.com"><img src="HPLogo.gif" alt="Hewlett
  Packard Company" title="Hewlett Packard Company" border=0></a></p>

  <p>August 1999 - February 2001<br>
  <font class=dim>Contract</font><br>
  Systems Technology Division<br>
  Enterprise Java Lab</p>

  <p>Setup security system automating the running of Medusa (an internal
  security audit tool) on approximately 100 machines. Reports are generated
  automatically and are viewable on the web. Setup and maintained security
  related patch depots.</p>

  <p>Implemented nightly automation for the lab's machines including security
  checks, automatic installation of line printer models, etc. This automation
  was bundled into an SD-UX bundle.</p>

  <p>Migrated user data to HP NetStorage 6000. Worked extensively with HP
  NetStorage 6000 Support on problems with this machines OS and interfacing with
  Windows 2000.</p>

  <P>Migrated HP-UX applications from one application server to another.

  <p>Participated in several critical planned networked down times where the
  team was able to implement changes to the infrastructure, including migration
  to Clearcase 4.0, migration of project and user data to HP NetStorage 6000's
  and other such changes.</p>

  <p>Set up Netscape Enterprise Web Server and iPlanet 4.1 Web Server.</p>

  <hr noshade>

  <p><a href="http://cisco.com"><img src="Cisco.gif" alt="Cisco Systems" 
  title="Cisco Systems" border=0></a></p>

  <p>March 1999 - August 1999<br>
  <font class=dim>Contract</font><br>
  <a href="https://defaria-status.blogspot.com/search/label/Cisco">Cisco</a></p>

  <p>Served as Clearcase/Unix Systems Administrator. Responsible for all
  Clearcase operations in CNS/AD on Sun Solaris, HP-UX, Windows NT 4.0 and
  Windows 2000. Assisted in creating additional View and Vob servers and
  balancing the Clearcase load amongst them. Participated in Rational's Beta
  program for Windows 2000. Installed, tested and documented Clearcase on
  Windows 2000 as well as Windows NT 4.0.</p>

  <p>Assisted in recovery of a catastrophic disk failure in a critical vob.
  Assisted with implementing a backup strategy with Arcserve Open. Helped
  evaluate system monitoring packages.</p>

  <p>As CNS/AD was in a secured and isolated network, learned and assisted users
  with ssh/scp.</p>

  <hr noshade>

  <a href="https://www.oracle.com/sun/index.html"><img src="Sun.jpg" alt="Sun Microsystems" 
  title="Sun Microsystems" border=0></a></p>

  <p>December 1998 - March 1999<br>
  <font class=dim>Contract</font><br>
  <a href="https://defaria-status.blogspot.com/search/label/Sun">Sun Microsystems</a></p>

  <p>Worked on the Sunpeak Configuration Management team performing promotions
  of code updates into test and production environments. Also worked on
  improving the process flow of promotions utilizing make and rdist.</p>

  <hr noshade>

  <p><a href="http://hp.com"><img src="HPLogo.gif" alt="Hewlett
  Packard Company" title="Hewlett Packard Company" border=0></a></p>

  <p>February 1988 - November 1998<br>
  Systems Technology Division<br>
  Enterprise Java Lab</p>

  <p>Primary Clearcase and Multisite Administrator for a large Clearcase
  environment with approximately 1400 views and 180 vobs. Most vobs are
  multisited between several other labs and I am responsible for resolving
  Multisite problems. I also serve as general System Administrator, overseeing
  approximately 400 machines in the lab. I help institute policies and
  procedures to keep the network running smoothly. Also participate in the
  design and restructuring the network topology and Clearcase topology by bring
  in many Kittyhawks, Mohawks and Bravehawks (about 40 of them) for use as
  Clearcase Vob, View and Build, Mail, Application, X Terminal and Web servers.
  Assist in documenting setup and configuration as well as trouble shooting and
  handling of patches for all lab wide shared resources.</p> 

  <p>Responsible for setup and running of Windows NT domain, account setup and
  print serving. Setup and evaluated Clearcase 3.2 on NT. Developed backup
  strategy for NT systems. Maintain a repository of software tools as well as
  evaluated and recommended several PC packages for lab usage. Main point of
  contact for Windows 95/NT problem solving in the lab. Also sought after by
  many people in Hewlett Packard relating to both PC and Unix configurations and
  problem solving.</p>

  <p>Also served as webmaster for the lab as well as consult on HTML questions
  and design issues. Installed, configured and maintain the <a href="http://home.netscape.com/">Netscape</a>
  Suitespot Servers including the Enterprise and Directory servers. Developed
  several web pages and forms for the lab as well as run
  <a href="https://web.archive.org/web/20001109171100/http://defaria.com/Quicken">The
  Unofficial Quicken® Web Page.</a></p>

  <p>I developed an Application Server providing many machines with many
  software packages without the need for individual system administration
  utilizing scripting and NFS heavily.</p>

  <p>Prior to the Productivity Project I worked on COBOL/SoftBench product
  which consists of encapsulating some core HP Micro Focus COBOL tools using C++
  3.0 and the SoftBench Encapsulator libraries. Also, working on porting an
  X/Motif application to MS Windows 3.1. The code is written using C++ 3.0 on
  both the HP workstation and the PC (Borland C++ 3.1).</p>

  <p>Worked in the Ada project on Ada/SoftBench. This project was similar to
  COBOL/SoftBench in that it involved some SoftBench encapsulations using a
  language called edl.</p>

  <p>Worked producing Ada Bindings to Xlib, Xt and Motif. This involved using a
  modified C compiler to translate C header and source files to Ada declarations
  and function prototypes. Using this methodology we were able to migrate our
  product from X11 R3 and Motif 1.0 to X11 R4 and Motif 1.1 in one week!</p>

  <p>Worked on a project that produced Ada Bindings to HP-UX, which enabled me
  to get good breath knowledge into all system calls, and another binding to
  Starbase graphical subsystem.</p>

  <p>Performed destructive testing on MPE/XL 1.0-1.3. Wrote several programs to
  stress the OS. Submitted 300+ Service Requests many of which appeared on Must
  Fix lists.</p>

  <hr noshade>

  <h2>Copyright (GPL)</h2>

  <?php start_box ("cs2")?>
    <a name="copyleft"></a>
      <p style="color:#666">This resume is freely available; you can
      redistribute it and/or modify it under the terms of the GNU
      General Public License as published by the Free Software
      Foundation; either version 2 of the License, or (at your option)
      any later version. This means that if you modify this resume you
      must include a copy of the original source or refer to its origin
      at <a href="http://clearscm.com/Resumes/Andrew">http://clearscm.com/Resumes/Andrew</a>.</p>

      <p style="color:#666">This resume is distributed in the hope
      that it will be useful, but WITHOUT ANY WARRANTY; without even
      the implied warranty of MERCHANTABILITY or FITNESS FOR A
      PARTICULAR PURPOSE.  See the GNU General Public License for more
      details.</p>

      <p style="color:#666">You should have received a copy of the GNU
      General Public License along with this resume; if not, write to
      the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
      Boston, MA 02111-1307, USA.</p>
    </font>
  <?php end_box ();?>

  <?php copyright ("1988");?>

<script language="JavaScript" src="/JavaScript/Menus.js" type="text/javascript"></script>

</body>
</html>
