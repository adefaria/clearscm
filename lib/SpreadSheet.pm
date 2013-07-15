=pod

=head1 NAME $RCSfile: SpreadSheet.pm,v $

Object oriented interface to Excel Spreadsheets

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.1 $

=item Created

Tue Nov 20 10:40:53 PST 2012

=item Modified

$Date: 2012/11/21 02:53:06 $

=back

=head1 SYNOPSIS

Provides access to Excel Spreadsheets

 # Create SpreadSheet object
 my $ss = SpreadSheet->new ($file)

 # Get data in a sheet
 my @rows = $ss->getData ($sheetName);
 
 foreach (@rows) {
   my %row = %$_;
   
   foreach (keys %row) {
     display "$_: $row{$_}";
   } # foreach
 } # foreach
 
=head1 DESCRIPTION

This module provides a simple, object oriented interface to a SpreadSheet.

=head1 ROUTINES

The following routines are exported:

=cut

package SpreadSheet;

use strict;
use warnings;

use File::Basename;

use Display;
use OSDep;
use TimeUtils;

use Win32::OLE;
use Win32::OLE::Const 'Microsoft Excel';

sub _setError ($$) {
  my ($self, $errmsg, $error) = @_;
  
  $self->{errmsg} = $errmsg;
  $self->{error}  = $error;
  
  return;
} # _setError

sub DESTROY {
  my ($self) = @_;
  
  undef $self->{excel} if $self->{excel};
} # DESTROY

sub new (;$) {
  my ($class, $filename) = @_;

=pod

=head2 new ()

Construct a new SpreadSheet object. 

Parameters:

=for html <blockquote>

=over

=item $filename

Pathname to the spreadsheet file

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item SpreadSheet object

=back

=for html </blockquote>

=cut

  my $self = bless {
    filename => $filename,
    excel    => Win32::OLE->new ('Excel.Application', 'Quit'),
  }, $class;

  # Excel needs a Windows based absolute path
  if ($^O eq 'cygwin') {
    my @output = `cygpath -wa $self->{filename}`;
    chomp @output;

    $self->{filename} = $output[0];
  } else {
    require Cwd;
    
    Cwd->import ('abs_path');

    $self->{filename} = abs_path ($self->{filename});
  } # if

  $self->{book} = $self->{excel}->Workbooks->Open ($self->{filename});
  
  $self->_setError ("Unable to open spreadsheet $self->{filename}", 1)
    unless $self->{book};

  return $self;
} # new

sub getSheet (;$) {
  my ($self, $sheet) = @_;
  
=pod

=head2 getSheet ($)

Return the data in the sheet specified

Parameters:

=for html <blockquote>

=over

=item $sheet

The name of the sheet

=back

=for html </blockquote>

Returns:

=for html <blockquote>

=over

=item @records

Array of rows each represented by a hash. Note this assumes that the first row
are field headings and are used as the keys for the hash.

=back

=for html </blockquote>

=cut

  my @data;
  
  unless ($self->{book}) {
    $self->_setError ("Failed to open SpreadSheet ($self->{filename})", 1);
    
    return;
  } # unless

  if ($sheet) {
    $self->{sheet} = $self->{book}->Worksheets->Item ($sheet);
  } else {
    $sheet = 1;
    
    $self->{sheet} = $self->{book}->Worksheets (1);
  } # if
  
  unless ($self->{sheet}) {
  	$self->_setError ("Unable to get sheet $sheet from spreadsheet $self->{filename}", 1);
  	
  	return;
  } # unless
    
  # Now parse the spreadsheet
  my $lastRow = $self->{sheet}->UsedRange->Find ({
                    What            => '*',
                    SearchDirection => xlPrevious,
                    SearchOrder     => xlByRows,
                   })->{Row};
  my $lastColumn = $self->{sheet}->UsedRange->Find ({
                     What             => '*',
                     SearchDirection  => xlPrevious,
                     SearchOrder      => xlByColumns,
                   })->{Column};

  # Find columns by headings
  my (@fields, $row, $column);

  for ($column = 1; $column <= $lastColumn; $column++) {
    $fields[$column - 1] = $self->{sheet}->Cells (1, $column)->{Value};
  } # for
  
  # Get data
  for ($row = 2; $row <= $lastRow; $row++) {
    my %row;
    
    for ($column = 1; $column <= $lastColumn; $column++) {
      $row{$fields[$column - 1]} = 
        $self->{sheet}->Cells ($row, $column)->{Value};
        
      $row{$fields[$column - 1]} ||= '';
    } # for
    
    push @data, \%row;
  } # for
    
  return @data;
} # getSheet

1;