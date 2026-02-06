<?php
// Hit Counter Logic
$dir = dirname(__FILE__);
if (file_exists("$dir/.resumehits")) {
  $resumeHit = fopen("$dir/.resumehits", 'r');
  fscanf($resumeHit, "%d\n", $count);
  fclose($resumeHit);
} else {
  $count = 0;
}

$count++;
$resumeHit = fopen("$dir/.resumehits", 'w');
fwrite($resumeHit, $count);
fclose($resumeHit);

$resumeHist = fopen("$dir/.resume.hist", 'a');
$date = date(DATE_RFC822);
fwrite($resumeHist, "$_SERVER[REMOTE_ADDR] read resume at $date\n");
fclose($resumeHist);

// Email notification logic (simplified/commented as in original)
$me = false;
$myip = '75.80.5.95'; // Legacy IP?

// Original logic was here... keeping it minimal or preserving if actually used.
// For now, retaining the logic flow but cleaning up the HTML output part.

$page_title = "Resume";
$header_path = $_SERVER['DOCUMENT_ROOT'] . '/includes/frame_header.php';
if (!file_exists($header_path)) {
  // Fallback if DOCUMENT_ROOT is not what we expect
  $header_path = __DIR__ . '/../../includes/frame_header.php';
}

if (file_exists($header_path)) {
  require $header_path;
}
?>

<style>
  /* Core Variables Fallback (in case style.css fails) */
  :root {
    --bg-color: #121212;
    --surface-color: #1e1e1e;
    --primary-color: #bb86fc;
    --secondary-color: #03dac6;
    --text-color: #e0e0e0;
    --muted-color: #a0a0a0;
    --google-blue: rgb(66, 133, 244);
    --google-red: rgb(234, 67, 53);
    --google-yellow: rgb(251, 188, 5);
    --google-green: rgb(52, 168, 83);
    --google-purple: rgb(161, 66, 244);
    --font-heading: 'Outfit', sans-serif;
  }

  [data-theme="light"] {
    --bg-color: #ffffff;
    --surface-color: #f5f5f5;
    --text-color: #121212;
    --muted-color: #5f6368;
  }

  /* Resume Specific Styling */
  .resume-container {
    max-width: 900px;
    margin: 0 auto;
    background-color: var(--surface-color);
    padding: 2rem;
    border-radius: 16px;
    border: 1px solid rgba(255, 255, 255, 0.05);
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    color: var(--text-color);
  }

  /* Force all text inside to inherit color unless specified */
  .resume-container * {
    color: inherit;
  }

  .resume-container h2,
  .resume-container h3,
  .resume-container a,
  .resume-container .standout {
    /* Re-apply specific colors as they are overridden by * selector */
  }

  h2 {
    color: var(--google-blue) !important;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    padding-bottom: 0.5rem;
    margin-top: 2rem;
    font-family: var(--font-heading);
    text-transform: uppercase;
    font-size: 1.5rem;
  }

  h3 {
    color: var(--google-red) !important;
    margin-top: 1.5rem;
    margin-bottom: 0.5rem;
    font-size: 1.2rem;
  }

  table {
    width: 100%;
    border-collapse: collapse;
    margin: 1rem 0;
  }

  td {
    border: 1px solid rgba(255, 255, 255, 0.1);
    padding: 10px;
    vertical-align: top;
  }

  .standout {
    color: var(--google-green) !important;
    font-weight: bold;
    display: block;
    margin-bottom: 4px;
  }

  ul {
    margin-top: 0.5rem;
  }

  li {
    margin-bottom: 0.5rem;
    color: var(--text-color);
  }

  a {
    color: var(--google-blue) !important;
  }

  a:hover {
    text-decoration: underline;
  }

  /* Header adjustments */
  .resume-header {
    text-align: center;
    margin-bottom: 2rem;
    border-bottom: 1px solid var(--muted-color);
    padding-bottom: 1rem;
  }

  .resume-header h2 {
    margin-bottom: 0.2rem;
    line-height: 1.2;
    font-family: var(--font-fancy);
    font-size: 3rem;
    font-weight: 700;
    text-transform: none;
    /* Script font looks better normal case */
  }

  .resume-header h2 a {
    color: var(--google-blue);
  }

  .resume-header p {
    font-size: 1.1rem;
    margin-top: 0;
    /* Removing top margin to tighten */
    line-height: 1.4;
  }

  .download-link {
    display: inline-block;
    margin-top: 5px;
    /* Reduced from 10px */
    padding: 8px 16px;
    /* Removed background/border to make it look more like a link if desired, 
       but user just said Make it red and bold. 
       Let's keep the pill shape but make it standout red. */
    background: rgba(234, 67, 53, 0.1);
    /* Light red bg */
    border: 1px solid var(--google-red);
    border-radius: 20px;
    font-size: 1rem;
    /* Larger */
    /* Bold removed */
    text-decoration: none;
    color: var(--google-red) !important;
    /* Red */
  }

  .download-link:hover {
    background: var(--google-red);
    color: white !important;
    text-decoration: none;
  }
</style>

<div class="resume-container">
  <div class="resume-header">
    <h2><a href="https://defaria.com" style="text-decoration:none; color:inherit;">Andrew DeFaria</a></h2>
    <p>
      <a href="tel:4085964937" style="text-decoration:none; color:inherit;">(408) 596-4937</a> &bull; <a
        href="mailto:Andrew@DeFaria.com">Andrew@DeFaria.com</a><br>
      <a href="Resume.docx" class="download-link">Download MS Word copy</a>
    </p>
  </div>

  <h2>Professional Summary</h2>
  <p>Seeking a position in IT operations and network management to leverage over 20 years of expertise
    in state-of-the-art operating systems and networks, ensuring seamless information flow and system
    performance. Open to remote work or hybrid roles in the San Diego area.</p>

  <h2>Skills</h2>

  <table cellspacing="0" cellpadding="3">
    <tbody>
      <tr>
        <td width="33%"><span class="standout">Hardware</span>
          Workstations and servers from Sun, HP, Microsoft Windows, various manufacturers of Linux systems
        </td>
        <td width="33%"><span class="standout">Operating Systems</span>
          Linux (Redhat, Centos, Ubuntu), Windows, Unix (Solaris, HP-UX), Cygwin
        </td>
        <td width="33%"><span class="standout">Networking</span>
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
        <td><span class="standout">Cloud Computing</span> (Classroom Only)
          EC2, IAM, S3, CloudFront, Route53, VPC, Docker
        </td>
        <td>&nbsp;</td>
        <td>&nbsp;</td>
      </tr>

    </tbody>
  </table>

  <h2>Experience</h2>

  <h3>Perl Developer | October 2021 - Current <br><span
      style="font-size:0.9em; color:var(--muted-color);">Cpanel/WebPros | CA</span></h3>
  <ul>
    <li>Worked on the Artemis Team, improving WHM and learning Cpanel's extensive code base</li>
    <li>Transitioned to the Release Team, focusing on bug fixes and release tasks</li>
    <li>Contributed to the WordPress Squared team, enhancing backend functionality with bug fixes and improvements</li>
    <li>Conducted quality assurance and integration testing for project readiness</li>
    <li>Developed software applications to enhance client satisfaction and user experience</li>
  </ul>

  <h3>Engineer Consultant | July 2007 - September 2021<br><span
      style="font-size:0.9em; color:var(--muted-color);">ClearSCM, Inc | CA</span></h3>
  <ul>
    <li>Ran a consulting firm specializing in Build Engineering, Linux Administration and Version Control Systems</li>
    <li>Provided services to many clients like Wells Fargo, General Dynamics, Broadcom, ICANN, and General Electric</li>
    <li>Served as a Perl developer writing scripts automating tasks in build systems, test systems, and complete
      applications</li>
    <li>Administered subsystems like Puppet/Ansible, Clearcase/Clearquest, Git, Perforce, Jenkins, and JIRA</li>
    <li>Specialized in Linux administration</li>
  </ul>

  <h3>Clearcase/Clearquest Administrator | February 2004 - June 2007<br><span
      style="font-size:0.9em; color:var(--muted-color);">DeFaria.com | CA</span></h3>
  <ul>
    <li>Consulted for clients including Hewlett Packard, Broadcom, Lynuxworks, and Ameriquest</li>
    <li>Specialized in Build Release engineering, Clearcase/Clearquest engineering, and system security hardening</li>
    <li>Addressed customer inquiries and resolved issues promptly</li>
    <li>Collaborated with IT department to troubleshoot technical issues with office equipment and software</li>
  </ul>

  <h3>Clearcase/Clearquest Administrator/Build Engineer | August 2001 - February 2004<br><span
      style="font-size:0.9em; color:var(--muted-color);">Salira | CA</span></h3>
  <ul>
    <li>Joined Salira Optical Network Systems as a Clearcase/Clearquest Administrator</li>
    <li>Set up environment, provided training, and managed the build process as Release Engineer</li>
    <li>Developed Clearquest Daemon, automation scripts, and conducted Build Stress Testing</li>
    <li>Designed and implemented Clearquest bug tracking system</li>
    <li>Advised on Clearcase issues, branching strategies, labeling, and release management</li>
    <li>Implemented Clearquest Daemon for web page and trigger interactions</li>
  </ul>

  <h3>Clearcase/Unix Systems Administrator | February 1998 - August 2001<br><span
      style="font-size:0.9em; color:var(--muted-color);">Hewlett Packard Company | CA</span></h3>
  <ul>
    <li>Primary Clearcase and Multisite Administrator for a large environment with 1400 views and 180 vobs</li>
    <li>Assisted in network and Clearcase topology design, setup, and maintenance</li>
    <li>Managed Netscape Suitespot Servers for 400 machines, developed lab web pages, and restructured network topology.
      Documented setups, troubleshooting, and patch handling for shared resources</li>
    <li>Managed Windows NT domain, account setup, print serving, and evaluated Clearcase 3.2 on NT</li>
    <li>Developed NT backup strategy and maintained software tool repository</li>
    <li>Main contact for Windows 95/NT problem-solving; consulted on PC and Unix issues</li>
    <li>Served as lab webmaster, installed, configured, and maintained Netscape Servers, and ran The Unofficial Quicken
      Web Page</li>
    <li>Developed an Application Server for software distribution using scripting and NFS</li>
    <li>Worked on COBOL/SoftBench and Ada/SoftBench projects, porting applications and producing Ada bindings to Xlib,
      Xt, Motif, and HP-UX</li>
    <li>Conducted destructive testing on MPE/XL, submitting 300+ Service Requests, many on Must Fix lists</li>
  </ul>

  <h2>Education</h2>
  <h3>Associate in Applied Science (A.A.S) - Computer Science</h3>
  <p>Union County College, Scotch Plains, New Jersey</p>
  <ul>
    <li>Continued studies at Fairleigh Dickenson University, San Jose State University, Mission College, and Chico State
    </li>
  </ul>

  <h2>Certifications and Class Work</h2>
  <ul>
    <li><a href="AWS%20Certified%20Solutions%20Architect%20-%20Associate%20certificate.pdf" target="_blank">AWS
        Solutions Architect</a>: Validation Number: 4Q2XDJDCK1EE1HC5</li>
    <li><a href="Docker Certified Associate (DCA).pdf">Docker Certified Associate (DCA)</a>: Course Completed @ A Cloud
      Guru</li>
    <li><a href="Jenkins Quick Start.pdf">Jenkins Quick Start</a>: Course Completed @ A Cloud Guru</li>
    <li><a href="Jenkins Fundamentals.pdf">Jenkins Fundamentals</a>: Course Completed @ A Cloud Guru</li>
  </ul>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
</body>

</html>