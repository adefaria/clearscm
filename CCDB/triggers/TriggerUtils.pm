=pod

=head1 NAME $RCSfile: TriggerUtils.pm,v $

Trigger Utilities

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.3 $

=item Created

Fri Mar 11 15:37:34 PST 2011

=item Modified

$Date: 2011/03/26 06:24:30 $

=back

=head1 SYNOPSIS

Provides an some utilities for the CCDB Triggers.

=cut

package TriggerUtils;

use strict;
use warnings;

use Carp;
use FindBin;

use lib "$FindBin::Bin/../../lib";

use DateUtils;

use base 'Exporter';

our $VIEW_DRIVE     = 'M';
our $VIEWTAG_PREFIX = ($^O =~ /mswin/i or $^O =~ /cygwin/)
                    ? "$VIEW_DRIVE:/"
                    : "/view/";

our @EXPORT = qw (
  trigmsg
  triglog
  triglogmsg
  trigdie
  vobname
);

our $logfile;

my $logfileName = "$FindBin::Bin/trigger.log";

sub trigmsg ($){
  # Display a message to the user using clearprompt
  my ($msg) = @_;

  my $cmd  = "clearprompt proceed -newline -type error -prompt \"$msg\" ";
     $cmd .= "-mask abort -default abort";
     
  `$cmd`;
  
  return;
} # trigmsg

sub triglog ($) {
  # Log a message to the log file
  my ($msg) = @_;
  
  return unless $ENV{CCDB_TRIGGER_DEBUG};
  
  unless ($logfile) {
    open $logfile, '>>', $logfileName
      or die "Unable to open logfile $logfile - $!\n";
      
    $logfile->autoflush (1);
  } # unless

  my $timestamp = timestamp;
  
  print $logfile "$FindBin::Script: $timestamp: $msg\n";
  
  return;
} # triglog

sub triglogmsg ($) {
  my ($msg) = @_;
  
  # Log message to log file then display it to user
  triglog $msg;
  trigmsg $msg;
  
  return;
} # triglogmsg

sub trigdie ($$) {
  my ($msg, $err) = @_;
  
  $err ||= 0;
  
  triglog $msg;
  die "$msg\n";
} # trigdie

sub vobname ($) {
  my ($pvob) = @_;
  
  # CCDB stores pvob's in the database with the VOBTAG_PREFIX removed. This
  # makes a vob name OS independent as on Windows it's \$pvob and Unix/Linux
  # it's /vob/$pvob (or sometimes /vobs/$pvob! This is site specific). Now we
  # have a handy method in Clearcase.pm for this but we want speed here. Doing a
  # "use Clearcase;" will invoke a cleartool subproccess ($Clearcase::CC) and we
  # don't want that overhead. So we are replicating that code here. We are
  # hinging off of the first character of the vob name (either '\', or '/') to
  # indicate if we are Windows or non-Windows. Additionally we are hardcoding
  # '/vob/' as the vob tag prefix for the Unix/Linux case.
  if (substr ($pvob, 0, 1) eq '\\') {
    $pvob = substr $pvob, 1;
  } elsif (substr ($pvob, 0, 1) eq '/') {
    if ($pvob =~ /\/vob\/(.+)/) {
      $pvob = $1;
    } # if
  } # if
  
  return $pvob;
} # vobname

sub dumpenv () {
  triglog 'Dumping CLEARCASE_* environment';

  foreach (keys %ENV) {
    next unless /CLEARCASE_/;
  
    triglog "$_: $ENV{$_}";
  } # foreach
  
  return;
} # dumpenv

1;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<Carp>

L<FindBin>

=head2 ClearSCM Perl Modules

=begin man 

 DateUtils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/cvs_man.php?file=lib/DateUtils.pm">DateUtils</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, ClearSCM, Inc. All rights reserved.

=cut