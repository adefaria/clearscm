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

use lib "$FindBin::Bin/../lib";

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

  for (@names) {
    if (/action(\d+)/) {
      push @sequence_nbrs, $1;
    } # if
  } # for

  return @sequence_nbrs;
} # ReturnSequenceNbrs

sub DeleteEntries {
  my ($type) = @_;

  my @sequence_nbrs = ReturnSequenceNbrs;

  my $count;

  for (@sequence_nbrs) {
    my ($err, $msg) = DeleteList(
      userid   => $userid,
      type     => $type,
      sequence => $_, 
    );

    # How to best handle error?
    croak $msg if $err < 0;

    $count += $err;
  } # for

  if ($count == 0) {
    DisplayError('Nothing to delete!');
  } else {
    ResequenceList(
      userid => $userid,
      type   => $type
    );

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
  my $retention = '';
  my $hit_count = '';

  if (defined $email_nbr && $email_nbr ne '') {
    $email = param "email$email_nbr";
    if ($email && $email ne '') {
      ($pattern, $domain) = split /\@/, $email;
    } # if

    $hit_count = CountMsg($email);
  } # if

  print Tr [
    td {-class      => $leftclass,
        -align      => 'center'}, "$nextseq",
    td {-class      => $dataclass,
        -align      => 'right'},
      (textfield {-class     => 'inputfieldright',
                  -style     => 'width:100%',
                  -size      => 25,
                  -maxlength => '255',
                  -name      => "pattern$nextseq",
                  -value     => $pattern}),
    td {-class      => $dataclass,
        -align      => 'center'}, '@',
    td {-class      => $dataclass},
      (textfield {-class      => 'inputfield',
                  -style      => 'width:100%',
                  -size       => 25,
                  -maxlength  => '255',
                  -name       => "domain$nextseq",
                  -value      => $domain}),
    td {-class      => $dataclass},
      (textfield {-class     => 'inputfieldright',
                  -style     => 'width:100%',
                  -size      => 25,
                  -maxlength => '255',
                  -name      => "hit_count$nextseq",
                  -value     => $hit_count}),
    td {-class      => $dataclass},
      (textfield {-class      => 'inputfieldright',
                  -style      => 'width:100%',
                  -size       => 20,
                  -maxlength  => '40',
                  -name       => "retention$nextseq",
                  -value      => $retention}),
    td {-class      => $rightclass},
      (textfield {-class     => 'inputfield',
                  -style     => 'width:100%',
                  -size      => 25,
                  -maxlength => '255',
                  -name      => "comment$nextseq",
                  -value     => ''}),
  ];

  return;
} # PrintInputLine

sub AddNewEntry {
  my ($type, @selected)  = @_;

  # First display the last page and add the appropriate number of
  # empty, editable entries (possibly filled in) for the user to add
  # the new entry
  my $selected = @selected;
  my $nextseq = GetNextSequenceNo(
    userid => $userid,
    type   => $type,
  );

  my $next = ($nextseq - $lines) + $selected - 1;

  $next = 0 if $next < 0;

  my $Type = ucfirst $type;

  Heading(
    'getcookie',
    '',
    "Add to $Type List",
    "Add to $Type List",
    '',
    $table_name,
    @scripts
  );

  NavigationBar($userid);

  # Now display table and new entry
  print start_form {
    -method => 'post',
    -action => "add2${type}list.cgi",
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
    th {-class => 'tableheader'},   'Hit Count',
    th {-class => 'tableheader'},   'Retention',
    th {-class => 'tablerightend'}, 'Comments',
  ];

  my $list = ReturnList(
    userid   => $userid,
    type     => $type,
    start_at => $next,
    lines    => $lines,
  );

  my $i = 1;

  for my $record (@$list) {
    $i++;

    # Normalize fields
    $record->{pattern}   //= '&nbsp;';
    $record->{domain}    //= '&nbsp;';
    $record->{comment}   //= '&nbsp;';
    $record->{hit_count} //= '&nbsp;';
    $record->{retention} //= '&nbsp;';

    print Tr [
      td {-class  => 'tableleftdata',  -align  => 'center'}, $record->{sequence},
      td {-class  => 'tabledata',      -align  => 'right'},  $record->{pattern},
      td {-class  => 'tabledata',      -align  => 'center'}, '@',
      td {-class  => 'tabledata',      -align  => 'left'},   $record->{domain},
      td {-class  => 'tabledata',      -align  => 'right'},  $record->{hit_count},
      td {-class  => 'tabledata',      -align  => 'right'},  $record->{retention},
      td {-class  => 'tablerightdata', -align  => 'left'},   $record->{comment},
    ];
  } # for

  # Now the input line(s)
  if (@selected == 0) {
    PrintInputLine($nextseq, undef, 'tablebottomleft', 'tablebottomdata',
                                    'tablebottomright');
  } else {
    for (@selected) {
      my $leftclass  = $i == $lines ? 'tablebottomleft'  : 'tableleftdata';
      my $dataclass  = $i == $lines ? 'tablebottomdata'  : 'tabledata';
      my $rightclass = $i == $lines ? 'tablebottomright' : 'tablerightdata';
      $i++;
      PrintInputLine($nextseq++, $_, $leftclass, $dataclass, $rightclass);
    } # for
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

  Heading(
    'getcookie',
    '',
    "Modify $Type List",
    "Modify $Type List",
    '',
    $table_name,
    @scripts
  );

  NavigationBar($userid);

  # Redisplay the page but open up the lines that are getting modified
  print start_form {
    -method  => 'post',
    -action  => 'modifyentries.cgi',
    -name    => 'list'
  };

  # Print some hidden fields to pass along
  print hidden ({-name    => 'type', -default => $type}),
        hidden ({-name    => 'next', -default => $next});

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
    th {-class => 'tableheader'},   'Hit Count',
    th {-class => 'tableheader'},   'Retention',
    th {-class => 'tablerightend'}, 'Comments',
  ];

  my $list = ReturnList(
    userid   => $userid,
    type     => $type,
    start_at => $next,
    lines    => $lines,
  );

  my $s = 0;
  my $i = 1;

  for my $record (@$list) {
    my $leftclass  = ($i == @$list || $record->{sequence} eq $total) ?
      'tablebottomleft'  : 'tableleftdata';
    my $dataclass  = ($i == @$list || $record->{sequence} eq $total) ?
      'tablebottomdata'  : 'tabledata';
    my $rightclass = ($i == @$list || $record->{sequence} eq $total) ?
      'tablebottomright' : 'tablerightdata';

    $i++;

    print start_Tr,
      td {-class  => $leftclass,
          -align  => 'center'}, $record->{sequence};

    if ($selected[$s] and $record->{sequence} eq $selected[$s]) {
      $s++;
      # Normalize fields
      $record->{pattern}   //= '';
      $record->{domain}    //= '';
      $record->{comment}   //= '';
      $record->{hit_count} //= '';
      $record->{retention} //= '';

      print
        td {-class               => $dataclass,
            -align               => 'right'},
          (textfield {-class     => 'inputfieldright',
                      -style     => 'width:100%',
                      -align     => 'right',
                      -size      => 25,
                      -maxlength => '255',
                      -name      => "pattern$record->{sequence}",
                      -value     => $record->{pattern}}),
        td {-class               => $dataclass,
            -align               => 'center'}, '@',
        td {-class               => $dataclass},
          (textfield {-class     => 'inputfield',
                      -style     => 'width:100%',
                      -align     => 'left',
                      -size      => 25,
                      -maxlength => '255',
                      -name      => "domain$record->{sequence}",
                      -value     => $record->{domain}}),
        td {-class               => $dataclass},
          (textfield {-class     => 'inputfieldright',
                      -style     => 'width:100%',
                      -align     => 'left',
                      -size      => 25,
                      -maxlength => '255',
                      -name      => "hit_count$record->{sequence}",
                      -value     => $record->{hit_count}}),
        td {-class               => $dataclass},
          (textfield {-class     => 'inputfieldright',
                      -style     => 'width:100%',
                      -align     => 'left',
                      -size      => 25,
                      -maxlength => '40',
                      -name      => "retention$record->{sequence}",
                      -value     => $record->{retention}}),
        td {-class               => $rightclass},
          (textfield {-class     => 'inputfield',
                      -style     => 'width:100%',
                      -align     => 'left',
                      -size      => 25,
                      -maxlength => '255',
                      -name      => "comment$record->{sequence}",
                      -value     => $record->{comment}});
    } else {
      # Normalize fields
      # Put in '&nbsp;' for undefined fields
      $record->{pattern}   //= '&nbsp;';
      $record->{domain}    //= '&nbsp;';
      $record->{comment}   //= '&nbsp;';
      $record->{hit_count} //= '&nbsp;';
      $record->{retention} //= '&nbsp;';

      print
        td {-class => $dataclass,
            -align => 'right'}, $record->{pattern},
        td {-class => $dataclass,
            -align => 'center'}, '@',
        td {-class => $dataclass,
            -align => 'left'}, $record->{domain},
        td {-class => $dataclass,
            -align => 'right'}, $record->{hit_count},
        td {-class => $dataclass,
            -align => 'right'}, $record->{retention},
        td {-class => $rightclass,
            -align => 'left'}, $record->{comment};
    } # if

    print end_Tr;
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
} # ModifyEntries

sub WhitelistMarked {
  AddNewEntry('white', ReturnSequenceNbrs);

  return;
} # WhitelistMarked

sub BlacklistMarked {
  AddNewEntry('black', ReturnSequenceNbrs);

  return;
} # BlacklistMarked

sub NulllistMarked {
  AddNewEntry('null', ReturnSequenceNbrs);

  return;
} # NulllistMarked

# Main
$userid ||= $ENV{USER};

SetContext($userid);

my %options = GetUserOptions($userid);

$lines = $options{'Page'};

$total = CountList(
  userid => $userid,
  type   => $type,
) if $type;

if ($action eq 'Add') {
  AddNewEntry($type);
} elsif ($action eq 'Delete') {
  DeleteEntries($type);
} elsif ($action eq 'Modify') {
  ModifyEntries($type);
} elsif ($action eq 'Whitelist') {
  WhitelistMarked;
} elsif ($action eq 'Blacklist') {
  BlacklistMarked;
} elsif ($action eq 'Nulllist') {
  NulllistMarked;
} else {
  Heading(
    'getcookie',
    '',
    "Unknown action ($action)",
    "Unknown action ($action)"
  );

  NavigationBar($userid);
  DisplayError("Unknown action encountered ($action)");
} # if

Footing($table_name);

exit;
