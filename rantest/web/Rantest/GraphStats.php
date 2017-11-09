<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	GraphStats.php
// Revision:	1.2
// Description:	Produce a graph showing number of tests passed/failed for a
//		date range.
// Author:	Andrew@ClearSCM.com
// Created:	Mon Apr 28 15:20:06 MST 2008
// Modified:	
// Language:	PHP
//
// (c) Copyright 2008, General Dynamics, all rights reserved.
//
// All rights reserved except as subject to DFARS 252.227-7014 of contract
// number CP02H8901N issued under prime contract N00039-04-C-2009.
//
// Warning: This document contains technical data whose export is restricted
// by the Arms Export Control Act (Title 22, U.S.C., Sec 2751, et seq.) or the
// Export Administration Act of 1979, as amended, Title, 50, U.S.C., App. 2401
// et seq. Violations of these export laws are subject to severe criminal
// penalties. Disseminate in accordance with provisions of DoD Directive
// 5230.25.
//
////////////////////////////////////////////////////////////////////////////////
$script = basename ($_SERVER["PHP_SELF"]);
$inc	= $_SERVER["DOCUMENT_ROOT"];

include_once "$inc/php/Utils.php";
include_once "$inc/php/RantestDB.php";

include_once ("$inc/pChart/pData.class");
include_once ("$inc/pChart/pChart.class");

$start	= $_REQUEST["start"];
$end	= $_REQUEST["end"];
$type	= $_REQUEST["type"];

$debug;

function mydebug ($msg) {
  $debug = fopen ("/tmp/debug.log", "a");

  fwrite ($debug, "$msg\n");
} // mydebug

// Sorting functions
function sortByDate ($a, $b) {
  return strcmp ($a["Date"], $b["Date"]);
} // sortByDate

openDB ();

$data = getStatus ($start, $end, $type);

usort ($data, "sortByDate");

$fonts = "$inc/Fonts";

// Dataset definition 
$DataSet = new pData;

foreach ($data as $result) {
  $reportDate = YMD2MDY ($result["Date"]);

//  mydebug ("$reportDate Success $result[Success] Failure $result[Failure]");

  $DataSet->AddPoint ($result["Success"], "Passed",	$reportDate);
  $DataSet->AddPoint ($result["Failure"], "Failed");
} // foreach

$DataSet->AddAllSeries ();
$DataSet->SetAbsciseLabelSerie ();

$DataSet->SetSerieName ("Passed", "Passed");
$DataSet->SetSerieName ("Failed", "Failed");

// Initialise the graph
$Test = new pChart (700, 280);
$Test->drawGraphAreaGradient (100, 150, 175, 100, TARGET_BACKGROUND);
$Test->setFontProperties ("$fonts/tahoma.ttf", 8);
$Test->setGraphArea (50, 30, 680, 200);
$Test->drawRoundedRectangle (5, 5, 695, 275, 5, 230, 230, 230);
$Test->drawGraphAreaGradient (162, 183, 202, 50);
$Test->drawScale ($DataSet->GetData (), $DataSet->GetDataDescription (), SCALE_ADDALL, 200, 200, 200, true, 70, 2, true);
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
$Test->drawTitle (50, 22, "Test Metrics ($type)", 255, 255, 255, 675);
$Test->Stroke ();
