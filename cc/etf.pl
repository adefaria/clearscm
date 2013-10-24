#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: etf.pl,v $

Evil Twin Finder

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision:

$Revision: 1.5 $

=item Created:

Fri Apr 23 09:40:31 PDT 2010

=item Modified:

$Date: 2011/01/09 01:00:28 $

=back

=head1 SYNOPSIS

 Usage: eft.pl [-u|sage] [-ve|rbose] [-d|ebug] [-di|rectory <dir>]

 Where:

  -u|sage:       Displays usage
  -ve|rbose:     Be verbose
  -d|ebug:       Output debug messages

  -dir           Directory to process

=head1 DESCRIPTION

This script will search for existing evil twins in a Clearcase vob. It is
intended to be used in the context of a base Clearcase view with a default
config spec.

An evil twin is defined as two or more Clearcase elements that share the same
path, and same name, but have different OIDs thus having different version
histories. This can occur when a user creates an element in a directory that
used to exist in this same directory on another branch or on a previous version
of the same branch. By default Clearcase will create an element with a new OID.
This new, evil twin will then develop it's own version history. This then
becomes a problem when you attempt to merge branches - which twin (OID) should
Clearcase keep track of?

Most Clearcase users implement an evil twin trigger to prevent the creation of
evil twins but sometimes evil twins have already been created. This script helps
identify these already existing evil twins.

Note: Evil twins can also happen if you only apply your evil twin trigger to the
mkelem Clearcase action. It should be applied to the lnname action as elements
come into creation by things like the cleartool ln, mv and mkdir commands. These
all eventually do an lnname so that's where you should put your evil twin
trigger.

=head1 ALGORITHM

 TODO: Is cleartool find really needed? I mean since we are going through
       the extended version namespace don't we by default find all
       subdirectories?
 
This script will use cleartool find to process all directory elements from
$startingDir (Default '.'). For each version of the directory a hash will be
built up containing all of the element names in that directory version.
Elements are always added and never deleted in this hash as we are looking for
all elements that have ever existed in the directory at any point in time.

This script then dives into the view extended namespace for directory elements
examining the internal Clearcase structures. If we find a branch we recurse or 
numbered directory version we recurse looking for file elements (TODO: What 
about directory evil twins?). Note that we skip version 0 as version 0 is never
interesting - it is always a duplicate of what it branched from and empty.

Directory versions that are not numbered are labels or baselines that point to
numbered directory versions so we don't need to look at them again. 

For each file element we find we use the cleartool dump command to get the OID
of this particiular versioned element and build up an array of hashes of all the
elements in the directory. For each element version we maintain a hash keyed by
the OID. The structure also contains a count of the number of times the OID was
found. An evil twin therefore will have multiple OIDs for the same element
version name.

After the directory is processed we look though the array of hashes for elements
that have multiple OIDs and report them. Then we proceed to the next directory.

=cut

use strict;
use warnings;

use Getopt::Long;
use File::Basename;
use Cwd;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Clearcase;
use Clearcase::Element;
use Display;
use Logger;
use TimeUtils;
use Utils;

my $VERSION = '1.0';

my (%total, %dirInfo, $log, $startTime);

=pod

=head2 reportDir (%directoryInfo)

Report any evil twins found in %directoryInfo

Parameters:

=for html <blockquote>

=over

=item %directoryInfo

Structure representing the OIDs of element in a direcotry

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item nothing

=back

=for html </blockquote>

=cut

sub reportDir (%) {
  my (%directoryInfo) = @_;

  my $ets = 0;

  foreach my $filename (sort keys %directoryInfo) {
    my @oids = @{$directoryInfo{$filename}};

    if (scalar @oids > 1) {
      $ets++;

      $log->msg ("File: $filename");

      foreach (@oids) {
	$log->msg ("\tOID: $$_{OID} ($$_{count})");
	$log->msg ("\tFirst detected \@: $$_{version}");
      } # foreach
    } # if
  } # foreach

  return $ets;
} # reportDir

=pod

=head2 proceedDir $dirName

Build up a data structure for $dirName looking for evil twins

Parameters:

=for html <blockquote>

=over

=item $dirName

Directory to examine

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item %dirInfo

Directory info hash keyed by element name whose value is an array of oidInfo
hashes containing a unique OID and a count of how many occurences of that OID
exist for that element.

=back

=for html </blockquote>

=cut

sub processDir ($);
sub processDir ($) {
  my ($dirName) = @_;

  opendir my $dir, $dirName
    or $log->err ("Unable to open directory $dirName - $!", 1);

  my @dirVersions = grep {!/^\./} readdir $dir;

  closedir $dir;

  my ($directory, $version) = split /$Clearcase::SFX/, $dirName;

  $directory = basename (cwd)
    if $directory eq '.';

  my $displayName = "$directory$Clearcase::SFX$version";
   
  # We only want to deal with branches and numbered versions. Non-numbered
  # versions which are not branches represent labels and baselines which are
  # just aliases for directory and file elements. Branches represent recursion
  # points and numbered versions represent unique directory versions.
  my @elements;

  foreach (@dirVersions) {
    my ($status, @output) = $Clearcase::CC->execute (
      "describe -fmt %m $dirName/$_"
    );
    my $objkind = $output[0];

    if ($objkind =~ / element/) {
      push @elements, $_;
    } elsif (/^\d/ or $objkind eq 'branch') {
      # Skip 0 element - it's never interesting.
      next if $_ eq '0';

      # Recurse for branches and numbered directory versions
      if ($objkind eq 'branch') {
        $total{branches}++;
      } else {
        $total{'directory versions'}++;
      } # if

      verbose_nolf '.';

      #$log->log ("Recurse:\t$displayName/$_");

      %dirInfo = processDir "$dirName/$_";

      next;
    } # if
  } # foreach

  foreach (@elements) {
    $total{'element versions'}++;

    #$log->log ("Element:\t$displayName/$_");

    # Get oid using the helper function
    my $oid = Clearcase::Element::oid "$dirName/$_";

    if ($dirInfo{$_}) {
      my $found = 0;

      # Search our %dirInfo for a version matching $version	
      foreach (@{$dirInfo{$_}}) {
        # Increment count if we find a matching oid
        if ($$_{OID} eq $oid) {
          $$_{count}++;
          $found = 1;
          last;
        } # if
      } # foreach
        
      unless ($found) {
        # If we didn't find a match then make a new %objInfo starting with a
        # count of 1. Also save this current $version, which is the first
        # instance of this new oid. 
        push @{$dirInfo{$_}}, {
          OID     => $oid,
          count   => 1,
          version => "$dirName/$_",
        };
      } # unless
    } else {
      $dirInfo{$_} = [{
        OID     => $oid,
        count   => 1,
        version => "$dirName/$_",
      }];
   } # if
  } # foreach

  return %dirInfo;
} # processDir

=pod

=head2 proceedDirs $startingDir

Process all directories under $startingDir


Parameters:

=for html <blockquote>

=over

=item $startingDir

Directory to start processing

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item $total{etf}

Total number of evil twins found

=back

=for html </blockquote>

=cut

sub processDirs ($) {
  my ($startingDir) = @_;

  my $cmd = "cleartool find \"$startingDir\" -type d -print";

  open my $dirs, '-|', $cmd
    or $log->err ("Unable to execute $cmd - $!", 1);

  while (<$dirs>) {
    chomp; chop if /\r$/;

    my $displayName = $_;

    $displayName =~ s/\@\@$//;

    if ($displayName eq '.') {
      $displayName = basename (cwd);
    } # if

    $log->msg ("Processing $displayName");

    my $startingTime  = time;
    my %directoryInfo = processDir $_;

    verbose '';

    display_duration $startingTime, $log;

    $total{'evil twins'} += reportDir %dirInfo;
  } # while

  close $dirs
    or $log->err ("Unable to close $cmd - $!");
    
  return $total{'evil twins'};
} # processDirs

# Main
local $| = 1;

my $startingDir = '.';

GetOptions (
  usage         => sub { Usage },
  verbose       => sub { set_verbose },
  debug         => sub { set_debug },
  'directory=s' => \$startingDir,
) or Usage 'Invalid parameter';

$startTime = time;

$log = Logger->new;

$log->msg ("Evil Twin Finder $FindBin::Script v$VERSION");

processDirs $startingDir;

Stats \%total, $log;

$log->msg ("$FindBin::Script finished @ " . localtime);

display_duration $startTime, $log;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<Cwd>

L<File::Basename|File::Basename>

L<FindBin>

L<Getopt::Long|Getopt::Long>

=head2 ClearSCM Perl Modules

=begin man 

 Clearcase
 Clearcase::Element
 Display
 Logger
 TimeUtils
 Utils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase.pm">Clearcase</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Clearcase/Element.pm">Element</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Logger.pm">Logger</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/TimeUtils.pm">TimeUtils</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Utils.pm">Utils</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this script

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, ClearSCM, Inc. All rights reserved.

=cut
