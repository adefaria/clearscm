#!/usr/local/bin/perl

=pod

=head1 NAME $RCSfile: processfilesystem.cgi,v $

Delete a filesystem

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.4 $

=item Created:

Mon Oct 25 11:10:47 PDT 2008

=item Modified:

$Date: 2011/02/14 14:52:40 $

=back

=head1 SYNOPSIS

 Usage processfileystem.cgi: [-u|sage] [-ve|rbose] [-d|ebug]
                             action=[edit|delete]
                             system=<system> filesystem=<filesystem>

 Where:
   -u|sage:    Displays usage
   -ve|rbose:  Be verbose
   -d|ebug:    Output debug messages
   
   action:     "edit" or "delete" to edit or delete the filesystem
   system:     System
   filesystem: Filesystem to delete

=head2 DESCRIPTION

This script edits or deletes a filessystem from Clearadm

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

my $VERSION  = '$Revision: 1.4 $';
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

my $title = 'Process Filesystem: '
          . ucfirst $opts{system}
          . ":$opts{filesystem}";

heading $title;

unless ($opts{'delete.x'} or $opts{'edit.x'} or $opts{action}) {
  displayError 'Action not defined!';
  footing;
  exit 1;
} # unless

unless ($opts{system}) {
  displayError 'System not defined!';
  footing;
  exit 1;
} # unless

unless ($opts{filesystem}) {
  displayError 'System not defined!';
  footing;
  exit 1;
} # unless

my ($err, $msg);

if ($opts{'delete.x'}) {
  ($err, $msg) = $clearadm->DeleteFilesystem ($opts{system}, $opts{filesystem});
   
  if ($msg !~ /Records deleted/) {
    displayError "Unable to delete $opts{system}:$opts{filesystem}\n$msg";
  } else {
    display h1 {
      class => 'center'
    }, 'Filesystem ' . ucfirst $opts{system} . ":$opts{filesystem} deleted";
  } # if
} elsif ($opts{'edit.x'}) {
  display h1 {
    class => 'center'
  }, 'Edit Filesystem: ', ucfirst $opts{system} . ":$opts{filesystem}";

  editFilesystem ($opts{system}, $opts{filesystem});
} elsif ($opts{action} eq 'Post') {
  delete $opts{action};
  delete $opts{'edit.x'}
    if $opts{'edit.x'};
  delete $opts{'edit.y'}
    if $opts{'edit.y'};
  
  ($err, $msg) = $clearadm->UpdateFilesystem (
    $opts{system},
    $opts{filesystem},
    %opts
  );
  
  if ($err) {
    displayError "$msg (Status: $err)";
  } else {
    display h1 {class => 'center'}, ucfirst $opts{system} . ":$opts{filesystem} updated";
    
    displayFilesystem ($opts{system});
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
