#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: add2nulllist.cgi,v $
# Revision:        $Revision: 1.1 $
# Description:        Add an email address to the nulllist
# Author:       Andrew@DeFaria.com
# Created:      Mon Jan 16 20:25:32 PST 2006
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     Perl
#
# (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;
use warnings;

use FindBin;
$0 = $FindBin::Script;

use lib $FindBin::Bin;

use MAPS;
use MAPSLog;
use MAPSWeb;

use CGI qw/:standard *table/;
use CGI::Carp 'fatalsToBrowser';

my $userid;
my $Userid;
my $type = 'null';

sub Add2List {
  my $sender   = '';
  my $nextseq  = MAPSDB::GetNextSequenceNo $userid, $type;

  while () {
    my $pattern   = param "pattern$nextseq";
    my $domain    = param "domain$nextseq";
    my $comment   = param "comment$nextseq";
    my $hit_count = param "hit_count$nextseq";

    last if ((!defined $pattern || $pattern eq '') &&
              (!defined $domain || $domain  eq ''));

    $sender = lc "$pattern\@$domain";

    my ($status, $rule) = OnNulllist $sender;

    if ($status != 0) {
      print br {-class => 'error'}, "The email address $sender is already on ${Userid}'s $type list";
    } else {
      $hit_count ||= CountMsg $sender;

      Add2Nulllist $sender, $userid, $comment, $hit_count;

      print br "The email address, $sender, has been added to ${Userid}'s $type list";

      # Now remove this entry from the other lists (if present)
      foreach my $otherlist ('white', 'black') {
        my $sth = FindList $otherlist, $sender;
        my ($sequence, $count);

        ($_, $_, $_, $_, $_, $sequence) = GetList $sth;

        if ($sequence) {
          $count = DeleteList $otherlist, $sequence;

          print br "Removed $sender from ${Userid}'s " . ucfirst $otherlist . ' list'
            if $count > 0;

          ResequenceList $userid, $otherlist;
        } # if
      } # foreach
    } # if

    $nextseq++;
  } # while
} # Add2List

# Main
$userid = Heading (
  'getcookie',
  '',
  'Add to Null List',
  'Add to Null List',
);

SetContext $userid;

NavigationBar $userid;

$Userid = ucfirst $userid;

Add2List;

print start_form {
  -method        => 'post',
  -action        => 'processaction.cgi',
  -name          => 'list'
};

print '<p></p><center>',
  hidden ({-name        => 'type',
           -default     => $type}),
  submit ({-name        => 'action',
           -value       => 'Add New Entry'}),
  '</center>';

Footing;

exit;
