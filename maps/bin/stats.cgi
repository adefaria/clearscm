#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: stats.cgi,v $
# Revision:     $Revision: 1.1 $
# Description:  This script produces a table of statistics of mail processed for
#               the user.
# Author:       Andrew@DeFaria.com
# Created:      Fri Nov 29 14:17:21  2002
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     perl
#
# (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;
use warnings;

use FindBin;
$0 = $FindBin::Script;

use lib "$FindBin::Bin/../lib";

use MAPS;
use MAPSLog;
use MAPSUtil;
use MAPSWeb;

use CGI qw (:standard *table start_Tr end_Tr);
use CGI::Carp 'fatalsToBrowser';

my $nbr_days = param('nbr_days');
my $date     = param('date');

my $table_name = 'stats';

$date = defined $date ? $date : Today2SQLDatetime;

sub Body {
  print start_table ({-align       => 'center',
                      -id          => $table_name,
                      -border      => 0,
                      -cellspacing => 0,
                      -cellpadding => 2,
                      -cols        => 9,
                      -width       => '100%'});
  print start_Tr {-valign => 'bottom'};
  print th {-class => 'tableleftend'}, 'Date';

  for (@Types) {
    print th {-class => 'tableheader'}, ucfirst;
  } # for

  print th {-class => 'tablerightend'}, 'Total';

  my %dates = GetStats($nbr_days, $date);
  my %totals;

  for my $date (sort {$b cmp $a} (keys (%dates))) {
    print start_Tr;
    print td {-class => 'tablerightleftdata',
              -align => 'center'}, FormatDate $date;

    my $day_total = 0;

    for (@Types) {
      my $value = $dates{$date}{$_};
      if ($value == 0) {
        print td {-class => 'tabledata'}, '&nbsp;';
      } else {
        print td {-class => 'tabledata',
                  -align => 'center'},
              a {-href => "detail.cgi?type=$_;date=$date"},
                 $value;
      } # if
      $totals{$_} += $value;
      $day_total  += $value;
    } # for

    if ($day_total == 0) {
      print td {-class => 'tableleftrightdata'}, '&nbsp;';
    } else {
      print td {-class => 'tableleftrightdata',
                -align => 'center'}, $day_total;
    } # if

    print end_Tr;
  } # for

  my $grand_total = 0;

  print start_Tr;
  print th {-class	=> 'tablebottomlefttotal'}, 'Totals';

  for (@Types) {
    if ($totals{$_} eq 0) {
      print td {-class	=> 'tablebottomtotal'}, '&nbsp;';
    } else {
      print td {-class => 'tablebottomtotal',
                -align => 'center'},
            a {-href => "detail.cgi?type=$_"}, $totals{$_};
    } # if

    $grand_total += $totals{$_};
  } # for

  print td {-class => 'tablebottomrighttotal',
            -align => 'center'}, $grand_total;

  print end_Tr;
  print end_table;
} # Body

# Main
my $userid = Heading (
  'getcookie',
  '',
  'Statistics',
  'Statistics',
  '',
  $table_name
);

SetContext($userid);

if (!$nbr_days) {
  my %options = GetUserOptions $userid;
  $nbr_days = $options{Dates};
} # if

NavigationBar($userid);

Body;

Footing($table_name);

exit;
