#!/usr/bin/env perl

=pod

=head1 NAME $RCSfile: processrunning.pl,v $

Checks to see if a process is running

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.2 $

=item Created:

Mon Dec 13 09:13:27 EST 2010

=item Modified:

$Date: 2013/05/21 16:42:17 $

=back

=head1 SYNOPSIS

 Usage processrunning.pl: [-u|sage] [-ve|rbose] [-deb|ug]
                          -name <processname>

 Where:
   -u|sage:   Displays usage
 
   -ve|rbose: Be verbose
   -deb|ug:   Output debug messages
   
   -name:     Name of the process to check for.

=head1 DESCRIPTION

This script will simply check to see if the process specified is running. Note
that it uses ps(1) and relies on the presence of Cygwin when run on Windows
systems. 

=cut

use strict;
use warnings;

use FindBin;
use Getopt::Long;

use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Display;
use OSDep;
use Utils;

my $VERSION  = '$Revision: 1.2 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);
  
sub restart ($) {
  my ($restart) = @_;

  my ($status, @output) = Execute "$restart 2>&1";
    
  unless ($status) {
    display "Successfully executed restart option: $restart";
      
    display $_ foreach (@output);
  } else {
    display "Unable to restart process using $restart (Status: $status)";
      
    display $_ foreach (@output);
  } # unless
  
  return $status;
} # restart
  
# Main
error "Cannot use $FindBin::Script when using Windows - hint try using Cgywin", 1 
  if $ARCH eq 'windows';
  
my ($name, $restart);

GetOptions (
  usage       => sub { Usage },
  verbose     => sub { set_verbose },
  debug       => sub { set_debug },
  'name=s'    => \$name,
  'restart=s' => \$restart,
) or Usage "Invalid parameter";

Usage 'Extraneous options: ' . join ' ', @ARGV
  if @ARGV;

Usage "Must specify process name"
  unless $name;
  
# Announce ourselves
verbose "$FindBin::Script V$VERSION";

my $opts = $ARCH eq 'cygwin' ? '-eWf' : '-ef';

my $cmd = "ps $opts | grep -i '$name' | grep -v \"grep -i \'$name\'\"";

my ($status, @output) = Execute $cmd;

unless ($status) {
  display "No process found with the name of $name";
  
  $status = restart $restart if $restart;
  
  exit $status;
} elsif ($status == 2) {
  error "Unable to execute $cmd (Status: $status) - $!\n"
      . join ("\n", @output), $status;
} # if
 
foreach (@output) {
  next
    if /grep -i '$name'/;
    
  next
    if /grep -i $name/;
  
  next
    if /$FindBin::Script/;
    
  display "Found processes named $name";
  exit 0;
} # foreach

display "Did not find any processes named $name";

exit restart $restart if $restart;

=pod

=head1 CONFIGURATION AND ENVIRONMENT

DEBUG: If set then $debug is set to this level.

VERBOSE: If set then $verbose is set to this level.

TRACE: If set then $trace is set to this level.

=head1 DEPENDENCIES

=head2 Perl Modules

L<FindBin>

L<Getopt::Long|Getopt::Long>

=head2 ClearSCM Perl Modules

=begin man 

 Display
 Utils

=end man

=begin html

<blockquote>
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
