#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: add2whitelist.cgi,v $
# Revision:     $Revision: 1.1 $
# Description:  Add an email address to the whitlist
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

local $0 = $FindBin::Script;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use Utils;

use MAPS;
use MAPSLog;
use MAPSWeb;

use CGI qw/:standard *table/;
use CGI::Carp 'fatalsToBrowser';

sub Add2List(%) {
  my (%rec) = @_;

  CheckParms (['userid', 'type'], \%rec);

  my $nextseq = GetNextSequenceNo (%rec);

  my $Userid = ucfirst $rec{userid};

  while () {
    $rec{pattern}   = param "pattern$nextseq";
    $rec{domain}    = param "domain$nextseq";
    $rec{comment}   = param "comment$nextseq";
    $rec{hit_count} = param "hit_count$nextseq";
    $rec{retention} = param "retention$nextseq";

    last unless $rec{pattern} or $rec{domain};

    $rec{sender} = CheckEmail $rec{pattern}, $rec{domain};

    my ($status, $rule) = OnWhitelist ($rec{sender}, $rec{userid});

    if ($status) {
      my $match = ($rule->{pattern} // '') . '@' . ($rule->{domain} // '');
      $match .= " ($rule->{comment})" if $rule->{comment};
      print br
"The email address $rec{sender} is already on ${Userid}'s $rec{type} list";
      print br "Matches: $match";
    } else {
      my ($messages, $msg) = Add2Whitelist (%rec);

      if ($messages < 0) {
        print br "Unable to add $rec{sender} to $rec{type} list";
        print br $msg;
        return;
      } else {
        print br
"The email address, $rec{sender}, has been added to ${Userid}'s $rec{type} list";
      }    # if

      if ($messages > 0) {
        if ($messages == 1) {
          print br 'Your previous message has been delivered';
        } else {
          print br "Your previous $messages messages have been delivered";
        }    # if
      } elsif ($messages == 0) {
        print br
'Unable to find any old messages but future messages will now be delivered.';
      }    # if

      # Now remove this entry from the other lists (if present)
      for my $otherlist ('black', 'null') {
        FindList (
          userid => $rec{userid},
          type   => $otherlist,
          sender => $rec{sender},
        );

        my $seq = GetList ();

        if ($seq->{sequence}) {
          my $err;

          ($err, $msg) = DeleteList (
            userid   => $rec{userid},
            type     => $otherlist,
            sequence => $seq->{sequence},
          );

          croak $msg if $err < 0;

          print br "Removed $rec{sender} from ${Userid}'s "
            . ucfirst $otherlist . ' list'
            if $err > 0;

          ResequenceList (
            userid => $rec{userid},
            type   => $otherlist,
          );
        }    # if
      }    # for
    }    # if

    $nextseq++;
  }    # while

  return;
}    # Add2List

# Main
my $userid =
  Heading ('getcookie', '', 'Add to White List', 'Add to White List',);

$userid ||= $ENV{USER};

SetContext ($userid);

NavigationBar ($userid);

my $type = 'white';

Add2List (
  userid => $userid,
  type   => $type,
);

print start_form {
  -method => 'post',
  -action => 'processaction.cgi',
  -name   => 'list'
};

print '<p></p><center>',
  hidden ({
    -name    => 'type',
    -default => $type
  }
  ),
  submit ({
    -name  => 'action',
    -value => 'Add'
  }
  ),
  '</center>';

Footing;

exit;
