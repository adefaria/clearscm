#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: Stream.pl,v $

This trigger will update CCDB when streams are added or removed.

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.6 $

=item Created:

Fri Mar 11 17:45:57 PST 2011

=item Modified:

$Date: 2011/03/26 06:24:44 $

=back

=head1 DESCRIPTION

This trigger will update the CCDB when UCM streams are added or removed. It
is implemented as a post operation trigger on the mkstream and rmstream
Clearcase operations. It should be attached to all UCM vobs (i.e. pvobs) that
you wish CCDB to monitor. If using mktriggers.pl the trigger defintion is:
 
 Trigger:        CCDB_STREAM
   Description:  Updates CCDB when a stream is made or removed
   Type:         -element -all
   Opkinds:      -postop mkstream,rmstream
   ScriptEngine: Perl
   Script:       Stream.pl
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

triglog 'Starting trigger';

my $VERSION  = '$Revision: 1.6 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

# UCM fires the mkstream trigger operation (CLEARCASE_OP_KIND=mkstream) twice,
# once with CLEARCASE_MTYPE set to stream and another time with it set to 
# project. The reason for this is to update the project that we now have this
# new stream. Normally we would use this to update a table in CCDB regarding
# the relationship between UCM projects and streams, but we're not tracking that
# so we can simply exit.
exit 0
  if ($ENV{CLEARCASE_MTYPE} and $ENV{CLEARCASE_MTYPE} eq 'project');

my ($name, $pvob) = split /\@/, $ENV{CLEARCASE_STREAM};

trigdie 'Stream name not known', 1
  unless $name;

trigdie 'Pvob name not known', 1
  unless $pvob;

$pvob = vobname $pvob;

my $CCDBService = CCDBService->new;

trigdie 'Unable to connect to CCDBService', 1
  unless $CCDBService->connectToServer;

my ($err, $msg, $request);

triglog "CLEARCASE_OP_KIND: $ENV{CLEARCASE_OP_KIND}";

if ($ENV{CLEARCASE_OP_KIND} eq 'mkstream') {
  my $stream = Dumper {
    name => $name,
    pvob => $pvob
  };
  
  # Squeeze out extra spaces
  $stream =~ s/ = /=/g;
  $stream =~ s/ => /=>/g;
  
  $request = "AddStream $stream";
} elsif ($ENV{CLEARCASE_OP_KIND} eq 'rmstream') {
  $request = "DeleteStream $name $pvob";
} elsif ($ENV{CLEARCASE_OP_KIND} eq 'deliver_complete' or
         $ENV{CLEARCASE_OP_KIND} eq 'rebase_complete') {
  # Add $ENV{CLEARCASE_DLV_ACTS} to $ENV{CLEARCASE_BASELINES}.
  $ENV{CLEARCASE_DLVR_ACTS} ||= '';
  
  foreach (split / /, $ENV{CLEARCASE_DLVR_ACTS}) {
    my ($activity) = split /\@/;

    foreach (split / /, $ENV{CLEARCASE_BASELINES}) {
      my ($baseline) = split /\@/;
      
      my $baselineActivityXref = Dumper {
        baseline => $baseline,
        activity => $activity,
        pvob     => $pvob,
      };
    
      # Squeeze out extra spaces
      $baselineActivityXref =~ s/ = /=/g;
      $baselineActivityXref =~ s/ => /=>/g;
  
      $request = "AddBaselineActivityXref $baselineActivityXref";
      
      triglog "Executing request: $request";

      ($err, $msg) = $CCDBService->execute ($request);
      
      # Just ignore dups
      trigdie "Unable to execute request: $request\n"
            . join ("\n", @$msg), $err
        unless $err == 0 or $err == 1062;
    } # foreach
  } # foreach
  
  exit 0;
} # if

triglog "Executing request: $request";

($err, $msg) = $CCDBService->execute ($request);

trigdie "Unable to execute request: $request\n"
      . join ("\n", @$msg), $err
  if $err;
  
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

