<?php
$inc = "/var/www/html/Fsmon";

include_once ("$inc/pChart/pData.class");
include_once ("$inc/pChart/pChart.class");

$fonts = "$inc/Fonts";

// Dataset definition   
$DataSet = new pData;

// Free first
// $DataSet->AddPoint (0, "Free", 1);
// $DataSet->AddPoint (0, "Used", 1);
// $DataSet->AddPoint (70, "Free", 2);
// $DataSet->AddPoint (30, "Used", 2);
// $DataSet->AddPoint (80, "Free", 3);
// $DataSet->AddPoint (20, "Used", 3);
// $DataSet->AddPoint (90, "Free", 4);
// $DataSet->AddPoint (10, "Used", 4);

// Used first
$DataSet->AddPoint (0, "Used", 1);
$DataSet->AddPoint (70, "Used", 2);
$DataSet->AddPoint (80, "Used", 3);
$DataSet->AddPoint (90, "Used", 4);
$DataSet->AddPoint (0, "Free", 1);
$DataSet->AddPoint (30, "Free", 2);
$DataSet->AddPoint (20, "Free", 3);
$DataSet->AddPoint (10, "Free", 4);

$DataSet->AddAllSeries();
$DataSet->SetAbsciseLabelSerie();

// Initialise the graph
$Test = new pChart (700, 280);

$Test->setColorPalette (1, 0, 255, 0);
$Test->setColorPalette (0, 255, 0, 0);

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
$Test->drawTitle (50, 22, "$system:$mount", 255, 255, 255, 675);
$Test->Stroke ();
?>