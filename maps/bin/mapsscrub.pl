#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: mapsscrub,v $

This script scrubs messages from the MAPS database based on the users settings

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@DeFaria.com>

$Revision: 1.1 $

=item Created:

Fri Nov 29 14:17:21  2002

=item Modified:

$Date: 2013/06/12 14:05:47 $

=back

=head1 SYNOPSIS

 Usage: mapsscrub.pl [-usa|ge] [-h|elp] [-v|erbose] [-de|bug]
                     [-n|optimize]

  Where:
   -usa|ge       Print this usage
   -h|elp        Detailed help
   -v|erbose     Verbose mode (Default: Not verbose)
   -de|bug       Turn on debugging (Default: Off)

   -user|id      User ID to scrub (Default: All users)
   -n\oopitmize  Whether or not to optimize DB (Default: optimize)

=cut

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use Getopt::Long;
use Pod::Usage;

use DateUtils;
use Display;
use Logger;
use MAPS;
use Utils;

my %opts = (
  usage    => sub {pod2usage},
  help     => sub {pod2usage (-verbose => 2)},
  verbose  => sub {set_verbose},
  debug    => sub {set_debug},
  optimize => 1,
);

my ($log, %total);

sub CleanUp($) {
  my ($userid) = @_;

  my %options = GetUserOptions ($userid);

  my $timestamp = SubtractDays (Today2SQLDatetime, $options{History});

  $total{'Emails cleaned'}      = CleanEmail $timestamp, $opts{dryrun};
  $total{'Log entries removed'} = CleanLog $timestamp,   $opts{dryrun};

  for (qw(white black null)) {
    my $listname = ucfirst ($_) . 'list entries removed';

    $total{$listname} = CleanList (
      userid => $userid,
      type   => $_,
      log    => $log,
      dryrun => $opts{dryrun},
    );
  }    # for

  Stats \%total, $log;

  return;
}    # CleanUp

# Main
GetOptions (\%opts, 'usage', 'help', 'verbose', 'debug', 'userid=s',
  'optimize!', 'dryrun',)
  or pod2usage;

$log = Logger->new (
  path        => '/var/local/log',
  timestamped => 'yes',
);

FindUser (%opts{userid});

while (my $rec = GetUser ()) {
  SetContext ($rec->{userid});

  CleanUp ($rec->{userid});
}    # while

# Now optimize the database
if ($opts{optimize}) {
  OptimizeDB;

  $log->msg ('Database optimized');
}    # if

exit;
