#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: getFilesystems.cgi,v $

Get a list of filesystems for a system

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.5 $

=item Created:

Mon Dec 13 09:13:27 EST 2010

=item Modified:

$Date: 2011/01/14 16:29:37 $

=back

=head1 SYNOPSIS

 Usage getFilesystems.cgi: system=<system>

 Where:
   system=<system>: Name of the system defined in the Clearadm database to
                    retrieve the filesystems for
=head1 DESCRIPTION

Retrieve a list of filesystems for a given system and put out a web page that
specifies the <select> dropdown representing the filesystems for the system.
This script is intended to be called by AJAX to fill in a dropdown list on a
web page in response to JavaScript action on another dropdown (a system 
dropdown).

=cut

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Clearadm;
use ClearadmWeb;
use Display;

use CGI qw (:standard :cgi-lib);

my %opts = Vars;

error "System not specified", 1
  unless $opts{system};

my $clearadm = Clearadm->new;

heading undef, 'short';

display makeFilesystemDropdown ($opts{system}, 'Filesystem'); 

display end_html;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<FindBin>

=head2 ClearSCM Perl Modules

=begin man 

 Clearadm
 ClearadmWeb
 Display

=end man

=begin html

<blockquote>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/Clearadm.pm">Clearadm</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=clearadm/lib/ClearadmWeb.pm">ClearadmWeb</a><br>
<a href="http://clearscm.com/php/scm_man.php?file=lib/Display.pm">Display</a><br>
</blockquote>

=end html

=head1 BUGS AND LIMITATIONS

There are no known bugs in this script

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, ClearSCM, Inc. All rights reserved.

=cut