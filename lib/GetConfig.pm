=pod

=head1 NAME $RCSfile: GetConfig.pm,v $

Simple config file parsing

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@DeFaria.com>

=item Revision

$Revision: 1.19 $

=item Created

Tue Feb 14 11:03:18 PST 2006

=item Modified

$Date: 2013/01/17 01:08:34 $

=back

=head1 SYNOPSIS

Parse config files.

 # Comment lines are skipped - white space is eliminated...
 app:                   MyApp
 nbr_iterrations:       10
 major_version:         1
 release:               2
 version:               $major_version.$release

 my %opts = GetConfig "myconfig.cfg";
 print "Application Name:\t" . $opts {app}              . "(" . $opts {version} . )\n";
 print "Iterrations:\t\t"    . $opts {nbr_iterrations}  . "\n";

yields

 Application Name:      MyApp (1.2)
 Iterrations:           10

=head1 DESCRIPTION

This module is a simple interface to reading config files. Config file
format is roughly like .XDefaults format - <name>:<value> pairs. A
hash of the name/value pairs are returned. Variable interpolation is
supported such that env(1) variables will be interpolated as well as
previously defined values. Thus:

 temp_files: tmp
 temp_dir:   $HOME/$temp_files
 temp_dir2:  $HOME/$foo/$temp_files

would return:

 $conf{temp_files} => "tmp"
 $conf{temp_dir}   => "~/tmp"
 $conf{temp_dir2}  => "~/$foo/tmp"

In other word, $HOME would be expanded because it's set in your
environment and $temp_files would be expanded because you set it in
the first line. Finally $foo would not be expanded because it was not
set in the first place. This is useful if other processing wants to
provide further interpolation.

=head1 ROUTINES

The following routines are exported:

=cut

package GetConfig;

use strict;
use warnings;

use base 'Exporter';
use File::Spec;
use Carp;

our @EXPORT = qw (
  GetConfig
);

# Interpolate variable in str (if any) from %opts
sub interpolate ($%) {
  my ($str, %opts) = @_;

  # Since we wish to leave undefined $var references in tact the following while
  # loop would loop indefinitely if we don't change the variable. So we work
  # with a copy of $str changing it always, but only changing the original $str
  # for proper interpolations.
  my $copyStr = $str;

  while ($copyStr =~ /\$(\w+)/) {
    my $var = $1;

    if (exists $opts{$var}) {
      $str     =~ s/\$$var/$opts{$var}/;
      $copyStr =~ s/\$$var/$opts{$var}/;
    } elsif (exists $ENV{$var}) {
      $str     =~ s/\$$var/$ENV{$var}/;
      $copyStr =~ s/\$$var/$ENV{$var}/;
    } else {
     $copyStr =~ s/\$$var//;
  } # if
 } # while

 return $str;
} # interpolate

sub _processFile ($%) {
  my ($configFile, %opts) = @_;
  
  while (<$configFile>) {
    chomp;

    next if /^\s*[\#|\!]/;    # Skip comments

    if (/\s*(\w*)\s*:\s*(.*)\s*$/) {
      my $key   = $1;
      my $value = $2;

      # Strip trailing spaces
      $value =~ s/\s+$//;

      # Interpolate
      $value = interpolate $value, %opts;

      if ($opts{$key}) {
        # If the key exists already then we have a case of multiple values for 
        # the same key. Since we support this we need to replace the scalar
        # value with an array of values...
        if (ref $opts{$key} eq "ARRAY") {
          # It's already an array, just add to it!
          push @{$opts{$key}}, $value;
        } else {
          # It's not an array so make it one
          my @a;

          push @a, $opts{$key};
          push @a, $value;
          $opts{$key} = \@a;
        } # if
      } else {
        # It's a simple value
        $opts{$key} = $value;
      }  # if
    } # if
  } # while
  
  return %opts;
} # _processFile

sub GetConfig ($) {
  my ($filename) = @_;

=pod

=head2 GetConfig ($conf)

Reads $filename looking for .XDefaults style name/value pairs and
returns a hash.

Parameters:

=begin html

<blockquote>

=end html

=over

=item $conf

Name of configuration file

=back

=begin html

</blockquote>

=end html

Returns:

=begin html

<blockquote>

=end html

=over

=item Hash of name/value pairs

=back

=begin html

</blockquote>

=end html

=cut

  my %opts;

  open my $configFile, '<', $filename
    or carp "Unable to open config file $filename";

  %opts = _processFile $configFile;

  close $configFile;

  return %opts;
} # GetConfig

1;

=pod

=head1 DEPENDENCIES

=head2 Perl Modules

L<File::Spec>

=head1 INCOMPATABILITIES

None yet...

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Andrew DeFaria (Andrew@DeFaria.com).

=head1 AUTHOR

Andrew DeFaria (Andrew@DeFaria.com)

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
