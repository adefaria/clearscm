#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: add2nulllist.cgi,v $
# Revision:     $Revision: 1.1 $
# Description:  Add an email address to the nulllist
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

    my ($status, $rule) = OnNulllist ($rec{sender});

    if ($status) {
      my $match = ($rule->{pattern} // '') . '@' . ($rule->{domain} // '');
      $match .= " ($rule->{comment})" if $rule->{comment};
      print br,
"The email address $rec{sender} is already on ${Userid}'s $rec{type} list";
      print br, "Matches: $match";
    } else {
      my ($messages, $msg) = Add2Nulllist (%rec);

      if ($messages < 0) {
        print br, $msg;
        print br, "Unable to add $rec{sender} to $rec{type} list";
        return;
      } else {
        print br,
"The email address, $rec{sender}, has been added to ${Userid}'s $rec{type} list";

        print br, $msg if $messages > 0;
      }    # if

      # Now remove this entry from the other lists (if present)
      for my $otherlist ('white', 'black') {
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

          print br,
            "Removed $rec{sender} from ${Userid}'s "
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
my $userid = Heading ('getcookie', '', 'Add to Null List', 'Add to Null List',);

$userid ||= $ENV{USER};

SetContext ($userid);

NavigationBar ($userid);

my $type = 'null';

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
