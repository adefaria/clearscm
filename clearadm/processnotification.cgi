#!/usr/local/bin/perl

=pod

=head1 NAME $RCSfile: processnotification.cgi,v $

Process a notification

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.3 $

=item Created:

Mon Oct 25 11:10:47 PDT 2008

=item Modified:

$Date: 2011/02/14 14:53:07 $

=back

=head1 SYNOPSIS

 Usage processnotification.cgi: [-u|sage] [-ve|rbose] [-d|ebug]
                                action=[Add|Delete|Edit|Post] 
                                notification=<notificationname>

 Where:
   -u|sage:      Displays usage
   -ve|rbose:    Be verbose
   -d|ebug:      Output debug messages
   
   action:       Specifies to add, delete, edit or post an alert
   notification: Name of notification to delete or edit

=head2 DESCRIPTION

This script adds, deletes, edits or posts a notification

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

my $title = 'Notifications';

heading $title;

unless ($opts{'delete.x'} or $opts{'edit.x'} or $opts{action}) {
  displayError 'Action not defined!';
  exit 1;
} # unless

unless ($opts{action} eq 'Add') {
  unless ($opts{name}) {
    displayError 'Notification not defined!';
    exit 1;
  } # unless
} # unless

my ($err, $msg);

if ($opts{action} eq 'Add') {
  display h1 {class => 'center'}, 'Add Notification';
  editNotification; 
} elsif ($opts{'delete.x'}) {
  ($err, $msg) = $clearadm->DeleteNotification ($opts{name});
   
  if ($msg !~ /Records deleted/) {
    displayError "Unable to delete notification $opts{name}\n$msg";
  } else {
    display h1 {class => 'center'}, $title;
    display h3 {class => 'center'}, "Notification '$opts{name}' deleted";
    
    displayNotification;
  } # if
} elsif ($opts{'edit.x'}) {
  display h1 {class => 'center'}, 'Edit Notification: ', $opts{name};
  editNotification ($opts{name});
} elsif ($opts{action} eq 'Post') {
  delete $opts{action};
  
  my %notification = $clearadm->GetNotification ($opts{name});
  
  # System and Filesystem are links to tables of the same name. If specified 
  # they need to match up to an existing system or they can be null. If we
  # have this as an edited field and the user puts nothing in them then we
  # get '', which won't work. So change '' -> undef.
  
  # TODO: Should think about making these dropdowns instead (However that would
  # require AJAX to update filesystem when system changes). For now let's do
  # this.
#  $opts{system} = undef
#    if $opts{system} eq '';
#  $opts{filesystem} = undef
#    if $opts{filesystem} eq '';
  
  if (%notification or $opts{oldname}) {
    my $name = delete $opts{oldname};
    
    $name ||= $opts{name};
    
    ($err, $msg) = $clearadm->UpdateNotification ($name, %opts);

    if ($err) {
      displayError "$msg (Status: $err)";
    } else {
      display h1 {class => 'center'}, $title;
      display h3 {class => 'center'}, "Notification '$opts{name}' updated";
    
      displayNotification;
    } # if
  } else {
    ($err, $msg) = $clearadm->AddNotification (%opts);

    if ($err) {
      displayError "$msg (Status: $err)";
    } else {
     
      display h1 {class => 'center'}, $title;
      display h3 {class => 'center'}, "Notification '$opts{name}' added";
    
      displayNotification;
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
