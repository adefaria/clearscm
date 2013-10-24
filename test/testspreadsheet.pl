#!/usr/bin/perl
use strict;
use warnings;

=pod

=head1 NAME $RCSfile: testspreadsheet.pl,v $

Test the SpreadSheet libary

This script tests various functions of the SpreadSheet libary

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.1 $

=item Created:

Mon Nov 12 16:50:44 PST 2012

=item Modified:

$Date: 2012/11/21 02:53:28 $

=back

=head1 SYNOPSIS

 Usage: testclearquest.pl [-u|sage] [-v|erbose] [-d|ebug]
                          -filename <spreadsheet file>
                  
 Where:
   -usa|ge:     Displays usage
   -v|erbose:   Be verbose
   -de|bug:     Output debug messages

   -filename:   Spreadsheet file

=cut

use FindBin;
use Getopt::Long;

use lib "$FindBin::Bin/../lib";

use SpreadSheet;
use Display;
use Utils;

sub displayData (@) {
  my (@rows) = @_;
  
  my $row = 2;
  
  foreach (@rows) {
    my %row = %$_;
    
    display "Row: $row"; $row++;
    
    foreach (keys %row) {
      my $value = $row{$_} || '';
      
      display "$_: $value";
    } # foreach
  } # foreach
  
  return;
} # displayRecord

## Main
local $| = 1;

my %opts;

GetOptions (
  \%opts,
  usage   => sub { Usage },
  verbose => sub { set_verbose },
  debug   => sub { set_debug },
  'filename=s',
) || Usage;

Usage "Must specify -filename <filename>" unless $opts{filename};

my $spreadSheet = SpreadSheet->new ($opts{filename});

displayData ($spreadSheet->getSheet);
