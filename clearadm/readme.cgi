#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: readme.cgi,v $

Display the README file

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.2 $

=item Created:

Mon Oct 25 11:10:47 PDT 2008

=item Modified:

$Date: 2011/02/14 14:54:19 $

=back

=head1 DESCRIPTION

This script displays the README file

=cut

use strict;
use warnings;

use FindBin;
use Getopt::Long;

use CGI qw (:standard *table start_Tr end_Tr);
use CGI::Carp 'fatalsToBrowser';

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use ClearadmWeb;
use Display;
use Utils;

# Main
GetOptions (
  'usage'        => sub { Usage },
  'verbose'      => sub { set_verbose },
  'debug'        => sub { set_debug },
) or Usage "Invalid parameter";

# Announce ourselves
verbose "$ClearadmWeb::APPNAME V$ClearadmWeb::VERSION";

heading;

display '<pre><blockquote>';

display h1 {class => 'center'}, "$ClearadmWeb::APPNAME: README";

display $_
  foreach (ReadFile 'README');

display '</pre></blockquote>';

footing;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<CGI|CGI.html>

L<CGI::Carp|CGI::Carp>

L<FindBin>

L<Getopt::Long|Getopt::Long>

=head2 ClearSCM Perl Modules

=begin man 

 Display
 Utils

=end man

=begin html

<blockquote>
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