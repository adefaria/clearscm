<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:        $RCSfile: scm.php,v $
// Revision:    $Revision: 1.0 $
// Description: SCM routines
// Author:      Andrew@DeFaria.com
// Created:     Thu Oct 10 16:29:35 PDT 2013
// Modified:    $Date: $
// Language:    Php
//
// (c) Copyright 2013, ClearSCM Inc., all rights reserved
//
////////////////////////////////////////////////////////////////////////////////
function getSCMFile ($file) {
  $url = "http://clearscm.com/gitweb/?p=clearscm.git;a=blob_plain;f=$file;hb=HEAD";

  $contents = @file ($url)
    or die ("$url not found");

  return $contents;
} // getSCMFile
?>
