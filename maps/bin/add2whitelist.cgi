#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: add2whitelist.cgi,v $
# Revision:     $Revision: 1.1 $
# Description:  Add an email address to the blacklist
# Author:       Andrew@DeFaria.com
# Created:      Mon Jan 16 20:25:32 PST 2006
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     Perl
#
# (C) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;
use warnings;

use FindBin;
$0 = $FindBin::Script;

use lib "$FindBin::Bin/../lib";

use MAPS;
use MAPSLog;
use MAPSWeb;
use MAPSUtil;

use CGI qw/:standard *table/;
use CGI::Carp 'fatalsToBrowser';

my $userid;
my $Userid;
my $type = 'white';

sub Add2List() {
  my $sender  = '';
  my $nextseq = GetNextSequenceNo($userid, $type);

  while () {
    my $pattern = param "pattern$nextseq";
    my $domain  = param "domain$nextseq";
    my $comment = param "comment$nextseq";

    last if ((!defined $pattern || $pattern eq '') &&
             (!defined $domain  || $domain  eq ''));

    $sender = CheckEmail $pattern, $domain;

    my ($status, $rule) = OnWhitelist($sender, $userid);

    if ($status != 0) {
      print br {-class => 'error'}, "The email address $sender is already on ${Userid}'s $type list";
    } else {
      my $messages = Add2Whitelist($sender, $userid, $comment);

      print br "The email address, $sender, has been added to ${Userid}'s $type list";
      if ($messages > 0) {
        if ($messages == 1) {
          print br 'Your previous message has been delivered';
        } else {
          print br "Your previous $messages messages have been delivered";
        } # if
      } elsif ($messages == -1) {
        print br {-class => 'error'}, 'Unable to deliver message';
      } else {
        print br 'Unable to find any old messages but future messages will now be delivered.';
      } # if

      # Now remove this entry from the other lists (if present)
      for my $otherlist ('black', 'null') {
        my $sth = FindList($otherlist, $sender);
        my ($sequence, $count);

        ($_, $_, $_, $_, $_, $sequence) = GetList($sth);

        if ($sequence) {
          $count = DeleteList($otherlist, $sequence);
          print br "Removed $sender from ${Userid}'s " . ucfirst $otherlist . ' list'
            if $count > 0;

          ResequenceList($userid, $otherlist);
        } # if
      } # for
    } # if

    $nextseq++;
  } # while
} # Add2List

# Main
$userid = Heading(
  'getcookie',
  '',
  'Add to White List',
  'Add to White List',
);

$userid ||= $ENV{USER};

$Userid = ucfirst $userid;

SetContext($userid);

NavigationBar($userid);

Add2List;

print start_form {
  -method => 'post',
  -action => 'processaction.cgi',
  -name   => 'list'
};

print '<p></p><center>',
  hidden ({-name    => 'type',
           -default => $type}),
  submit ({-name    => 'action',
           -value   => 'Add'}),
  '</center>';

Footing;

exit;
