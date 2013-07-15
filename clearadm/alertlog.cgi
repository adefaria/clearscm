#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: alertlog.cgi,v $

Display the alert log

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.9 $

=item Created:

Mon Oct 25 11:10:47 PDT 2008

=item Modified:

$Date: 2011/01/29 23:33:04 $

=back

=head1 SYNOPSIS

 Usage alertlog.cgi: [-u|sage] [-ve|rbose] [-d|ebug]

 Where:
   -u|sage:               Displays usage
   -ve|rbose:             Be verbose
   -d|ebug:               Output debug messages

=head2 DESCRIPTION

This script displays the alert log

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

my $VERSION  = '$Revision: 1.9 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);
  
my $clearadm;

my %opts = Vars;

$opts{start} ||= 0;
$opts{page}  ||= 10;

# Main
GetOptions (
  usage      => sub { Usage },
  verbose    => sub { set_verbose },
  debug      => sub { set_debug },
) or Usage 'Invalid parameter';

undef $opts{alert}
  if $opts{alert} and $opts{alert} eq 'All';
undef $opts{system}
  if $opts{system} and $opts{system} eq 'All';
undef $opts{notification}
  if $opts{notification} and $opts{notification} eq 'All';

# Announce ourselves
verbose "$FindBin::Script v$VERSION";

$clearadm = Clearadm->new;

my $title = 'Alert Log';
           
heading $title;

display h1 {class => 'center'}, $title;

displayAlertlog (%opts);

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
<a href="http://clearscm.com/php/cvs_man.php?file=clearadm/lib/Clearadm.pm">Clearadm</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=clearadm/lib/ClearadmWeb.pm">ClearadmWeb</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=lib/Display.pm">Display</a><br>
<a href="http://clearscm.com/php/cvs_man.php?file=lib/Utils.pm">Utils</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this script

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, ClearSCM, Inc. All rights reserved.

=cut