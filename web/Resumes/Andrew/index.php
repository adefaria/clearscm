<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <meta name="GENERATOR" content="Mozilla/4.61 [en] (Win98; U) [Netscape]">
  <title>Andrew DeFaria's Resume</title>
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
menu_css();

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

$resumeHit = fopen('.resumehits', 'w');

fwrite($resumeHit, $count);
fclose($resumeHit);

$resumeHist = fopen('.resume.hist', 'a');
$date = date(DATE_RFC822);

fwrite($resumeHist, "$_SERVER[REMOTE_ADDR] read resume at $date\n");
fclose($resumeHist);

$msg = '<html><body>';
$msg .= '<h1>Somebody just visited your resume.</h1>';
$msg .= "<p>Here's what I know about them:</p>";

$me = false;

foreach ($_SERVER as $key => $value) {
    if (preg_match("/^REMOTE/", $key)) {
        $msg .= "$key: $value<br>";

        if ($key == 'REMOTE_ADDR') {
            // Skip me...
            if ($value == '208.113.131.137') {
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
    $msg .= '</body></html>';

    $headers = "MIME-Version: 1.0\r\n";
    $headers .= "Content-type: text/html; charset=iso-8859-1\r\n";
    $headers .= "From: Resume Reporter <ResumeReporter@DeFaria.com>";

    $subject = "Another resume hit. This makes $count visits to your resume";

    mail("andrew@defaria.com", $subject, $msg, $headers);
} // if
?>
</head>

<body onload="blink()" onunload="stoptimer()" id="homepage">

<!--<?php heading();?>-->

<div id="page">
  <div id="content">
    <?php start_box("cs2")?>
      <h2 align=center><a href="https://defaria.com">Andrew DeFaria</a></h2>
      <address style="text-align:center">
      2010 West San Marcos Blvd Unit 33<br>
      San Marcos, California 92078<br>
      </address>
      <p style="text-align:center">
      Phone: 408-596-4937</a><br>
      Email: <a href="mailto:Andrew@DeFaria.com">Andrew@DeFaria.com</a><br><br>
      <a href="Resume.docx">Download an MS Word copy</a><br>
      For the most up-to-date copy of this resume see <a href="https://defaria.com/resume">https://defaria.com/resume</a>


<!-- <table align="center" width="500">
  <tr>
    <td>
      <marquee behavior="alternate" onmouseover="this.stop()" onmouseout="this.start()"><a id="blink" href="Resume.docx">Download an MS Word copy!</a></marquee><br>
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
      <font size=-1>For the most up-to-date copy of this resume see <a href="https://defaria.com/resume">https://defaria.com/resume</a></font>
      </center>
    </td>
  </tr>
</table> -->
    <?php end_box();?>

    <h2>Certifications and Class Work</h2>

    <table cellspacing="0" cellpadding="0" width="500" border="0" align="center">
      <tbody>
        <tr>
          <td valign="center" align="center">
            <a href="AWS Certified Solutions Architect - Associate certificate.pdf" target="_blank">
              AWS Solutions Architect
            </a>
          </td>
          <td><b>Validation Number:</b> 4Q2XDJDCK1EE1HC5</td>
        </tr>
        <tr>
          <td valign="top" align="center">
            <a href="Docker Certified Associate (DCA).pdf" target="_blank">
              Docker Certified Associate (DCA)
            </a>
          </td>
          <td>Course Completed @ A Cloud Guru</td>
        </tr>
        <tr>
          <td valign="top" align="center">
            <a href="Jenkins Quick Start.pdf" target="_blank">
              Jenkin Quick Start</a>
            </a>
          </td>
          <td>Course Completed @ A Cloud Guru</td>
        </tr>
        <tr>
          <td valign="top" align="center">
            <a href="Jenkins Fundamentals.pdf" target="_blank">
              Jenkin Fundamentals</a>
            </a>
          </td>
          <td>Course Completed @ A Cloud Guru</td>
        </tr>
      </tbody>
    </table>

  <h3>Objective</h3>

  <p>To work with state-of-the-art operating systems and networks to
  ensure the smooth running of an organization's information flow.</p>

  <h3>Hardware</h3>

  <p>Workstations and servers from Sun, HP, Microsoft Windows as well as various
  other manufacturers of Linux systems.</p>

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
          <span class="standout">Git</span>,
          <span class="standout">Perforce</span>,
          <span class="standout">Clearcase</span>
        </td>
      </tr>
      <tr>
        <th>Issue Tracking</th>
        <td>
          <span class="standout">JIRA</span>,
          <span class="standout">Clearquest</span>,
          <span class="standout">Bugzilla</span>
        </td>
      </tr>
      <tr>
        <th>Languages</th>
        <td>
          <span class="standout">Perl</span>,
          <span class="standout">Bash</span>,
          <span class="standout">PHP</span>,
          <span class="standout">C++</span>,
          <span class="standout">C</span>,
          <span class="standout">Ada</span>,
          <span class="standout">TCL</span>
        </td>
      </tr>
      <tr>
        <th>Configuration Management</th>
        <td>
          <span class="standout">Puppet</span>,
          <span class="standout">Ansible</span>
        </td>
      </tr>
      <tr>
        <th>Middleware</th>
        <td>
          <span class="standout">Apache</span>,
          <span class="standout">Tomcat</span>,
          <span class="standout">Samba</span>,
          <span class="standout">Winbind</span>,
          <span class="standout">LDAP</span>,
          <span class="standout">REST</span>
        </td>
      </tr>
      <tr>
        <th>Web Apps</th>
        <td>
          <span class="standout">JIRA</span>,
          <span class="standout">Confluence</span>,
          <span class="standout">Swarm</span>
        </td>
      </tr>
      <tr>
        <th>Databases</th>
        <td>
          <span class="standout">MySQL</span>,
          <span class="standout">Oracle</span>
        </td>
      </tr>
      <tr>
        <th>CI/CD</th>
        <td>
          <span class="standout">Jenkins</span>,
          <span class="standout">Electric Commander</span>
        </td>
      </tr>
      <tr>
        <th>Virtualization</th>
        <td>
          <span class="standout">VMWare</span>,
          <span class="standout">VirtualBox</span>,
          <span class="standout">vSphere</span>,
          <span class="standout">vCenter</span>
        </td>
      </tr>
      <tr>
        <th>Cloud Computing (<span class="standout">Classroom Only</span>)</th>
        <td>
          <span class="standout">EC2</span>,
          <span class="standout">IAM</span>,
          <span class="standout">S3</span>,
          <span class="standout">CloudFront</span>,
          <span class="standout">Route53,
          <span class="standout">VPC</span>,
          <span class="standout">Docker</span>
        </td>
      </tr>
    </tbody>
  </table>

  <h3>Education</h3>

  <p>
    A.A.S. in Computer Science from Union County College in Scotch Plains, New
    Jersey. I continued my studies at Fairleigh Dickenson University,  San Jose State
    University, Mission College, and Chico State in pursuit of my degree.</p>

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

  <h2>ClearSCM, Inc</h2>

  <p><i>July 2007 - Present</i></p>

  <p>During this time I ran a consulting firm specializing in Build Engineering,
  Linux Administration and Version Control Systems. I provided my services to
  many clients like Wells Fargo, General Dynamics, Broadcom, ICANN, and General
  Electric.</p>

  <p>In my contracting roles I've often served as a Perl developer writing scripts
  automating tasks in build systems, test systems as well as complete applications. I
  also served as administrator for various subsystems that today's software businesses
  often emply like Puppet/Ansible, Clearcase/Clearquest, Git, Perforce, Jenkins,
  and JIRA. I'm well versed in Linux administration and even use Linux exclusively
  in my home. I am the kind of guy who will dig into a customers needs and work
  at devising a custom solution to the problem.</p>


  <hr noshade>

  <h2>DeFaria.com</h2>

  <p><i>February 2004 - June 2007</i></p>

  <p>Operating as a 1099 business, I performed consulting services for clients
  like Hewlett Packard, Broadcom, Lynuxworks and Ameriquest. Services included
  Build Release engineering, and Clearcase/Clearquest engineering as well as
  hardening of systems security.</p>

  <hr noshade>

  <h2>Salira</h2>

  <p><i>August 2001 - February 2004</i></p>

  <h3>Clearcase/Clearquest Administrator/Build Engineer</h3>

  <p>After consulting briefly with Salira Optical Network Systems I joined this
  startup company serving in the role of Clearcase/Clearquest Administrator for
  this mostly Windows shop. I helped others in setting up the
  Clearcase/Clearquest environment as well as provided Training.</p>

  <p>I also served in the role of Release Engineer managing the build process.
  I employed wide usage of <a href="http://cygwin.com/">Cygwin</a>, which is a
  product that provides an extremely workable Unix-like environment, and
  engineered a build environment around that using GNU make and other standard
  Unix and GNU utilities. When users complained that building remotely was slow
  I performed an analysis of build performance. I also performed Build Stress
  Testing where I characterized the effect of multiple simultaneous builds
  performed on the server.</p>

  <p>I also set up and developed their Clearquest bug tracking system as well
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

  <h2>Hewlett Packard Company</h2>

  <p><i>February 1988 - November 1998</i></p>

  <h3>Clearcase/Unix Systems Administrator</h3>

  <p>Primary Clearcase and Multisite Administrator for a large Clearcase
  environment with approximately 1400 views and 180 vobs. Most vobs are
  multisited between several other labs and I am responsible for resolving
  Multisite problems. I also serve as general System Administrator, overseeing
  approximately 400 machines in the lab. I help institute policies and
  procedures to keep the network running smoothly. Also participated in the
  design and restructuring of the network topology and Clearcase topology by bringing
  in many Kittyhawks, Mohawks, and Bravehawks (about 40 of them) for use as
  Clearcase Vob, View and Build, Mail, Application, X Terminal, and Web servers.
  Assist in documenting setup and configuration as well as troubleshooting and
  handling of patches for all lab-wide shared resources.</p>

  <p>Responsible for set up and running of Windows NT domain, account setup, and
  print serving. Setup and evaluated Clearcase 3.2 on NT. Developed backup
  strategy for NT systems. Maintain a repository of software tools as well as
  evaluated and recommended several PC packages for lab usage. Main point of
  contact for Windows 95/NT problem-solving in the lab. Also sought after by
  many people in Hewlett Packard relating to both PC and Unix configurations and
  problem solving.</p>

  <p>Also served as webmaster for the lab as well as consulted on HTML questions
  and design issues. Installed, configured, and maintained the <a href="http://home.netscape.com/">Netscape</a>
  Suitespot Servers including the Enterprise and Directory servers. Developed
  several web pages and forms for the lab as well as run
  <a href="https://web.archive.org/web/20001109171100/https://defaria.com/Quicken">The
  Unofficial Quicken® Web Page.</a></p>

  <p>I developed an Application Server providing many machines with many
  software packages without the need for individual system administration
  utilizing scripting and NFS heavily.</p>

  <p>Before the Productivity Project, I worked on the COBOL/SoftBench product
  which consists of encapsulating some core HP Micro Focus COBOL tools using C++
  3.0 and the SoftBench Encapsulator libraries. Also, working on porting an
  X/Motif application to MS Windows 3.1. The code is written using C++ 3.0 on
  both the HP workstation and the PC (Borland C++ 3.1).</p>

  <p>Worked in the Ada project on Ada/SoftBench. This project was similar to
  COBOL/SoftBench in that it involved some SoftBench encapsulations using a
  language called edl.</p>

  <p>Worked producing Ada Bindings to Xlib, Xt, and Motif. This involved using a
  modified C compiler to translate the C header and source files to Ada declarations
  and function prototypes. Using this methodology we were able to migrate our
  product from X11 R3 and Motif 1.0 to X11 R4 and Motif 1.1 in one week!</p>

  <p>Worked on a project that produced Ada Bindings to HP-UX, which enabled me
  to get good breath knowledge into all system calls, and another binding to
  Starbase graphical subsystem.</p>

  <p>Performed destructive testing on MPE/XL 1.0-1.3. Wrote several programs to
  stress the OS. Submitted 300+ Service Requests many of which appeared on Must
  Fix lists.</p>

</body>
</html>
