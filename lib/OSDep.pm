=pod

=head1 NAME $RCSfile: OSDep.pm,v $

Isolate OS dependencies

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.12 $

=item Created

Tue Jan  3 11:36:10 PST 2006

=item Modified

$Date: 2011/11/16 19:46:13 $

=back

=head1 SYNOPSIS

This module seeks to isolate OS dependences by confining them to this
module as well as provide convienent references and mechanisms for
doing things that are different on different OSes.

 print "Running on $ARCH\n";
 `$cmd > $NULL 2>&1`;
 my $filename = $app_base . $SEPARATOR . "datafile.txt";

=head1 DESCRIPTION

This module exports several variables that are useful to isolate OS
dependencies. For example, $ARCH is set to "windows", "cygwin" or the
value of $^O depending on which OS the script is running. This allows
you to write code that is dependant on which OS you are running
on. Similarly, $NULL is set to the string "NUL" when running on
Windows otherwise it is set to "/dev/null" (Under Cygwin /dev/null is
appropriate). This way if you wish to say redirect output to "null"
you can use $NULL.

There is currently only one subroutine exported, Chrooted, which
returns $TRUE if you are operating in a chrooted environment, $FALSE
otherwise;

=head1 ROUTINES

The following routines are exported:

=cut

package OSDep;

use strict;
use warnings;

use base 'Exporter';

our $ARCH      = $^O =~ /MSWin/ 
               ? 'windows'
               : $^O =~ /cygwin/
               ? "cygwin"
               : $^O;
our $NULL      = $^O =~ /MSWin/ ? 'NUL' : '/dev/null';
our $SEPARATOR = $^O =~ /MSWin/ ? '\\'  : '/';
our $TRUE      = 1;
our $FALSE     = 0;
our $ROOT      = $^O =~ /MSWin/ ? $ENV {SYSTEMDRIVE} . $SEPARATOR : "/";

our @EXPORT = qw (
  $ARCH
  $FALSE
  $NULL
  $SEPARATOR
  $TRUE
  Chrooted
);

sub Chrooted () {

=pod

=head2 Chrooted ()

Returns $TRUE  if you are operating under a chrooted environment,
$FALSE otherwise.

Parameters:

=begin html

<blockquote>

=end html

=over

=item None

=back

=begin html

</blockquote>

=end html

Returns:

=begin html

<blockquote>

=end html

=over

=item Boolean

=back

=begin html

</blockquote>

=end html

=cut

  if ($ARCH eq "windows" or $ARCH eq "cygwin") {
    # Not sure how this relates to Windows/Cygwin environment so just
    # return false
    return $FALSE;
  } else {
    return ((stat $ROOT) [1] != 2);
  } # if
} # Chrooted

1;

=pod

=head1 VARIABLES

=over

=item $ARCH

Set to either "windows", "cygwin" or $^O.

=item $NULL

Set to "NUL" for Windows, "/dev/null" otherwise.

=item $SEPARATOR}

Set to "\" for Windows, "/" otherwise.

=item $TRUE;

Convenient boolean variable set to 1 (Cause I always forget if 1 or 0
is true)

=item $FALSE

Convenient boolean variable set to 0 (Cause I always forget if 1 or 0
is false)

=item $ROOT

Set to SYSTEMDRIVE for Windows, "/" otherwise

=back

=head1 DEPENDENCIES

None

=head1 INCOMPATABILITIES

None yet...

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria <Andrew@ClearSCM.com>.

=head1 LICENSE AND COPYRIGHT

This Perl Module is freely available; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version.

This Perl Module is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License (L<http://www.gnu.org/copyleft/gpl.html>) for more
details.

You should have received a copy of the GNU General Public License
along with this Perl Module; if not, write to the Free Software Foundation,
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
reserved.

=cut
