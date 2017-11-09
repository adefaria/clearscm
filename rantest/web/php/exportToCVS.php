<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:	exportToCVS.php
// Description:	Exports a table to CVS
// Author:	Andrew@ClearSCm.com
// Created:	Mon Apr 28 15:20:06 MST 2008
// Modified:	
// Language:	PHP
//
// (c) Copyright 2000-2008, General Dynamics, all rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
function exportToCSV ($filename, $data) {
  header ("Content-Type: application/octect-stream");
  header ("Content-Disposition: attachment; filename=$filename");

  foreach ($data as $line) {
    foreach ($line as $key => $value) {
      if (!$first_time) {
	print ",\"$value\"";
      } else {
	print "\"$value\"";
      } // if
    } // foreach
  } // foreach
} // exportToCSV
