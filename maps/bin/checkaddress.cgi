#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: checkaddress.cgi,v $
# Revision:     $Revision: 1.1 $
# Description:	Check an email address
# Author:       Andrew@DeFaria.com
# Created:      Mon Jan 16 20:25:32 PST 2006
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     perl
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

use MAPS;

use CGI qw(:standard);

# Get MAPSUser from cookie
my $userid;

if (param "user") {
  $userid = param 'user';
} else {
  $userid = cookie 'MAPSUser';
} # if

$userid //= $ENV{USER};

my $sender = param 'sender';

sub formatRule($$$) {
  my ($list, $email_on_file, $rec) = @_;

  my $next  = $rec->{sequence} - 1;
  my $rule  = "Rule: $email_on_file (";
     $rule .= a {
       -href   => "/maps/php/list.php?type=$list&next=$next",
       -target => '_blank',
     }, "$list:$rec->{sequence}";
     $rule .= ')' . br;

     if ($rec->{retention}) {
       $rule .= "Retention: " . $rec->{retention} . br;
     } # if

     if ($rec->{comment}) {
       $rule .= "Comment: " . $rec->{comment};
     } # if

  return $rule;
} # formatRule

sub Heading() {
  print
    header     (-title  => "MAPS: Check Address"),
    start_html (-title  => "MAPS: Check Address",
                -author => "Andrew\@DeFaria.com");
    print h3 {-align => "center",
              -class => "header"},
    "MAPS: Checking address $sender";

  return;
} # Heading

sub Body() {
  my ($onlist, $rec);

  # Algorithm change: We now first check to see if the sender is not found
  # in the message and skip it if so. Then we handle if we are the sender
  # and that the from address is formatted properly. Spammers often use 
  # the senders email address (i.e. andrew@defaria.com) as their from address
  # so we check "Andrew DeFaria <Andrew@DeFaria.com>", which they have never
  # forged. This catches a lot of spam actually.
  #
  # Next we check to see if the sender is on our whitelist. If so then we let
  # them in. This allows us to say whitelist josephrosenberg@hotmail.com while
  # still nulllisting all of the other hotmail.com spammers.
  #
  # Next we process blacklisted people as they are also of high priority.
  #
  # Then we process nulllist people.
  #
  # Finally, we handle return processing

  # Some email addresses have a '+' in them (e.g. 
  # wipro+autoreply@talent.icims.com). The problem is that CGI.pm replaces the
  # '+' with a space. Now email addresses cannot contain spaces so we're gonna
  # assume that a space in the email should be a '+'.
  $sender =~ s/\s/\+/g;

  ($onlist, $rec) = OnWhitelist($sender, $userid, 0);

  if ($onlist) {
    print div {-align => "center"},
      font {-color => "green"},
        "Messages from", b ($sender), "will be", b ("delivered"), br, hr;
    print formatRule('white', $sender, $rec);
  } else {
    ($onlist, $rec) = OnBlacklist($sender, 0);

    if ($onlist) {
      print div {-align => "center"},
           font {-color => "black"},
            "Messages from", b ($sender), "will be", b ("blacklisted"), br, hr;
      print formatRule('black', $sender, $rec);
    } else {
      ($onlist, $rec) = OnNulllist($sender, 0);

      if ($onlist) {
        print div {-align => "center"},
             font {-color => "grey"},
            "Messages from", b ($sender), "will be", b ("discarded"), br, hr;
        print formatRule('null', $sender, $rec);
      } else {
        print div {-align => "center"},
             font {-color => "red"},
            "Messages from", b ($sender), "will be", b ("returned");
      } # if
    } # if
  } # if

  print br div {-align => "center"},
    submit(-name      => "submit",
           -value     => "Close",
           -onClick   => "window.close (self)");

  return;
} # Body

sub Footing() {
  print end_html;

  return;
} # Footing

# Main
SetContext($userid);
Heading;
Body;
Footing;

exit;

