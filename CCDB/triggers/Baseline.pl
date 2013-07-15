#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: Baseline.pl,v $

This trigger will update CCDB when baselines are completed or removed.

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.6 $

=item Created:

Fri Mar 11 17:45:57 PST 2011

=item Modified:

$Date: 2011/04/02 00:29:15 $

=back

=head1 DESCRIPTION

This trigger will update the CCDB when UCM baselines are completed or removed.
It is implemented as a post operation trigger on the mkbl_complete and rmbl
Clearcase operations. It should be attached to all UCM vobs (i.e. pvobs) that
you wish CCDB to monitor. If using mktriggers.pl the trigger defintion is:
 
 Trigger:        CCDB_BASELINE
   Description:  Updates CCDB when baselines are completed or removed
   Type:         -element -all
   Opkinds:      -postop mkbl_complete,rmbl
   ScriptEngine: Perl
   Script:       Baseline.pl
   Vobs:         ucm
 EndTrigger

=cut

use strict;
use warnings;

use FindBin;
use Data::Dumper;
    
$Data::Dumper::Indent = 0;

use lib $FindBin::Bin, "$FindBin::Bin/../lib", "$FindBin::Bin/../../lib";

# I would like to use Clearcase but doing so causes a problem when the trigger
# is run from Clearcase Explorer - something about my use of open3 :-(

use TriggerUtils;
use CCDBService;

triglog 'Starting trigger';

TriggerUtils::dumpenv;

my $VERSION  = '$Revision: 1.6 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my $CCDBService = CCDBService->new;

trigdie 'Unable to connect to CCDBService', 1
  unless $CCDBService->connectToServer;
  
my ($err, $msg, $request);

triglog "CLEARCASE_OP_KIND: $ENV{CLEARCASE_OP_KIND}";

foreach (split / /, $ENV{CLEARCASE_BASELINES}) {
  my ($name, $pvob) = split /\@/;

  trigdie 'Baseline name not known', 1
    unless $name;

  trigdie 'Pvob name not known', 1
    unless $pvob;

  triglog "Processing Baseline: $name\@$pvob";
  
  my $pvobName = vobname $pvob;

  if ($ENV{CLEARCASE_OP_KIND} eq 'mkbl_complete') {
    triglog "Hit mkbl_complete!";
    
    TriggerUtils::dumpenv;

    my $cmd = "lsbl -fmt \"%[activities]p\" $name\@$pvob";
   
    my @output = `cleartool $cmd`; chomp @output;
    my $status = $?;

    trigdie "Unable to execute $cmd (Status: $status)\n" 
          . join ("\n", @output), $status
      if $status;

    foreach my $activity (split / /, $output[0]) {
      my $baselineActivityXref = Dumper {
        baseline => $name,
        activity => $activity,
        pvob     => $pvobName,
      };

      # Squeeze out extra spaces
      $baselineActivityXref =~ s/ = /=/g;
      $baselineActivityXref =~ s/ => /=>/g;

      $request = "AddBaselineActivityXref $baselineActivityXref";
    
      triglog "Executing the request: $request";

      ($err, $msg) = $CCDBService->execute ($request);
  
      trigdie "Baseline: Unable to execute request: $request\n" 
            . join ("\n", @$msg), $err
        if $err;
    } # foreach

    next;
  } elsif ($ENV{CLEARCASE_OP_KIND} eq 'mkbl') {
    my $baseline = Dumper {
      name => $name,
      pvob => $pvobName,
    };
  
    # Squeeze out extra spaces
    $baseline =~ s/ = /=/g;
    $baseline =~ s/ => /=>/g;
  
    $request = "AddBaseline $baseline";
      
    triglog "Executing request: $request";

    ($err, $msg) = $CCDBService->execute ($request);
    
    trigdie "Unable to execute request: $request\n"
          . join ("\n", @$msg), $err
      if $err;

    my $cmd = "lsstream -fmt \"%[activities]p\" $ENV{CLEARCASE_STREAM}";
    
    my @output = `cleartool $cmd`; chomp @output;
    my $status = $?;
    
    trigdie "Unable to execute $cmd (Status: $status)\n"
          . join ("\n", @output), $status
      if $status;
    
    foreach (split / /, $output[0]) {
      my $baselineActivityXref = Dumper {
        baseline => $name,
        activity => $_,
        pvob     => $pvobName,
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
    
    next;
  } elsif ($ENV{CLEARCASE_OP_KIND} eq 'rmbl') {
    $request = "DeleteBaseline $name $pvobName";
  } # if

  triglog "Executing request: $request";
  
  ($err, $msg) = $CCDBService->execute ($request);

  trigdie "Unable to execute request: $request\n"
        . join ("\n", @$msg), $err
    if $err;
} # foreach
  
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
<a href="http://clearscm.com/php/cvs_man.php?file=CCDB/lib/CCDBService.pm">CCDBService</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=CCDB/triggers/TriggerUtils.pm">TriggerUtils</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this script

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, ClearSCM, Inc. All rights reserved.

=cut