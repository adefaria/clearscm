#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: importlist.cgi,v $

Imports a white, black or null list into MAPS

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@DeFaria.com>

=item Revision

$Revision: 1.1 $

=item Created:

Mon Jan 16 20:25:32 PST 2006

=item Modified:

$Date: 2019/04/04 13:40:10 $

=back

=head1 SYNOPSIS

 Usage; importlist.cgi [-usa|ge] [-h|elp] [-v|erbose] [-de|bug]
                       [-type <white|black|null>] [-file <filename>]

 Where:
   -usa|ge       Print this usage
   -h|elp        Detailed help
   -v|erbose     Verbose mode (Default: Not verbose)
   -de|bug       Turn on debugging (Default: Off)

   -t|ype        Type of list - white, black or null
   -f|ile        File to import

=head1 DESCRIPTION

This script will import list entries from a list file for white, black or null
lists. Normally this script is run from the Import List button.

=cut

use strict;
use warnings;

use FindBin;
local $0 = $FindBin::Script;

use lib "$FindBin::Bin/../lib";

use Getopt::Long;
use Pod::Usage;

use Display;
use MAPS;
use MAPSWeb;

use CGI qw/:standard *table/;
use CGI::Carp "fatalsToBrowser";

my ($userid, $Userid);

my %opts = (
  usage       => sub { pod2usage },
  help        => sub { pod2usage(-verbose => 2)},
  verbose     => sub { set_verbose },
  debug       => sub { set_debug },
);

$opts{type} = param 'type';
$opts{file} = param 'filename';

die "File not specified" unless $opts{file};

sub importList ($$) {
  my ($list, $type) = @_;

  my $count = 0;

  my @output;

  $| = 1;
  while (<$list>) {
    next if /^\s*#/;

    chomp;

    my ($sender, $comment, $hit_count, $last_hit, $retention) = split /,/;

    my $alreadyExists;

    # The code for checking if a sender is on a list does not expect the $sender
    # to have any regexs
    my $cleansedSender = $sender;

    $cleansedSender =~ s/(\^|\+)//g;

    # TODO: While this works well for real email addresses it does not handle
    # our regexes. True it can weed out some duplicates where a more specific
    # email address is already covered by a more general regex. For example,
    # I may have say andrew@someplace.ru in a null list but also have say 
    # ".*\.ru$" which covers andrew@someplace.ru. Using On<List>list functions
    # will always see ".*\.ru$" as nonexistant and readd it.
    if ($type eq 'white') {
      ($alreadyExists) = OnWhitelist($cleansedSender, $userid);
    } elsif ($type eq 'black') {
      ($alreadyExists) = OnBlacklist($cleansedSender, $userid);
    } elsif ($type eq 'null') {
      ($alreadyExists) = OnNulllist($cleansedSender, $userid);
    } # if

    unless ($alreadyExists) {
      # Some senders lack '@' as they are username only senders. But AddList
      # complains if there is no '@'. For such senders tack on a '@'n
      if ($sender !~ /\@/) {
        $sender .= '@';
      } # if

      AddList(
        userid    => $userid,
        type      => $type,
        sender    => $sender, 
        sequence  => 0,
        comment   => $comment,
        hit_count => $hit_count,
        last_hit  => $last_hit,
        retention => $retention,
      );

      print "Added $sender to ${Userid}'s ${type}list<br>";
      push @output, "Added $sender to ${Userid}'s ${type}list<br>";

      $count++;
    } else {
      push @output, "$sender is already on your " . ucfirst($type) . 'list<br>';
    } # unless
  } # while

  print $_ for @output;

  return $count;
} # importList

# Main
GetOptions(
  \%opts,
  'usage',
  'help',
  'verbose',
  'debug',
  #'file=s',
  'type=s',
);

pod2usage 'Type not specified' unless $opts{type};
pod2usage 'File not specified' unless $opts{file};

# Now let's see if we can get that file
my $list = upload('filename');

#pod2usage "Unable to read $opts{file}" unless -r $opts{file};

$userid = Heading(
  'getcookie',
  '',
  'Import List',
  'Import List',
);

$userid //= $ENV{USER};
$Userid = ucfirst $userid;

SetContext($userid);

NavigationBar($userid);

my $count = importList($list, $opts{type});

if ($count == 1) {
  print br "$count list entry imported";
} elsif ($count == 0) {
  print br 'No entries imported';
} else {
  print br "$count list entries imported";
} # if

exit;
