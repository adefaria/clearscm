#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use Term::ANSIColor qw(:constants);

my $libs;

BEGIN {
  $libs = $ENV{SITE_PERLLIB} ? $ENV{SITE_PERLLIB} : "$FindBin::Bin/../lib";

  die "Unable to find libraries\n" 
    unless -d $libs;
} # BEGIN

use lib $libs;

use Clearcase;
use Display;

my ($status, @output) = $Clearcase::CC->execute ('-ver');

error 'Clearcase is not installed on this system', 1
  if $status;
  
display YELLOW . "Global Clearcase Variables\n" . RESET;

my $view_drive     = $Clearcase::VIEW_DRIVE;
my $vob_mount      = $Clearcase::VOB_MOUNT;
my $win_vob_prefix = $Clearcase::WIN_VOB_PREFIX;
my $vobtag_prefix  = $Clearcase::VOBTAG_PREFIX;
my $countdb        = $Clearcase::COUNTDB;

display MAGENTA . "View Drive:\t\t"       . RESET . $view_drive;
display MAGENTA . "VOB Mount:\t\t"        . RESET . $vob_mount;
display MAGENTA . "Windows VOB prefix:\t" . RESET . $win_vob_prefix;
display MAGENTA . "VOB Tag Prefix:\t\t"   . RESET . $vobtag_prefix;
display MAGENTA . "CountDB:\t\t"          . RESET . $countdb;

display CYAN    . "\nGlobal Clearcase Configuration\n" . RESET;

display MAGENTA . "Client:\t\t\t"       . RESET . $Clearcase::CC->client;
display MAGENTA . "Hardware type:\t\t"  . RESET . $Clearcase::CC->hardware_type;
display MAGENTA . "License host:\t\t"   . RESET . $Clearcase::CC->license_host;
display MAGENTA . "OS:\t\t\t"           . RESET . $Clearcase::CC->os;
display MAGENTA . "Region:\t\t\t"       . RESET . $Clearcase::CC->region;
display MAGENTA . "Registry host:\t\t"  . RESET . $Clearcase::CC->registry_host;
display MAGENTA . "Sitename:\t\t"       . RESET . $Clearcase::CC->sitename;
display MAGENTA . "Version:\t\t"        . RESET . $Clearcase::CC->version;

display GREEN . "\nCleartool Access\n" . RESET;

display_nolf MAGENTA . "Views:\t" . RESET;

($status, @output) = $Clearcase::CC->execute ("lsview -s");

display scalar @output;

display_nolf MAGENTA . "VOBs:\t" . RESET;

($status, @output) = $Clearcase::CC->execute ("lsvob -s");

display scalar @output;

($status, @output) = $Clearcase::CC->execute ("invalid command");

display $_ foreach (@output);
