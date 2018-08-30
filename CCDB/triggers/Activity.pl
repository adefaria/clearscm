#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: Activity.pl,v $

This trigger will update CCDB when activities are added or removed.

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.6 $

=item Created:

Fri Mar 11 17:45:57 PST 2011

=item Modified:

$Date: 2011/04/02 00:28:21 $

=back

=head1 DESCRIPTION

This trigger will update the CCDB when UCM activities are added or removed. It
is implemented as a post operation trigger on the mkactivity and rmactivity
Clearcase operations. It should be attached to all UCM vobs (i.e. pvobs) that
you wish CCDB to monitor. If using mktriggers.pl the trigger defintion is:
 
 Trigger:        CCDB_ACTIVITY
   Description:  Updates CCDB when activities are made or removed
   Type:         -element -all
   Opkinds:      -postop mkactivity,rmactivity,chactivity
   ScriptEngine: Perl
   Script:       Activity.pl
   Vobs:         ucm
 EndTrigger

=cut

use strict;
use warnings;

use FindBin;
use Data::Dumper;
  
$Data::Dumper::Indent = 0;

use lib $FindBin::Bin, "$FindBin::Bin/../lib", "$FindBin::Bin/../../lib";

use TriggerUtils;
use CCDBService;

my $VERSION  = '$Revision: 1.6 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);
  
triglog 'Starting trigger';
  
TriggerUtils::dumpenv;

my ($name, $pvob) = split /\@/, $ENV{CLEARCASE_ACTIVITY};
my ($stream)      = split /\@/, $ENV{CLEARCASE_STREAM};

trigdie 'Activity name not known', 1
  unless $name;

trigdie 'Pvob name not known', 1
  unless $pvob;

$pvob = vobname $pvob;

my $CCDBService = CCDBService->new;

trigdie 'Unable to connect to CCDBService', 1
  unless $CCDBService->connectToServer;
  
my ($err, $msg, $request);

triglog "CLEARCASE_OP_KIND: $ENV{CLEARCASE_OP_KIND}";

if ($ENV{CLEARCASE_OP_KIND} eq 'mkactivity') {
  my $activity = Dumper {
    name => $name,
    pvob => $pvob,
    type => $name !~ /^(deliver|rebase|integrate|revert|tlmerge)/i
          ? 'regular'
          : 'integration',
  };
  
  # Squeeze out extra spaces
  $activity =~ s/ = /=/g;
  $activity =~ s/ => /=>/g;
  
  $request = "AddActivity $activity";
  
  triglog "Executing request: $request";
  
  ($err, $msg) = $CCDBService->execute ($request);

  trigdie "Activity: Unable to execute request: $request\n"
        . join ("\n", @$msg), $err
    if $err;
  
  triglog "Success";
  
  my $streamActivityXref = Dumper {
    stream   => $stream,
    activity => $name,
    pvob     => $pvob,
  };
  
  # Squeeze out extra spaces
  $streamActivityXref =~ s/ = /=/g;
  $streamActivityXref =~ s/ => /=>/g;
  
  $request = "AddStreamActivityXref $streamActivityXref"
} elsif ($ENV{CLEARCASE_OP_KIND} eq 'rmactivity') {
  # Note: The delete on cascade option in the MySQL database for CCDB should
  # handle clean up of any associated records like any stream_activity_xref
  # records.
  $request = "DeleteActivity $name $pvob";
} elsif ($ENV{CLEARCASE_OP_KIND} eq 'chactivity') {
  # Need to move changeset items from $ENV{CLEARCASE_ACTIVITY} -> 
  # $ENV{CLEARCASE_TO_ACTIVITY}. I believe we will be called once for each
  # element version since it says that CLEARCASE_ID_STR will be set and 
  # CLEARCASE_ID_STR uniquely identifies an element/version
  triglog "Processing chactivity";
  
  my ($fromActivity) = split /@/, $ENV{CLEARCASE_ACTIVITY};
  
  my ($toActivity) = split /@/, $ENV{CLEARCASE_TO_ACTIVITY};
  
  my $update = Dumper {
    activity => $toActivity
  };
  
  # Squeeze out extra spaces
  $update =~ s/ = /=/g;
  $update =~ s/ => /=>/g;
  
  my $elementName = $ENV{CLEARCASE_PN};
     $elementName =~ s/\\/\//g;
     $elementName = removeViewTag $elementName;
  my $version     = $ENV{CLEARCASE_ID_STR};
     $version     =~ s/\\/\//g;
  
  $request  = "UpdateChangeset $fromActivity $elementName ";
  $request .= "$version $pvob $update";
} # if

triglog "Executing request: $request";
  
($err, $msg) = $CCDBService->execute ($request);

trigdie "Activity: Unable to execute request: $request\n"
      . join ("\n", @$msg), $err
  if $err;

triglog "Success";

$CCDBService->disconnectFromServer;

triglog 'Ending trigger';

exit 0;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<FindBin>

L<Data::Dumper|Data::Dumper>

=head2 ClearSCM Perl Modules

=begin man 

 CCDBSerivce
 TriggerUtils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=CCDB/lib/CCDBService.pm">CCDBService</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=CCDB/triggers/TriggerUtils.pm">TriggerUtils</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this script

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, ClearSCM, Inc. All rights reserved.

=cut