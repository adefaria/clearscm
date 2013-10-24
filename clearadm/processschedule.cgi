#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: processschedule.cgi,v $

Process a schedule

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.3 $

=item Created:

Mon Oct 25 11:10:47 PDT 2008

=item Modified:

$Date: 2011/02/14 14:53:36 $

=back

=head1 SYNOPSIS

 Usage processschedule.cgi: [-u|sage] [-ve|rbose] [-d|ebug]
                            action=[Add|Delete|Edit|Post] 
                            schedule=<schedule>

 Where:
   -u|sage:   Displays usage
   -ve|rbose: Be verbose
   -d|ebug:   Output debug messages
   
   action:     Specifies to add, delete, edit or post an alert
   schedule:   Schedule to delete or edit

=head2 DESCRIPTION

This script adds, deletes, edits or posts a schedule

=cut

use strict;
use warnings;

use FindBin;
use Getopt::Long;
use CGI qw (:standard :cgi-lib *table start_Tr end_Tr);
use CGI::Carp 'fatalsToBrowser';

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Clearadm;
use ClearadmWeb;
use Display;
use Utils;

my $VERSION  = '$Revision: 1.3 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);
  
my $clearadm;

# Main
GetOptions (
  usage      => sub { Usage },
  verbose    => sub { set_verbose },
  debug      => sub { set_debug },
) or Usage 'Invalid parameter';

# Announce ourselves
verbose "$FindBin::Script v$VERSION";

$clearadm = Clearadm->new;

my %opts = Vars;

my $title = 'Schedule';

heading $title;

unless ($opts{'delete.x'} or $opts{'edit.x'} or $opts{action}) {
  displayError 'Action not defined!';
  exit 1;
} # unless

unless ($opts{action} eq 'Add') {
  unless ($opts{name}) {
    displayError 'Schedule not defined!';
    exit 1;
  } # unless
} # unless

my ($err, $msg);

if ($opts{action} eq 'Add') {
  display h1 {class => 'center'}, 'Add Schedule';
  editSchedule; 
} elsif ($opts{'delete.x'}) {
  ($err, $msg) = $clearadm->DeleteSchedule ($opts{name});
   
  if ($msg !~ /Records deleted/) {
    displayError "Unable to delete schedule $opts{name}\n$msg";
  } else {
    display h1 {class => 'center'}, $title;
    display h3 {class => 'center'}, "Schedule $opts{name} deleted";
    
    displaySchedule;
  } # if
} elsif ($opts{'edit.x'}) {
  display h1 {class => 'center'}, 'Edit Schedule: ', $opts{name};
  editSchedule ($opts{name});
} elsif ($opts{action} eq 'Post') {
  delete $opts{action};
  
  my $nbr        = delete $opts{nbr};
  my $multiplier = delete $opts{multiplier};
  
  if ($nbr == 1) {
    $multiplier = substr $multiplier, 0, -1;   
  } # if
  
  $opts{frequency} = "$nbr $multiplier";
  
  my %schedule = $clearadm->GetSchedule ($opts{name});
  
  if (%schedule or $opts{oldname}) {
    my $name = delete $opts{oldname};

    $name ||= $opts{name};

    $opts{active} = 'false'
      unless $opts{active};
    
    ($err, $msg) = $clearadm->UpdateSchedule ($name, %opts);

    if ($err) {
      displayError "$msg (Status: $err)";
    } else {
      display h1 {class => 'center'}, $title;
      display h3 {class => 'center'}, "Schedule $opts{name} updated";
    
      displaySchedule;
    } # if
  } else {
    ($err, $msg) = $clearadm->AddSchedule (%opts);

    if ($err) {
      displayError "$msg (Status: $err)";
    } else {
     
      display h1 {class => 'center'}, $title;
      display h3 {class => 'center'}, "Schedule $opts{name} added";
    
      displaySchedule;
    } # if
  } # if
} else {
  displayError "Unknown action - $opts{action}";
} # if

footing;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<CGI>

L<CGI::Carp|CGI::Carp>

L<FindBin>

L<Getopt::Long|Getopt::Long>

=head2 ClearSCM Perl Modules

=begin man 

 Clearadm
 ClearadmWeb
 Display
 Utils

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/Clearadm.pm">Clearadm</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/ClearadmWeb.pm">ClearadmWeb</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Utils.pm">Utils</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this script

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, ClearSCM, Inc. All rights reserved.

=cut