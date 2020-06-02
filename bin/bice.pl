#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: bice.pl,v $

Report breakin attempts to this domain

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.3 $

=item Created:

Fri Mar 18 01:14:38 PST 2005

=item Modified:

$Date: 2013/05/30 15:35:27 $

=back

=head1 SYNOPSIS

 Usage: bice [-u|sage] [-v|erbose] [-d|ebug] [-nou|pdate] [-nom|ail]
             [-f|ilename <filename> ]

 Where:
   -u|sage     Print this usage
   -v|erbose:  Verbose mode (Default: -verbose)
   -nou|pdate: Don't update security logfile file (Default: -update)
   -nom|ail:   Don't send emails (Default: -mail)
   -f|ilename: Open alternate messages file (Default: /var/log/auth.log)

=head1 DESCRIPTION

This script will look at the security logfile for attempted breakins and then 
use whois to report them to the upstream provider.

=cut

use strict;
use warnings;

use FindBin;
use Getopt::Long;

use lib "$FindBin::Bin/../lib";

use Display;
use Mail;
use Utils;

use Fcntl ':flock'; # import LOCK_* constants

my $security_logfile = '/var/log/auth.log';

# Customize these variables
my $domain   = 'DeFaria.com';
my $contact  = 'Andrew@DeFaria.com';
my $location = 'Phoenix, Arizona, USA';
my $UTC      = 'UTC-7';
my $mailhost = $domain;
# End customize these variables

my $verbose;
my $update    = 1;
my $email     = 1;
my $hostname  = `hostname`;
chomp $hostname;

if ($hostname =~ /(\w*)\./) {
  $hostname = $1;
} # if

sub AddToIPTables (@) {
  my (@ips) = @_;

  # We shouldn't need to weed out duplicate but ya never know  
  my $ipfilename = '/etc/ipblock';

  my $result = open my $ipfile, '<', $ipfilename;

  my (%ips, @oldips);

  if ($result) {
    @oldips = <$ipfile>; 

    close $ipfile if $ipfile;

    chomp @oldips;
  } # if

  map { $ips{$_} = 1 } @oldips;
  map { $ips{$_} = 1 } <@ips>;

  open $ipfile, '>', "$ipfilename"
    or error "Unable to open $ipfilename - $!", 1;

  foreach (sort keys %ips) {
    print $ipfile "$_\n";
  } # foreach

  close $ipfile;

  # Recreate the BICE chain
  `/sbin/iptables -F BICE`;
  `/sbin/iptables -X BICE`;
  `/sbin/iptables -N BICE`;

  # Add all new @ips to iptables
  `/sbin/iptables -A BICE -s $_ -p tcp -j DROP` foreach (sort keys %ips);

  return;
} # AddToIPTables

# Use whois(1) to get the email addresses of the responsible parties for an IP
# address. Note that a hash is used to eliminate duplicates.
sub GetEmailAddresses ($) {
  my ($ip) = @_;

  # List of whois servers to try
  # Apparently whois.opensrs.net no longer offers whois service?
  my @whois_list = (
    '',
    'whois.arin.net',
    'whois.nsiregistry.net',
    #'whois.opensrs.net',
    'whois.networksolutions.com',
  );

  my %email_addresses;

  foreach (@whois_list) {
    my @lines;

    if ($_ eq "") {
      @lines = grep { /.*\@.*/ } `whois $ip`;
    } else {
      @lines = grep {/.*\@.*/ } `whois -h $_ $ip`;
    } # if

    foreach (@lines) {
      my @fields = split /:/, $_;

      $_ = $fields [@fields - 1];

      if (/(\S+\@\S[\.\S]+)/) {
        $email_addresses{$1} = "";
      } # if
    } # foreach

    # Break out of loop if we found email addresses
    last unless keys %email_addresses;
  } # foreach

  return keys %email_addresses;
} # GetEmailAddresses

# Send email to the responsible parties.
sub SendEmail ($$$$$) {
  my ($to, $subject, $message, $ip, $violations) = @_;

  if ($email) {
    verbose "Reporting $ip ($violations violations) to $to";
  } else {
    verbose "Would have reported $ip ($violations violations) to $to";
    return;
  } # if

  mail (
    from    => "BICE\@$domain",
    to      => $to,
    #cc      => $contact,
    subject => $subject,
    mode    => 'html',
    data    => $message,
  );
} # SendEmail

sub processLogfile () {
  my %violations;

  # Note: Normally you must be root to open up $security_logfile
  open my $readlog, '<', $security_logfile
    or error "Unable to open $security_logfile - $!", 1;

  flock $readlog, LOCK_EX
    or error "Unable to flock $security_logfile", 1;

  my @lines;

  while (<$readlog>) {
    my $newline = $_;

    if (/^(\S+\s+\S+\s+\S+)\s+.*Invalid user (\w+) from (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/) {
      my %violation = $violations{$3} ? %{$violations{$3}} : %_;

      push @{$violation{$2}}, $1;

      $violations{$3} = \%violation;

      $newline =~ s/Invalid user/INVALID USER/;
    } elsif (/^(\S+\s+\S+\s+\S+)\s+.*authentication failure.*ruser=(\S+).*rhost=(\S+)/) {
      my %violation = $violations{$3} ? %{$violations{$3}} : %_;

      push @{$violation{$2}}, $1;

      $violations{$3} = \%violation;

      $newline =~ s/authentication failure/AUTHENTICATION FAILURE/;
    } elsif (/^(\S+\s+\S+\s+\S+)\s+.*Failed password for (\w+) from (\d{1,3}\.\d{1,3}\.d{1,3}\.d{1,3})/) {
      my %violation = $violations{$3} ? %{$violations{$3}} : %_;

      push @{$violation{$2}}, $1;

      $violations{$3} = \%violation;

      $newline =~ s/Failed password/FAILED PASSWORD/;
    } # if

    push @lines, $newline; 
  } # while

  return %violations unless $update;

  flock $readlog, LOCK_UN
    or error "Unable to unlock $security_logfile", 1;

  close $readlog;

  open my $writelog, '>', $security_logfile
    or error "Unable to open $security_logfile for writing - $!", 1;

  flock $writelog, LOCK_EX
    or error "Unable to flock $security_logfile", 1;

  print $writelog $_ foreach @lines;

  flock $writelog, LOCK_UN
    or error "Unable to unlock $security_logfile", 1;

  close $writelog;

  return %violations;
} # processLogfile

# Report breakins to the authorities.
sub ReportBreakins () {
  my %violations = processLogfile;

  my $nbrViolations = keys %violations;

  if ($nbrViolations == 0) {
    verbose 'No violations found';
  } elsif ($nbrViolations == 1) {
    verbose '1 site attempting to violate our perimeter';
  } else {
    verbose "$nbrViolations sites attempting to violate our perimeter";
  } # if

  foreach (sort keys %violations) {
    my $ip = $_;

    my $attempts;

    $attempts += @{$violations{$ip}{$_}} foreach (keys %{$violations{$ip}});

    my @emails   = GetEmailAddresses $ip;

    unless (@emails) {
      verbose 'Unable to find any responsible parties for detected breakin '
            . "attempts from IP $ip ($attempts breakin attempts)";
      next;
    } # unless

    my $to      = join ',', @emails;
    my $subject = "Illegal attempts to break into $domain from your domain";
    my $message = <<"END";
<p>Somebody from your domain with an IP Address of <b>$ip</b> has been
attempting to break into my domain, <b>$domain</b>. <u>Breaking into somebody
else's computer is illegal and criminal prosecution can result!</u> As a
responsible ISP it is in your best interests to investigate such activity and to
shutdown any such illegal activity as it is a violation of law and most likely a
violation of your user level agreement. It is expected that you will investigate
this and send the result and/or disposition of your investigation back to
$contact. <font color=red><b>If you fail to do so then criminal prosecution may
result!</b></font></p>

<p>Please be aware that <b>none</b> of these attempts to breakin have been
successful - this system is configured such that only trusted users are allowed
to log in as they must provide authenticated keys in advance. So your attempts
have been wholly unsuccessful. Still, this does not diminish the illegality nor
the ability of us to pursue this matter in a court of law.</p>

<p>There were a total of $attempts attempts to break into $domain. The following
is a report of the breakin attempts from IP Address $ip along with the usernames
attempted and the time of the attempt:</p>

<p>Note: $domain is located in $location. All times are $UTC:</p>

<ol>
END
    # Report users
    foreach my $user (sort keys %{$violations{$ip}}) {
      if (@{$violations{$ip}{$user}} == 1) {
        $message .= "<li>The user <b>$user</b> attempted access on $violations{$ip}{$user}[0]</li>";
      } else {
        $message .= "<li>The user <b>$user</b> attemped access on the following date/times:</li>"; 
        $message .= "<ol>";
        $message .= "<li>$_</li>" foreach (@{$violations{$ip}{$user}});
        $message .= "</ol>";
      } # if
    } # foreach

    $message .= '</ol><p>Your prompt attention to this matter is expected '
              . 'and will be appreciated.</p>';
    SendEmail $to, $subject, $message, $ip, $attempts;
  } # foreach

  AddToIPTables keys %violations;
} # ReportBreakins

## Main

# Get options
GetOptions (
  'verbose', sub { set_verbose },
  'debug',   sub { set_debug },
  'usage',   sub { Usage },
  'update!', \$update,
  'mail!',   \$email,
  'file=s',  \$security_logfile,
) || Usage;

Usage 'Must specify filename'
  unless $security_logfile;

ReportBreakins;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<FindBin>

L<Getopt::Long|Getopt::Long>

L<Fcntl>

=head2 ClearSCM Perl Modules

=begin man 

 Display
 Mail
 Utils

=end man

=begin html

<blockquote>
<<a href="http://clearscm.com/php/scm_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Mail.pm">Mail</a><br>
a href="http://clearscm.com/php/scm_man.php?file=lib/Utils.pm">Utils</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this script

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, ClearSCM, Inc. All rights reserved.

=cut
