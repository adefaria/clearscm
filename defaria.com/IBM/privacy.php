<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <link rel="stylesheet" type="text/css" media="screen" href="/css/Letter.css">
  <title>IBM</title>
<?php
function logAccess () {
  $timestamp = date ('Y-m-d H:i:s');
  $line = <<<END
Somebody tried to access $_SERVER[REQUEST_URI] on $timestamp

IP Address: $_SERVER[REMOTE_ADDR]
Host:       $_SERVER[REMOTE_HOST]
URL:        $_SERVER[REQUEST_URI]

END;

  $access = fopen ("access.log", "a");

  fwrite ($access, $line);

  fclose ($access);

  return $line;
} // logAccess

function SendNotification () {
  $domain  = "DeFaria.com";
  $to      = "Andrew@DeFaria.com";
  $subject = "Somebody's probing $_SERVER[REQUEST_URI] page";
  $message = logAccess ();

  $extra_headers .= "From: Andrew DeFaria <Andrew@DeFaria.com>\n";

  if (mail ($to, $subject, $message, $extra_headers)) {
    print "
<p>The following information has been logged:</p>

<pre>
$message
</pre>
";
  } // if
} // SendNotification
?>
  <?php include "site-functions.php"?>
</head>

<body>

<p>IBM says that merely knowing the names of some of their employees
is a violation of their privacy and yet their employees post such
information to sites like LinkedIn identifying themselves as employees
of IBM. And it's well know the kinds of conventions companies use when
they compose email addresses for their employees. Common schemes are
&lt;firstname&gt;.&lt;lastname&gt;@&lt;company&gt;.com or sometimes
it's &lt;first initial&gt;&lt;lastname&gt;@&lt;company&gt;.com or even
&lt;firstname&gt;&lt;last initial&gt;@&lt;company&gt;.com. This is
common business practice. Note that IBM has several subdomains and
most US employees are in us.ibm.com. Enterprising people might try
them all.</p>

<p>Here's a small selection I got <b>from publically available web sites</b>:</p>

<table border="1">
  <tr>
    <th>Picture</th>
    <th>What I think of them</th>
    <th>Name</th>
    <th>Title</th>
    <th>Area</th>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=5497896&authType=NAME_SEARCH&authToken=G-_e&locale=en_US&srchid=c408efeb-9c6a-48ef-b31e-78b73a15e3b7-0&srchindex=1&srchtotal=8&goback=%2Efps_PBCK_Naomi+Guerrero_*1_*1_*1_*1_*1_*1_*2_*1_Y_*1_*1_*1_false_1_R_*1_*51_*1_*51_true_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2&pvs=ps&trk=pp_profile_name_link"><img src="http://m.c.lnkd.licdn.com/media/p/2/000/004/3f7/173e16e.jpg"></a></td>
    <td><img src="Dick.jpg" width="200" height="300"></td>
    <td>Naomi Guerrero</td>
    <td>Software Engineer, IBM</td>
    <td>San Francisco Bay Area</td>
  </tr>
  
  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=6714806&authType=NAME_SEARCH&authToken=0WSA&locale=en_US&srchid=df9dc610-1d76-42fd-bfb1-79d70bdb713e-0&srchindex=1&srchtotal=2&goback=%2Efps_PBCK_Ralph+Bosco+IBM_*1_*1_*1_*1_*1_*1_*2_*1_Y_*1_*1_*1_false_1_R_*1_*51_*1_*51_true_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2&pvs=ps&trk=pp_profile_name_link"><img src="http://static.licdn.com/scds/common/u/img/icon/icon_no_photo_60x60.png"></a></td>
    <td><img src="Dick.jpg" width="200" height="300"></td>
    <td>Ralph Bosco</td>
    <td>IT Manager at IBM</td>
    <td>Greater Boston Area</td>
  </tr>  

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=584251&authType=NAME_SEARCH&authToken=PJvM&locale=en_US&srchid=54169611368038570350&srchindex=1&srchtotal=3&trk=vsrp_people_res_name&trkInfo=VSRPsearchId%3A54169611368038570350%2CVSRPtargetId%3A584251%2CVSRPcmpt%3Aprimary"><img src="http://m.c.lnkd.licdn.com/mpr/mpr/shrink_200_200/p/3/000/08c/2cc/274cd46.jpg"></a></td>
    <td><img src="Dick.jpg" width="200" height="300"></td>
    <td>Dennis Griess</td>
    <td>GBS Asset Value Program Manager</td>
    <td>Greater Denver Area</td>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=1305348&authType=NAME_SEARCH&authToken=vG0p&locale=en_US&srchid=338768e1-0482-4651-a1f1-b7fa6894353f-0&srchindex=1&srchtotal=728&goback=%2Efps_PBCK_Denise+Cook_*1_*1_*1_*1_*1_*1_*2_*1_Y_*1_*1_*1_false_1_R_*1_*51_*1_*51_true_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2&pvs=ps&trk=pp_profile_name_link"><img src="http://m.c.lnkd.licdn.com/mpr/mpr/shrink_200_200/p/2/000/0f1/3d7/10c5ef0.jpg"></a></td>
    <td>&nbsp;</td>
    <td>Denise Cook</td>
    <td>JazzHub Technical Lead at IBM Rational</td>
    <td>Greater Denver Area</td>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=780412&authType=NAME_SEARCH&authToken=y1Hh&locale=en_US&srchid=fc9c947a-eaeb-4da4-a5a8-26dce04d07db-0&srchindex=1&srchtotal=1&goback=%2Efps_PBCK_Robin+Bater+IBM_*1_*1_*1_*1_*1_*1_*2_*1_Y_*1_*1_*1_false_1_R_*1_*51_*1_*51_true_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2&pvs=ps&trk=pp_profile_name_link"><img src="http://m.c.lnkd.licdn.com/mpr/mpr/shrink_200_200/p/3/000/08f/391/361484c.jpg"></a></td>
    <td>&nbsp;</td>
    <td>Robin Bater</td>
    <td>Design Factory - JLIP Scenaro Deisgner at IBM Rational Software</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=3093812&locale=en_US&trk=tyah2"><img src="http://static.licdn.com/scds/common/u/img/icon/icon_no_photo_60x60.png"></a></td>
    <td>&nbsp;</td>
    <td>Donna Fortune</td>
    <td>Sr Analytics Developer at IBM Rational Software</td>
    <td>Greater Boston Area</td>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=10478429&locale=en_US&trk=tyah2"><img src="http://m.c.lnkd.licdn.com/mpr/mpr/shrink_200_200/p/2/000/019/02b/09c1703.jpg"></a></td>
    <td>&nbsp;</td>
    <td>Peter Luckey</td>
    <td>IBM / Rational software</td>
    <td>Rochester, New York Area</td>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=12997534&locale=en_US&trk=tyah2"><img src="http://m.c.lnkd.licdn.com/mpr/mpr/shrink_200_200/p/2/000/003/19d/04b914b.jpg"></a></td>
    <td>&nbsp;</td>
    <td>Jason Bennett</td>
    <td>Project Manager at IBM Rational Software
    <td>Greater Boston Area</td>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=16411735&authType=NAME_SEARCH&authToken=v7j6&locale=en_US&srchid=98e078d0-a59a-47b0-a4b8-213641df1b8e-0&srchindex=1&srchtotal=4&goback=%2Efps_PBCK_Jamel+Touati_*1_*1_*1_*1_*1_*1_*2_*1_Y_*1_*1_*1_false_1_R_*1_*51_*1_*51_true_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2&pvs=ps&trk=pp_profile_name_link"><img src="http://static.licdn.com/scds/common/u/img/icon/icon_no_photo_60x60.png"></a></td>
    <td>&nbsp;</td>
    <td>Jamel Touati</td>
    <td>Rational Knowledge Manager | Content & Collaboration | PMP� at IBM Software Group</td>
    <td>Canada</td>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=10657304&authType=NAME_SEARCH&authToken=tFnx&locale=en_US&srchid=6a83b1b8-f2a1-4305-80c3-4d2592594f41-0&srchindex=1&srchtotal=2&goback=%2Efps_PBCK_Jamil+Bissar_*1_*1_*1_*1_*1_*1_*2_*1_Y_*1_*1_*1_false_1_R_*1_*51_*1_*51_true_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2&pvs=ps&trk=pp_profile_name_link"><img src="http://m.c.lnkd.licdn.com/mpr/mpr/shrink_200_200/p/1/000/01b/2ac/02a4b7b.jpg"></a></td>
    <td>&nbsp;</td>
    <td>Jamil Bissar</td>
    <td>Program Director at IBM</td>
    <td>Austin, Texas Area</td>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=16176127&authType=NAME_SEARCH&authToken=yVUS&locale=en_US&srchid=8e137a00-45de-4286-aaf2-97ee28e8b8f8-0&srchindex=1&srchtotal=3&goback=%2Efps_PBCK_Erin+O%27Connor+ibm_*1_*1_*1_*1_*1_*1_*2_*1_Y_*1_*1_*1_false_1_R_*1_*51_*1_*51_true_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2&pvs=ps&trk=pp_profile_name_link"><img src="http://media.licdn.com/mpr/mpr/shrink_60_60/p/3/000/014/23b/2a362ec.jpg"></a></td>
    <td>&nbsp;</td>
    <td>Erin O'Connor</td>
    <td>Project Management Professional at IBM</td>
    <td>Greater Boston Area</td>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=885004&authType=NAME_SEARCH&authToken=6TM-&locale=en_US&srchid=2ef248c0-71e8-41c9-806b-74a2824510ad-0&srchindex=1&srchtotal=4147&goback=%2Efps_PBCK_Karen+Williams_*1_*1_*1_*1_*1_*1_*2_*1_Y_*1_*1_*1_false_1_R_*1_*51_*1_*51_true_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2&pvs=ps&trk=pp_profile_name_link"><img src="http://m.c.lnkd.licdn.com/media/p/3/000/071/029/1e28ebe.jpg"></a></td>
    <td>&nbsp;</td>
    <td>Karen Williams</td>
    <td>Integration Executive, IBM</td>
    <td>Greater Boston Area</td>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=13365771&locale=en_US&trk=tyah2"><img src="http://m.c.lnkd.licdn.com/mpr/mpr/shrink_200_200/p/3/000/0ee/089/1b6f624.jpg"></a></td>
    <td>&nbsp;</td>
    <td>Kim Messina</td>
    <td>Project Manager- Rational PMO at IBM Rational Software</td>
    <td>San Francisco Bay Area</td>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=2356729&locale=en_US&trk=tyah2"><img src="http://static.licdn.com/scds/common/u/img/icon/icon_no_photo_60x60.png"></a></td>
    <td>&nbsp;</td>
    <td>Mary Morton</td>
    <td>Project Manager at IBM. PMP Certified.</td>
    <td>Greater Boston Area</td>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=8826914&authType=NAME_SEARCH&authToken=Ix0D&locale=en_US&srchid=a9c3cd66-2270-4713-9bca-df28395fed0b-0&srchindex=1&srchtotal=130&goback=%2Efps_PBCK_*1_Paula_Cox_*1_*1_*1_*1_*2_*1_Y_*1_*1_*1_false_1_R_*1_*51_*1_*51_true_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2&pvs=ps&trk=pp_profile_name_link"><img src="http://m.c.lnkd.licdn.com/mpr/mpr/shrink_200_200/p/6/000/214/399/28e8fff.jpg"></a></td>
    <td>&nbsp;</td>
    <td>Paula Cox</td>
    <td>Senior Software Engineer with IBM Rational Software</td>
    <td>Raleigh-Durham, North Carolina Area</td>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=3261081&locale=en_US&trk=tyah2"><img src="http://static.licdn.com/scds/common/u/img/icon/icon_no_photo_60x60.png"></a></td>
    <td>&nbsp;</td>
    <td>Sika Sullivan</td>
    <td>Worldwide Business Development Manager, IBM Rational Software</td>
    <td>Greater Boston Area</td>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=1377978&authType=NAME_SEARCH&authToken=Gt8g&locale=en_US&srchid=193fff08-6753-488b-aaf6-7511fb770b51-0&srchindex=1&srchtotal=1&goback=%2Efps_PBCK_Jami+Mitchell+IBM_*1_*1_*1_*1_*1_*1_*2_*1_Y_*1_*1_*1_false_1_R_*1_*51_*1_*51_true_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2&pvs=ps&trk=pp_profile_name_link"><img src="http://static.licdn.com/scds/common/u/img/icon/icon_no_photo_60x60.png"></a></td>
    <td>&nbsp;</td>
    <td>Jami Mitchell</td>
    <td>Premium Support Manager at IBM</td>
    <td>Dallas/Fort Worth Area</td>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=3787832&locale=en_US&trk=tyah2"><img src="http://static.licdn.com/scds/common/u/img/icon/icon_no_photo_60x60.png"></a></td>
    <td>&nbsp;</td>
    <td>Eric Shen</td>
    <td>Manager Market Engineering at IBM Rational</td>
    <td>Greater Boston Area</td>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=40927933&locale=en_US&trk=tyah2"><img src="http://m.c.lnkd.licdn.com/mpr/mpr/shrink_200_200/p/3/000/02c/3e6/246d5e3.jpg"></a></td>
    <td>&nbsp;</td>
    <td>Denise McKinnon</td>
    <td>Knowledge Engineer at IBM Rational</td>
    <td>Greater Boston Are</td>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=20470681&authType=NAME_SEARCH&authToken=_-H0&locale=en_US&srchid=2992e22a-6018-4f96-84a0-484a711eaa12-0&srchindex=1&srchtotal=41&goback=%2Efps_PBCK_Amit+Vaid_*1_*1_*1_*1_*1_*1_*2_*1_Y_*1_*1_*1_false_1_R_*1_*51_*1_*51_true_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2&pvs=ps&trk=pp_profile_name_link"><img src="http://m.c.lnkd.licdn.com/media/p/3/000/011/21a/35c8c31.jpg"></a></td>
    <td>&nbsp;</td>
    <td>Amit Vaid</td>
    <td>Senior Staff Software Engineer at Rational Software</td>
    <td>Gurgaon, India</td>
  </tr>

  <tr>
    <td><a href="http://www.linkedin.com/profile/view?id=2947653&authType=NAME_SEARCH&authToken=9Sr_&locale=en_US&srchid=a85f7697-e6de-4171-8170-afbafdf31983-0&srchindex=1&srchtotal=1&goback=%2Efps_PBCK_Doug+Ishigaki_*1_*1_*1_*1_*1_*1_*2_*1_Y_*1_*1_*1_false_1_R_*1_*51_*1_*51_true_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2_*2&pvs=ps&trk=pp_profile_name_link"><img src="http://m.c.lnkd.licdn.com/media/p/2/000/068/27b/2d00df9.jpg"></a></td>
    <td>&nbsp;</td>
    <td>Doug Ishigaki</td>
    <td>Systems & Software Technical Specialist at IBM Rational</td>
    <td>Orange County, California Area</td>
  </tr>
</table>

<p>IBM seems to be telling me that I am not allowed to open up a
"phone book" and read it! Sorry IBM, but you are not the government
and you don't make privacy law. Even the law goes by
"<a href="http://en.wikipedia.org/wiki/Expectation_of_privacy">expectation
of privacy</a>" and it seems clear to me that if you're posting your
mug to publically available web sites along with your affiliation with
IBM then you should have no expectation of privacy that your name,
often your picture, and your employer are somehow "private".</p>

<p>I draw your attention to the Wikipedia article under the heading
of <a href="http://en.wikipedia.org/wiki/Privacy_law#United_States">United
States</a> which states that:</p>

<blockquote>
  <p>... the renowned tort expert Dean Prosser argued that "privacy"
  was composed of four separate torts, the only unifying element of
  which was a (vague) "right to be left alone."[8] These torts were</p>

  <ol>
    <li>appropriating the plaintiff's identity for the defendant's
    benefit<br><font color="#999">That ain't happening
    here</font></li>

    <li>placing the plaintiff in a false light in the public eye<br>
    <font color="#999">I'm not placing anybody in any false
    light</font></li>

    <li>publicly disclosing private facts about the plaintiff<br>
    <font color="#999">Seems clear to me that these are not private
    facts</font></li>

    <li>unreasonably intruding upon the seclusion or solitude of the plaintiff<br>
    <font color="#999">If the plaintiff wants seclusion or solitude
    then they shouldn't be rummaging around on my site!</font></li>
  </ol>
</blockquote>

</table>

<?php copyright ();?>
<?php SendNotification ();?>

</body>
</html>
