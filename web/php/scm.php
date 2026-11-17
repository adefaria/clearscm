<?php
////////////////////////////////////////////////////////////////////////////////
//
// File:        $RCSfile: scm.php,v $
// Revision:    $Revision: 1.1 $
// Description: SCM routines
// Author:      Andrew@DeFaria.com
// Created:     Thu Oct 10 16:29:35 PDT 2013
// Modified:    $Date: $
// Language:    Php
//
// (c) Copyright 2013, ClearSCM Inc., all rights reserved
//
////////////////////////////////////////////////////////////////////////////////

function resolveSCMFilePath ($file) {
  $file = ltrim ((string)$file, '/');
  if ($file === '' || strpos ($file, '..') !== false) {
    return false;
  }

  $candidates = array (
    "/opt/clearscm/$file",
    "/opt/clearscm/Clearcase/$file",
    "/opt/clearscm/Clearquest/$file",
    "/opt/clearscm/Term-CmdLine/$file",
  );

  $scm_root = realpath ('/opt/clearscm');
  foreach ($candidates as $candidate) {
    if (is_file ($candidate) && is_readable ($candidate)) {
      $real = realpath ($candidate);
      if ($real !== false && strpos ($real, $scm_root . '/') === 0) {
        return $real;
      }
    }
  }

  return false;
} // resolveSCMFilePath

function resolveSCMGitRelPath ($file) {
  $real = resolveSCMFilePath ($file);
  if (!$real) {
    return ltrim ((string)$file, '/');
  }
  $scm_root = realpath ('/opt/clearscm') . '/';
  if (strpos ($real, $scm_root) === 0) {
    return substr ($real, strlen ($scm_root));
  }
  return ltrim ((string)$file, '/');
} // resolveSCMGitRelPath

function getSCMFile ($file) {
  $path = resolveSCMFilePath ($file);
  if (!$path) {
    die (htmlspecialchars ($file) . " not found");
  }

  $contents = @file ($path)
    or die ("Unable to read " . htmlspecialchars ($file));

  return $contents;
} // getSCMFile
?>
