#!/usr/bin/perl
#################################################################################
#
# File:         $RCSfile: processaction.cgi,v $
# Revision:     $Revision: 1.1 $
# Description:  Process the action
# Author:       Andrew@DeFaria.com
# Created:      Mon Jan 16 20:25:32 PST 2006
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     Perl
#
# (c) Copyright 2000-2006, Andrew@DeFaria.com, all rights reserved.
#
################################################################################
use strict;
use warnings;

use FindBin;
$0 = $FindBin::Script;

use lib $FindBin::Bin;

use MAPS;
use MAPSWeb;

use CGI qw (:standard *table start_Tr end_Tr);
use CGI::Carp 'fatalsToBrowser';

my $type   = param 'type';
my $action = param 'action';
my $next   = param 'next';
my $userid = cookie 'MAPSUser';
my $lines;
my $total;
my $table_name = 'list';

my @scripts = ('ListActions.js');

sub ReturnSequenceNbrs {
  my @names = param;
  my @sequence_nbrs;

  Debug "Entered ReturnSequenceNbrs";

  foreach (@names) {
    if (/action(\d+)/) {
      push @sequence_nbrs, $1;
    } # if
  } # foreach

  Debug "Returning sequence nbrs " . join ' ', @sequence_nbrs;

  return @sequence_nbrs;
} # ReturnSequenceNbrs

sub DeleteEntries {
  my ($type) = @_;

  my @sequence_nbrs = ReturnSequenceNbrs;

  my $count;

  foreach (@sequence_nbrs) {
    $count += DeleteList $type, $_;
  } # foreach

  if ($count == 0) {
    DisplayError 'Nothing to delete!';
  } else {
    ResequenceList $userid, $type;

    if ($count == 1) {
      print redirect ("/maps/php/list.php?type=$type&next=$next&message=Deleted entry");
    } else {
      print redirect ("/maps/php/list.php?type=$type&next=$next&message=Deleted $count entries");
    } # if
  } # if

  return $count;
} # DeleteEntries

sub PrintInputLine ($$$$$) {
  my ($nextseq, $email_nbr, $leftclass, $dataclass, $rightclass) = @_;

  my $email     = '';
  my $pattern   = '';
  my $domain    = '';
  my $hit_count = 0;

  if (defined $email_nbr && $email_nbr ne '') {
    $email = param "email$email_nbr";
    if ($email && $email ne '') {
      ($pattern, $domain) = split /\@/, $email;
    } # if

    $hit_count = CountMsg $email;
  } # if

  print Tr [
    td {-class      => $leftclass,
        -align      => 'center'}, "$nextseq",
    td {-class      => $dataclass,
        -align      => 'right'},
      (textfield {-class     => 'inputfield',
                  -style     => 'width:100%',
                  -align     => 'right',
                  -size      => 25,
                  -maxlength => '255',
                  -name      => "pattern$nextseq",
                  -value     => $pattern}),
    td {-class      => $dataclass,
        -align      => 'center'}, '@',
    td {-class      => $dataclass},
      (textfield {-class      => 'inputfield',
                  -style      => 'width:100%',
                  -align      => 'left',
                  -size       => 25,
                  -maxlength  => '255',
                  -name       => "domain$nextseq",
                  -value      => $domain}),
    td {-class      => $dataclass},
      (textfield {-class     => 'inputfield',
                  -style     => 'width:100%',
                  -align     => 'left',
                  -size      => 25,
                  -maxlength => '255',
                  -name      => "comment$nextseq",
                  -value     => ''}),
    td {-class      => $rightclass},
      (textfield {-class     => 'inputfield',
                  -style     => 'width:100%',
                  -align     => 'left',
                  -size      => 25,
                  -maxlength => '255',
                  -name      => "hit_count$nextseq",
                  -value     => $hit_count}),
  ];

  return;
} # PrintInputLine

sub AddNewEntry {
  my ($type, @selected)  = @_;

  # First display the last page and add the appropriate number of
  # empty, editable entries (possibly filled in) for the user to add
  # the new entry
  my $selected = @selected;
  my $nextseq = MAPSDB::GetNextSequenceNo $userid, $type;
  my $next = ($nextseq - $lines) + $selected - 1;

  $next = 0
    if $next < 0;

  my $Type = ucfirst $type;

  Heading (
    'getcookie',
    '',
    "Add to $Type List",
    "Add to $Type List",
    '',
    $table_name,
    @scripts
  );

  NavigationBar $userid;

  # Now display table and new entry
  print start_form {
    -method => 'post',
    -action => 'add2' . $type . 'list.cgi',
    -name   => 'list'
  };

  print start_table {-align       => 'center',
                     -id          => $table_name,
                     -border      => 0,
                     -cellspacing => 0,
                     -cellpadding => 4,
                     -width       => '100%'};
  print Tr [
    th {-class => 'tableleftend'},  'Seq',
    th {-class => 'tableheader'},   'Username',
    th {-class => 'tableheader'},   '@',
    th {-class => 'tableheader'},   'Domain',
    th {-class => 'tableheader'},   'Comments',
    th {-class => 'tablerightend'}, 'Hit Count'
  ];

  my @list = ReturnList $type, $next, $lines;
  my %record;
  my $i = 1;

  foreach (@list) {
    $i++;

    %record = %{$_};

    # Normalize fields
    my $sequence  = $record{sequence};
    my $pattern   = $record{pattern}   ? $record{pattern}   : '&nbsp;';
    my $domain    = $record{domain}    ? $record{domain}    : '&nbsp;';
    my $comment   = $record{comment}   ? $record{comment}   : '&nbsp;';
    my $hit_count = $record{hit_count} ? $record{hit_count} : '&nbsp;';

    print Tr [
      td {-class  => 'tableleftdata',
          -align  => 'center'}, $sequence,
      td {-class  => 'tabledata',
          -align  => 'right'}, $pattern,
      td {-class  => 'tabledata',
          -align  => 'center'}, '@',
      td {-class  => 'tabledata',
          -align  => 'left'}, $domain,
      td {-class  => 'tabledata',
          -align  => 'left'}, $comment,
      td {-class  => 'tablerightdata',
          -align  => 'right'}, $hit_count,
    ];
  } # foreach

  # Now the input line(s)
  if (@selected == 0) {
    PrintInputLine $nextseq, undef, 'tablebottomleft', 'tablebottomdata',
                                    'tablebottomright';
  } else {
    foreach (@selected) {
      my $leftclass  = $i == $lines ? 'tablebottomleft'  : 'tableleftdata';
      my $dataclass  = $i == $lines ? 'tablebottomdata'  : 'tabledata';
      my $rightclass = $i == $lines ? 'tablebottomright' : 'tablerightdata';
      $i++;
      PrintInputLine $nextseq++, $_, $leftclass, $dataclass, $rightclass;
    } # foreach
  } # for

  print end_table;
  print br,
    '<center>',
      submit ({-name    => 'update',
               -value   => 'Update',
               -onClick => 'return CheckEntry (document.list);'}),
      submit ({-name    => 'Reset',
               -value   => 'Reset',
               -onClick => 'history.back(); return false'}),
    '</center>';
  print end_form;

  return;
} # AddNewEntry

sub ModifyEntries {
  my ($type) = @_;

  my @selected = ReturnSequenceNbrs;

  my $Type = ucfirst $type;

  Heading (
    'getcookie',
    '',
    "Modify $Type List",
    "Modify $Type List",
    '',
    $table_name,
    @scripts
  );

  NavigationBar $userid;

  # Redisplay the page but open up the lines that are getting modified
  print start_form {
    -method  => 'post',
    -action  => 'modifyentries.cgi',
    -name    => 'list'
  };

  # Print some hidden fields to pass along
  print
    hidden ({-name    => 'type',
             -default => $type}),
    hidden ({-name    => 'next',
             -default => $next});

  print start_table {-align       => 'center',
                     -id          => $table_name,
                     -border      => 0,
                     -cellspacing => 0,
                     -cellpadding => 4,
                     -width       => '100%'};
  print Tr [
    th {-class => 'tableleftend'},  'Seq',
    th {-class => 'tableheader'},   'Username',
    th {-class => 'tableheader'},   '@',
    th {-class => 'tableheader'},   'Domain',
    th {-class => 'tableheader'},   'Comments',
    th {-class => 'tablerightend'}, 'Hit Count',
  ];

  my @list = ReturnList $type, $next, $lines;
  my %record;
  my $s = 0;
  my $i = 1;

  foreach (@list) {
    %record = %{$_};

    my $sequence = $record{sequence};
    my $leftclass  = ($i eq $lines || $sequence eq $total) ?
      'tablebottomleft'  : 'tableleftdata';
    my $dataclass  = ($i eq $lines || $sequence eq $total) ?
      'tablebottomdata'  : 'tabledata';
    my $rightclass = ($i eq $lines || $sequence eq $total) ?
      'tablebottomright' : 'tablerightdata';

    $i++;

    print start_Tr,
      td {-class  => $leftclass,
          -align  => 'center'}, $record{sequence};

    if ($record{sequence} eq $selected[$s]) {
      $s++;
      # Normalize fields
      my $pattern   = $record{pattern}   ? $record{pattern}   : '';
      my $domain    = $record{domain}    ? $record{domain}    : '';
      my $comment   = $record{comment}   ? $record{comment}   : '';
      my $hit_count = $record{hit_count} ? $record{hit_count} : '';

      print
        td {-class      => $dataclass,
            -align      => 'right'},
          (textfield {-class     => 'inputfield',
                      -style     => 'width:100%',
                      -align     => 'right',
                      -size      => 25,
                      -maxlength => '255',
                      -name      => "pattern$sequence",
                      -value     => $pattern}),
        td {-class      => $dataclass,
            -align      => 'center'}, '@',
        td {-class      => $dataclass},
          (textfield {-class     => 'inputfield',
                      -style     => 'width:100%',
                      -align     => 'left',
                      -size      => 25,
                      -maxlength => '255',
                      -name      => "domain$sequence",
                      -value     => $domain}),
        td {-class      => $dataclass},
           (textfield {-class     => 'inputfield',
                       -style     => 'width:100%',
                       -align     => 'left',
                       -size      => 25,
                       -maxlength => '255',
                       -name      => "comment$sequence",
                       -value     => $comment}),
        td {-class      => $rightclass},
           (textfield {-class     => 'inputfield',
                       -style     => 'width:100%',
                       -align     => 'left',
                       -size      => 25,
                       -maxlength => '255',
                       -name      => "hit_count$sequence",
                       -value     => $hit_count});
    } else {
      # Put in '&nbsp;' for undefined fields
      my $pattern   = $record{pattern}   ? $record{pattern}   : '&nbsp;';
      my $domain    = $record{domain}    ? $record{domain}    : '&nbsp;';
      my $comment   = $record{comment}   ? $record{comment}   : '&nbsp;';
      my $hit_count = $record{hit_count} ? $record{hit_count} : '&nbsp;';

      print
        td {-class => $dataclass,
            -align => 'right'}, $pattern,
        td {-class => $dataclass,
            -align => 'center'}, '@',
        td {-class => $dataclass,
            -align => 'left'}, $domain,
        td {-class => $dataclass,
            -align => 'left'}, $comment,
        td {-class => $rightclass,
            -align => 'left'}, $hit_count;
    } # if

    print end_Tr;
  } # foreach

  print end_table;
  print br,
    '<center>',
      submit ({-name    => 'update',
               -value   => 'Update',
               -onClick => 'return CheckEntry (document.list);'}),
      submit ({-name    => 'Reset',
               -value   => 'Reset',
               -onClick => 'history.back(); return false'}),
    '</center>';
  print end_form;

  return;
} # ModifyEntries

sub WhitelistMarked {
  AddNewEntry 'white', ReturnSequenceNbrs;
} # WhitelistMarked

sub BlacklistMarked {
  AddNewEntry 'black', ReturnSequenceNbrs;
} # BlacklistMarked

sub NulllistMarked {
  AddNewEntry 'null', ReturnSequenceNbrs;
} # NulllistMarked

# Main
$userid ||= $ENV{USER};

SetContext $userid;

my %options = GetUserOptions $userid;

$lines = $options{'Page'};

$total = MAPSDB::count 'list', "userid = \"$userid\" and type = \"$type\""
  if $type;

if ($action eq 'Add New Entry') {
  AddNewEntry $type;
} elsif ($action eq 'Delete Marked') {
  DeleteEntries $type;
} elsif ($action eq 'Modify Marked') {
  ModifyEntries $type;
} elsif ($action eq 'Whitelist Marked') {
  WhitelistMarked;
} elsif ($action eq 'Blacklist Marked') {
  BlacklistMarked;
} elsif ($action eq 'Nulllist Marked') {
  NulllistMarked;
} else {
  Heading (
    'getcookie',
    '',
    "Unknown action ($action)",
    "Unknown action ($action)"
  );

  NavigationBar $userid;
  DisplayError "Unknown action encountered ($action)";
} # if

Footing $table_name;

exit;
