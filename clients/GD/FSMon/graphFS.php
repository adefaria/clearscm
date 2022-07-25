<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	graphFS.php
// Revision:	0.1
// Description:	Produce a graph showing file system sizes
//		date range.
// Author:	Andrew@ClearSCM.com
// Created:	Mon Apr 28 15:20:06 MST 2008
// Modified:	
// Language:	PHP
//
// (c) Copyright 2008, ClearSCM Inc., all rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
$script = basename ($_SERVER["PHP_SELF"]);
//$inc	= $_SERVER["DOCUMENT_ROOT"];
$inc = "/var/www/html/Fsmon";

include_once "$inc/FsmonDB.php";
include_once "$inc/Fsutils.php";

include_once "$inc/pChart/pData.class";
include_once "$inc/pChart/pChart.class";

$system	= $_REQUEST["system"];
$mount	= $_REQUEST["mount"];

$debug;

function mydebug ($msg) {
  $debug = fopen ("/tmp/debug.log", "a");

  fwrite ($debug, "$msg\n");
} // mydebug

function setScaling () {
  if ($_REQUEST["scale"] == "byte") {
    return BYTE;
  } elseif ($_REQUEST["scale"] == "kbyte") {
    return KBYTE;
  } elseif ($_REQUEST["scale"] == "meg") {
    return MEG;
  } else {
    return GIG;
  } // if
} // if

function setPeriod () {
  if ($_REQUEST["period"] == "hourly") {
    return $_REQUEST["period"];
  } elseif ($_REQUEST["period"] == "weekly") {
    return $_REQUEST["period"];
  } elseif ($_REQUEST["period"] == "monthly") {
    return $_REQUEST["period"];
  } else {
    return "daily";
  } // if
} // if

openDB ();

$scaling = setScaling ();
$period  = setPeriod ();

$data	= getFSInfo ($system, $mount, $period);

$fonts	= "$inc/Fonts";

// Dataset definition   
$DataSet = new pData;

$system = "Unknown";
$mount  = "Unknown";

foreach ($data as $result) {
  $system	= $result["sysname"];
  $mount	= $result["mount"];

  // Set X Axis label properly
  if ($period == "hourly") {
    $hours	= substr ($result["timestamp"], 11, 2);
    $minutes	= substr ($result["timestamp"], 14, 2);
    $ampm	= "Am";

    if ($hours > 12) {
      $hours	= $hours - 12;
      $ampm	= "Pm";
    } elseif ($hours < 10) {
      $hours	= substr ($hours, 1, 1);
    } // if

    $Xlabel	= "$hours:$minutes $ampm";
  } elseif ($period == "daily") {
    $day	= substr ($result["timestamp"], 8, 2);
 
    if ($day < 10) {
      $day	= substr ($day, 1, 1);
    } // if
    
    $month	= substr ($result["timestamp"], 5, 2);
 
    if ($month < 10) {
      $month	= substr ($month, 1, 1);
    } // if
    
    $year	= substr ($result["timestamp"], 0, 4);
    $Xlabel	= "$month/$day/$year";
  } elseif ($period == "weekly") {
    $Xlabel	= "Weekly not implemented";
  } elseif ($period == "monthly") {
    $month	= substr ($result["timestamp"], 5, 2);
 
    if ($month < 10) {
      $month	= substr ($month, 1, 1);
    } // if
    
    $year	= substr ($result["timestamp"], 0, 4);
    $Xlabel	= "$month/$year";
  } else {
    $Xlabel	= $result["timestamp"];
  } // if

  $DataSet->AddPoint ($result["used"] / $scaling, "Used", $Xlabel);
  $DataSet->AddPoint ($result["free"] / $scaling, "Free", $Xlabel);
} // foreach

$DataSet->AddAllSeries();
$DataSet->SetAbsciseLabelSerie();

$DataSet->SetXAxisName ("Time");

// Initialise the graph
$Test = new pChart (700, 280);

$Test->setColorPalette (1, 0, 255, 0);
$Test->setColorPalette (0, 255, 0, 0);

$Test->drawGraphAreaGradient (100, 150, 175, 100, TARGET_BACKGROUND);
$Test->setFontProperties ("$fonts/tahoma.ttf", 8);

if ($scaling == BYTE) {
  $Test->setGraphArea (110, 30, 680, 200);
  $DataSet->SetYAxisName ("Bytes");
} elseif ($scaling == KBYTE) {
  $Test->setGraphArea (90, 30, 680, 200);
  $DataSet->SetYAxisName ("Kbytes");
} elseif ($scaling == MEG) {
  $Test->setGraphArea (70, 30, 680, 200);
  $DataSet->SetYAxisName ("Meg");
} else {
  $Test->setGraphArea (55, 30, 680, 200);
  $DataSet->SetYAxisName ("Gig");
} // if  

$Test->drawRoundedRectangle (5, 5, 695, 275, 5, 230, 230, 230);
$Test->drawGraphAreaGradient (162, 183, 202, 50);
$Test->drawScale ($DataSet->GetData (), $DataSet->GetDataDescription (), SCALE_ADDALLSTART0, 200, 200, 200, true, 70, 2, true);
$Test->drawGrid (4, true, 230, 230, 230, 50);

// Draw the 0 line
$Test->setFontProperties ("$fonts/tahoma.ttf", 6);
$Test->drawTreshold (0, 143, 55, 72, true, true);

// Draw the bar graph
$Test->drawStackedBarGraph ($DataSet->GetData (), $DataSet->GetDataDescription (), 75);

// Finish the graph
$Test->setFontProperties ("$fonts/tahoma.ttf",8);
$Test->drawLegend (610, 35, $DataSet->GetDataDescription (), 130, 180, 205);
$Test->setFontProperties ("$fonts/tahoma.ttf", 10);
$Test->drawTitle (50, 22, "$system:$mount ($period)", 255, 255, 255, 675);
$Test->Stroke ();
?>