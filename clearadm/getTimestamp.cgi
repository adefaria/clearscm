#!/usr/bin/perl

=pod

=head1 NAME $RCSfile: getTimestamp.cgi,v $

Get a list of timestamps startTimestamp or endTimestamp elementID

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.6 $

=item Created:

Mon Dec 13 09:13:27 EST 2010

=item Modified:

$Date: 2011/01/20 14:34:24 $

=back

=head1 SYNOPSIS

 Usage getTimestamp.cgi: system=<system> elementID=<elementID>
                         [filesytem=<filesystem>] [scaling=<scaling>] 

 Where:
   <system>:       Name of the system defined in the Clearadm database to
                   retrieve the timestamps for.
   <elementID>:    Element's ID name. Must be one of startTimestamp or 
                   endTimeStamp. This is needed by makeTimestampDropdown to
                   determine whether to default the dropdown to Earliest or
                   Latest.
   [<filesystem>]: If specified then we look at clearadm.filesystem otherwise
                   we look at clearadm.loadavg.
   <scaling>:      Currently one of Minute, Hour, Day or Month. Specifies how
                   Clearadm::GetLoadavg|GetFS will scale the data returned.
   
=head1 DESCRIPTION

Retrieve a list of timestamps for a given system/filesystem and put out a web
page that specifies the <select> dropdown representing the timestamps. If 
filesystem is specified then we retrieve information about filesystem snapshots
in clearadm.fs, otherwise we retrieve information about loadavg snapshots in
clearadm.loadavg for the given system. Data is scaled by scaling and elementID
is used to determine if we should make 'Earliest' or 'Latest' the default. This
script is intended to be called by AJAX to fill in a dropdown list on a web page
in response to JavaScript action on another dropdown (a system dropdown or an
interval dropdown).

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
  
error "ElementID not specified", 1
  unless $opts{elementID};
  
error 'ElementID must be either "startTimestamp" or "endTimestamp"', 1
  unless $opts{elementID} eq 'startTimestamp' or $opts{elementID} eq 'endTimestamp';
  
my $default = $opts{elementID} eq 'startTimestamp' ? 'Earliest' : 'Latest';

my $clearadm = Clearadm->new;

heading undef, 'short';

my $name = $opts{elementID} eq 'startTimestamp'
         ? 'start'
         : $opts{elementID} eq 'endTimestamp'
         ? 'end'
         : 'unknown';
          
if ($opts{filesystem}) {
  display makeTimeDropdown 
    'filesystem', 
    $opts{elementID},
    $opts{system},
    $opts{filesystem},
    $opts{label},
    $default,
    $opts{scaling},
    $name;
} else {
  display makeTimeDropdown 
    'loadavg',
    $opts{elementID},
    $opts{system},
    ucfirst $name,
    $opts{label},
    $default,
    $opts{scaling},
    $name;
} # if

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