#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: nag.pl,v $

Nag: A progressively more agressive reminder program.

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision:

$Revision: 1.6 $

=item Created:

Tue Jul 27 15:00:11 PDT 2004

=item Modified:

$Date: 2013/06/13 14:36:03 $

=back

=head1 SYNOPSIS

 Usage: nag.pl [-u|sage] [-ve|rbose] [-d|ebug] [-nos|ign] [-noe|xec]
               [-not|ag]

 Where:

 -u|sage:     Displays this usage
 -ve|rbose:   Be verbose
 -d|ebug:     Output debug messages

 -noe|xec:     No execute mode - just echo out what would have
               been done (Default: exec)
 -not|ag:      Tag message with a signature detailing how many
               times we've sent this email and when was the last time we
               sent it (Default: Don't tag)
 -nos|ign:     Include random signature from ~/.signatures (Default: Don't
               sign)
 -f|ile <file> Use <file> as naglist (Default: ~/.nag/list)

=head1 DESCRIPTION

This script read a file indicating who to remind. The format for this file is:

 <email>|<subject>|<when>|<msgfile>|<sent>|<date>

nag.pl will change a message that was set to send on a particular day of the
week to daily after 3 messages were sent. So if you set the message to be send
on say Mon it will be sent to 3 weeks and then flip to be sent daily.

=head1 The following things should be done to improve this system:

=over

=item *

Move naglist and message files to a database

=item *

Change MAPS to recognize when a message is returned from a nag message. Perhaps
tag it with X-Nag: <nag id> (will this come back when the user replies?). MAPS 
would then white list the sender and deliver the email as well as put the nag in
a pending state.

=cut

use strict;
use warnings;

use FindBin;
use Getopt::Long;

use lib "$FindBin::Bin/../lib";

use DateUtils;
use Display;
use Mail;
use Utils;

my $VERSION = '1.0';

my $exec = 1;
my ($tag, $sign);

my $nagfile = "$ENV{HOME}/.nag/list";

sub dow () {
  my @days = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');

  return $days[(localtime (time)) [6]];
} # dow

sub sign () {
  my $sigfile = "$ENV{HOME}/.signatures";

  return unless -r $sigfile;

  my $signature  = "-- <br>";

  open my $sigs, '<', $sigfile
    or error "Unable to open signature file $sigfile - $!", 1;

  my @sigs = <$sigs>;
  chomp @sigs;

  close $sigs;
  
  $signature .= '<font color="#bbbbbb">';
  $signature .= splice (@sigs, int (rand (@sigs)), 1);
  $signature .= '</font>';

  return $signature;
} # sign

sub tag ($$) {
  my ($sent, $date) = @_;

  return ''
    unless $sent;

  my $tagStr  = '<hr><p style="text-align: center;">';
     $tagStr .= "This message has been sent to you $sent time";

     $tagStr .= 's'
       if $sent > 1;

     $tagStr .= " before<br>";
     $tagStr .= "The last time this message was sent to you was $date<br>";
     $tagStr .= "$FindBin::Script $VERSION<br></p>";

  return $tagStr;
} # tag

## Main
GetOptions (
  usage    => sub { Usage },
  verbose  => sub { set_verbose },
  debug    => sub { set_debug },
  'exec!'  => \$exec,
  'tag!',  => \$tag,
  'sign!', => \$sign,
  'file',  => \$nagfile,
) or Usage 'Invalid parameter';

my $nagfilenew = "$nagfile.$$";

open my $nagsIn, '<', $nagfile
  or error "Unable to open $nagfile for read access - $!", 1;

open my $nagsOut, '>', $nagfilenew
  or error "Unable to open new nagfile $nagfilenew for write access - $!", 1;

while (<$nagsIn>) {
  if (/^#/ or /^$/) {
    print $nagsOut $_;
    next;
  } # if

  chomp;

  my ($email, $subject, $when, $msgfile, $sent, $date) = split /\|/;

  $sent ||= 0;

  my $dow = dow;

  if ($when =~ /$dow/i or $when =~ /daily/i) {
    verbose "Nagging $email with $msgfile...";

    my $footing = '';

    $footing = tag $sent, $date
      if $tag;

    $footing .= sign
      if $sign;

    my $msg;

    my $msgfilename = $msgfile;
       $msgfilename =~ s/~/$ENV{HOME}/;

    open $msg, '<', $msgfilename
      or error "Unable to open message file $msgfile - $!", 1;

    mail (
      to      => $email,
      subject => $subject,
      mode    => 'html',
      data    => $msg,
      footing => $footing,
    );

    close $msg
      or error "Unable to close message file $msg - $!", 1;

    $sent++;
    $date = YMDHM;
    $when = "Daily"
      if $sent > 3;

    print $nagsOut "$email|$subject|$when|$msgfile|$sent|$date\n";
  } else {
    print $nagsOut "$_\n";
  } # if
} # while

close $nagsIn
  or error "Unable to close $nagfile - $!", 1;

close $nagsOut
  or error "Unable to close $nagfilenew - $!", 1;

rename $nagfilenew, $nagfile
  or error "Unable to rename $nagfilenew to $nagfile", 1;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<FindBin>

L<Getopt::Long|Getopt::Long>

=head2 ClearSCM Perl Modules

=begin man 

 DateUtils
 Display
 Mail
 Utils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/cvs_man.php?file=lib/DateUtils.pm">DateUtils</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=lib/Mail.pm">Mail</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=lib/Utils.pm">Utils</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this script

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2004, ClearSCM, Inc. All rights reserved.

=cut  