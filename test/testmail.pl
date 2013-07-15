#!/usr/bin/env cqperl
################################################################################
#
# File:         $RCSfile: testmail.pl,v $
# Revision:	$Revision: 1.1 $
# Description:  Tests Mail.pm
# Author:       Andrew@DeFaria.com
# Created:      Wed Aug  1 09:16:42 MST 2007
# Modified:	$Date: 2007/12/07 05:52:36 $
# Language:     perl
#
# (c) Copyright 2007, ClearSCM, Inc., all rights reserved
#
################################################################################
use strict;
use warnings;

use FindBin;

my $libs;

BEGIN {
  $libs = $ENV{SITE_PERLLIB} ? $ENV{SITE_PERLLIB} : "$FindBin::Bin/../lib";

  die "Unable to find libraries\n" if !$libs;
}

use lib $libs;

use Mail;

my $data = <<END;
<table cellspacing=0 border=1>
  <tbody>
  <tr>
    <td align=center>RANCQ00008837</td>
    <td>Add new VOB to other projects</td>
    <td align=center>NeedingInfo</td>
    <td align=center>p6258c</td>
    <td align=center>p5602c</td>
    <td align=center>2007-07-26 15:19:53</td>
  </tr>
  <tr>
    <td align=center>RANCQ00012317</td>
    <td>RoseRT Crashing</td>
    <td align=center>NeedingInfo</td>
    <td align=center>p6258c</td>
    <td align=center>p29353</td>
    <td align=center>2007-07-18 11:49:57</td>
  </tr>
  <tr>
    <td align=center>RANCQ00012821</td>
    <td>http://ranweb requests</td>
    <td align=center>Verifying</td>
    <td align=center>p6258c</td>
    <td align=center>p6001c</td>
    <td align=center>2007-07-26 15:40:47</td>
  </tr>
  <tr>
    <td align=center>RANCQ00012830</td>
    <td>Not all errors are being reported when doing rebase from UCM GUI.</td>
    <td align=center>NeedingInfo</td>
    <td align=center>p6258c</td>
    <td align=center>p57413</td>
    <td align=center>2007-07-26 11:40:37</td>
  </tr>
  </tbody>
</table>
END

my $footing = <<END;
-- 
Clearquest Team
END

my $heading	= "<h1>Helpdesk Report as of 20070801</h1>";
my $subject	= "Helpdesk Report";
my $to		= "andrew.defaria\@gdc4s.com";

# Main
mail (
  "to"		=> $to,
  "subject"	=> $subject,
  "mode"	=> "html",
  "heading"	=> $heading,
  "footing"	=> $footing,
  "data"	=> $data,
)
