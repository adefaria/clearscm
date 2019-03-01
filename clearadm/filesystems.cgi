#!/usr/local/bin/perl

=pod

=head1 NAME $RCSfile: filesystems.cgi,v $

Filesystems

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.11 $

=item Created:

Mon Oct 25 11:10:47 PDT 2008

=item Modified:

$Date: 2011/02/14 14:50:37 $

=back

=head1 SYNOPSIS

 Usage filesystems.cgi: [-u|sage] [-ve|rbose] [-d|ebug]
                        [-s|ystem <system>]

 Where:
   -u|sage:   Displays usage
   -v|erbose: Be verbose
   -d|ebug:   Output debug messages
   
   -s|sytem:  System to report on filesystems (Default: all)

=head2 DESCRIPTION

This script displays all known filesystems

=cut

use strict;
use warnings;

use FindBin;
use Getopt::Long;
use CGI qw (:standard :cgi-lib *table start_Tr end_Tr start_td end_td);
use CGI::Carp 'fatalsToBrowser';

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Clearadm;
use ClearadmWeb;
use Display;
use Utils;

my $VERSION  = '$Revision: 1.11 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);
  
my $subtitle = 'Filesystems Status';

my $system = param 'system';

my $clearadm;

# Main
GetOptions (
  usage      => sub { Usage },
  verbose    => sub { set_verbose },
  debug      => sub { set_debug },
  'system=s' => \$system
) or Usage 'Invalid parameter';

$system ||= '';

# Announce ourselves
verbose "$FindBin::Script v$VERSION";

$subtitle .= $system eq '' 
           ? ': All Systems' 
           : ': ' . ucfirst $system;

$clearadm = Clearadm->new;

heading $subtitle;

display h1 {class => 'center'}, $subtitle;

displayFilesystem ($system);

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
