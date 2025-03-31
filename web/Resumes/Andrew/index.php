<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>

<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <meta name="GENERATOR" content="Mozilla/4.61 [en] (Win98; U) [Netscape]">
  <title>Andrew DeFaria's Resume</title>
  <link rel="stylesheet" type="text/css" media="screen" href="Article.css">
  <link rel="stylesheet" type="text/css" media="print" href="Print.css">
  <link rel="SHORTCUT ICON" href="http://clearscm.com/favicon.ico" type="image/png">

  <script type="text/javascript">
    function blink() {
      if (!document.getElementById('blink').style.color) {
        document.getElementById('blink').style.color = "white";
      } // if

      if (document.getElementById('blink').style.color == "white") {
        document.getElementById('blink').style.color = "red";
      } else {
        document.getElementById('blink').style.color = "white";
      } // if

      timer = setTimeout("blink()", 450);
    } // blink

    function stoptimer() {
      clearTimeout(timer);
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
  $myip = '75.80.5.95';

  foreach ($_SERVER as $key => $value) {
    if (preg_match("/^REMOTE/", $key) || preg_match("/^HTTP_USER_AGENT/", $key)) {
      $msg .= "$key: $value<br>";

      if ($key == 'REMOTE_ADDR') {
        // Skip me...
        if ($value == $myip) {
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

<body>
  <div id="content">
    <?php start_box("cs5") ?>
    <h2 align=center><a href="https://defaria.com">Andrew DeFaria</a></h2>
    <address style="text-align:center">
      San Marcos, California 92078<br>
    </address>
    <p style="text-align:center; font-size: 10pt">
      408-596-4937 <a href="mailto:Andrew@DeFaria.com">Andrew@DeFaria.com</a><br>
      Download an <a href="Resume.docx">MS Word copy of this resume</a></p>
    <?php end_box(); ?>

    <h2>PROFESSIONAL SUMMARY</h2>
    <hr noshade>

    <p>Seeking a position in IT operations and network management to leverage over 20 years of expertise
      in state-of-the-art operating systems and networks, ensuring seamless information flow and system
      performance. Open to remote work or hybrid roles in the San Marcos, CA area.</p>

    <h2>SKILLS</h2>
    <hr noshade>

    <table cellspacing="0" cellpadding="3" border="1" align="center">
      <tbody>
        <tr>
          <td><span class="standout">Hardware</span>
            Workstations and servers from Sun, HP, Microsoft Windows, various manufacturers of Linux systems
          </td>
          <td><span class="standout">Operating Systems</span>
            Linux (Redhat, Centos, Ubuntu), Windows, Unix (Solaris, HP-UX), Cygwin
          </td>
          <td><span class="standout">Networking</span>
            TCP/IP, Windows & Unix Networking, Active Directory/LDAP, Samba
          </td>
        </tr>

        <tr>
          <td><span class="standout">Version Control</span>
            Git, Perforce, Clearcase
          </td>
          <td><span class="standout">Issue Tracking</span>
            JIRA, Clearquest, Bugzilla
          </td>
          <td><span class="standout">Software Languages</span>
            Perl, Bash, PHP, C++, C, Ada, TCL
          </td>
        </tr>

        <tr>
          <td><span class="standout">Configuration Management</span>
            Puppet, Ansible
          </td>
          <td><span class="standout">Middleware</span>
            Apache, Tomcat, Samba, Winbind, LDAP, REST
          </td>
          <td><span class="standout">Web Apps</span>
            JIRA, Confluence, Swarm
          </td>
        </tr>

        <tr>
          <td><span class="standout">Databases</span>
            MySQL, Oracle
          </td>
          <td><span class="standout">CI/CD</span>
            Jenkins, Electric Commander
          </td>
          <td><span class="standout">Virtualization</span>
            VMWare, VirtualBox, vSphere, vCenter
          </td>
        </tr>

        <tr>
          <td><span class="standout">Cloud Computing (Classroom Only)</span>
            EC2, IAM, S3, CloudFront, Route53, VPC, Docker
          </td>
          <td>&nbsp;</td>
          <td>&nbsp;</td>
        </tr>

      </tbody>
    </table>

    <h2>EXPERIENCE</h2>
    <hr noshade>

    <h3>Perl Developer | October 2021 - Current <br>Cpanel/WebPros | CA</h3>

    <ul>
      <li>Worked on the Artemis Team, improving WHM and learning Cpanel's extensive code base</li>
      <li>Transitioned to the Release Team, focusing on bug fixes and release tasks</li>
      <li>Contributed to the WordPress Squared team, enhancing backend functionality with bug fixes and improvements
      </li>
      <li>Conducted quality assurance and integration testing for project readiness</li>
      <li>Developed software applications to enhance client satisfaction and user experience</li>
    </ul>

    <h3>Engineer Consultant | July 2007 - September 2021<br>ClearSCM, Inc | CA</h3>

    <ul>
      <li>Ran a consulting firm specializing in Build Engineering, Linux Administration and Version Control Systems</li>
      <li>Provided services to many clients like Wells Fargo, General Dynamics, Broadcom, ICANN, and General Electric
      </li>
      <li>Served as a Perl developer writing scripts automating tasks in build systems, test systems, and complete
        applications</li>
      <li>Administered subsystems like Puppet/Ansible, Clearcase/Clearquest, Git, Perforce, Jenkins, and JIRA</li>
      <li>Specialized in Linux administration</li>
    </ul>

    <h3>Clearcase/Clearquest Administrator | Februaray 2004 - June 2007<br>DeFaria.com | CA</h3>

    <ul>
      <li>Consulted for clients including Hewlett Packard, Broadcom, Lynuxworks, and Ameriquest</li>
      <li>Specialized in Build Release engineering, Clearcase/Clearquest engineering, and system security hardening</li>
      <li>Addressed customer inquiries and resolved issues promptly</li>
      <li>Collaborated with IT department to troubleshoot technical issues with office equipment and software</li>
    </ul>

    <h3>Clearcase?Clearquest Administrator/Build Engineer | August 2001 - February 2004<br>Salira | CA</h3>

    <ul>
      <li>Joined Salira Optical Network Systems as a Clearcase/Clearquest Administrator</li>
      <li>Setup environment, provided training, and managed the build process as Release Engineer</li>
      <li>Developed Clearquest Daemon, automation scripts, and conducted Build Stress Testing</li>
      <li>Designed and implemented Clearquest bug tracking system</li>
      <li>Advised on Clearcase issues, branching strategies, labeling, and release management</li>
      <li>Implemented Clearquest Daemon for web page and trigger interactions</li>
    </ul>

    <h3>Clearcase/Unix Systems Administrator | February 1998 - August 2001<br>Hewlett Packard Company | CA</h3>

    <ul>
      <li>Primary Clearcase and Multisite Administrator for a large environment with 1400 views and 180 vobs</li>
      <li>Assisted in network and Clearcase topology design, setup, and maintenance</li>
      <li>Managed Netscape Suitespot Servers for 400 machines, developed lab web pages, and restructured network
        topology. Documented setups, troubleshooting, and patch handling for shared resources</li>
      <li>Managed Windows NT domain, account setup, print serving, and evaluated Clearcase 3.2 on NT</li>
      <li>Developed NT backup strategy and maintained software tool repository</li>
      <li>Main contact for Windows 95/NT problem-solving; consulted on PC and Unix issues</li>
      <li>Served as lab webmaster, installed, configured, and maintained Netscape Servers, and ran The Unofficial
        Quicken Web Page</li>
      <li>Developed an Application Server for software distribution using scripting and NFS</li>
      <li>Worked on COBOL/SoftBench and Ada/SoftBench projects, porting applications and producing Ada bindings to Xlib,
        Xt, Motif, and HP-UX</li>
      <li>Conducted destructive testing on MPE/XL, submitting 300+ Service Requests, many on Must Fix lists</li>
    </ul>

    <h2>Education</h2>
    <hr noshade>

    <h3>Associate in Applied Science (A.A.S) - Computer Science</h3>
    <p>Union County College, Scotch Plains, New Jersey</p>

    <ul>
      <li>Continued studies at Fairleigh Dickenson University, San Jose State University, Mission College, and Chico
        State</li>
    </ul>

    <h2>Certifications and Class Work</h2>
    <hr noshade>

    <ul>
      <li><a href="AWS%20Certified%20Solutions%20Architect%20-%20Associate%20certificate.pdf" target="_blank">AWS
          Solutions Architect</a>: Validation Number: 4Q2XDJDCK1EE1HC5</li>
      <li><a href="Docker Certified Associate (DCA).pdf">Docker Certified Associate (DCA)</a>: Course Completed @ A
        Cloud Guru</li>
      <li><a href="Jenkins Quick Start.pdf">Jenkins Quick Start</a>: Course Completed @ A Cloud Guru</li>
      <li><a href="Jenkins Fundamentals.pdf">Jenkins Fundamentals</a>: Course Completed @ A Cloud Guru</li>
    </ul>
  </div>
</body>

</html>