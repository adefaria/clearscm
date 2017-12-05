#!/usr/bin/perl
################################################################################
#
# File:         $RCSfile: display.cgi,v $
# Revision:     $Revision: 1.1 $
# Description:  Displays an email message
# Author:       Andrew@DeFaria.com
# Created:      Fri Nov 29 14:17:21  2002
# Modified:     $Date: 2013/06/12 14:05:47 $
# Language:     perl
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

use CGI qw/:standard *table/;
use CGI::Carp "fatalsToBrowser";

use MIME::Parser;
use MIME::Base64;
use MIME::Words qw(:all);

my $userid      = cookie('MAPSUser');
my $sender      = param('sender');
my $msg_nbr     = param('msg_nbr');
my $table_name  = 'message';

sub ParseEmail (@) {
  my (@header) = @_;

  my %header;

  # First output the header information. Note we'll skip uninteresting stuff
  foreach (@header) {
    last if ($_ eq '' || $_ eq "\cM");

    # Escape "<" and ">"
    s/\</\&lt\;/;
    s/\>/\&gt\;/;

    if (/^from:\s*(.*)/i) {
      $header{From} = $1;
    } elsif (/^subject:\s*(.*)/i) {
      $header{Subject} = $1;
    } elsif (/^date:\s*(.*)/i) {
      $header{date} = $1;
    } elsif (/^To:\s*(.*)/i) {
      $header{to} = $1;
    } elsif (/^Content-Transfer-Encoding: base64/) {
      $header{base64} = 1;
    } # if
  } # while

  return %header;
} # ParseEmail

sub Body ($) {
  my ($count) = @_;

  $count ||= 1;

  my $handle = FindEmail $sender;

  my ($userid, $sender, $subject, $timestamp, $message);

  # Need to handle multiple messages
  for (my $i = 0; $i < $count; $i++) {
    ($userid, $sender, $subject, $timestamp, $message) = GetEmail $handle;
  } # for

  my $parser = new MIME::Parser;

  $parser->output_to_core (1);

  my $entity = $parser->parse_data ($message);

  my %header = ParseEmail @{($entity->header)[0]};

  print p . "\n";
    print start_table ({-align        => "center",
                        -id           => $table_name,
                        -border       => 0,
                        -cellspacing  => 0,
                        -cellpadding  => 0,
                        -width        => "100%"});
    print start_table ({-align        => "center",
                        -bgcolor      => "#d4d0c8",
                        -border       => 0,
                        -cellspacing  => 2,
                        -cellpadding  => 2,
                        -width        => "100%"}) . "\n";
    print "<tbody><tr><td>\n";
    print start_table ({-align        => "center",
                        -border       => 0,
                        -cellspacing  => 0,
                        -cellpadding  => 2,
                        -bgcolor      => "#ece9d8",
                        -width        => "100%"}) . "\n";

    foreach (keys (%header)) {
      next if /base64/;

      my $str = decode_mimewords ($header{$_});

      print Tr ([
        th ({-align    => "right",
             -bgcolor  => "#ece9d8",
             -width    => "8%"}, "$_:") . "\n" .
        td ({-bgcolor  => "white"}, $str)
      ]);
    } # if

    print end_table;
    print "</td></tr>";
    print end_table;

  print start_table ({-align        => "center",
                      -bgcolor      => "black",
                      -border       => 0,
                      -cellspacing  => 0,
                      -cellpadding  => 2,
                      -width        => "100%"}) . "\n";
  print "<tbody><tr><td>\n";
  print start_table ({-align        => "center",
                      -border       => 0,
                      -cellspacing  => 0,
                      -cellpadding  => 2,
                      -bgcolor      => "white",
                      -width        => "100%"}) . "\n";
  print "<tbody><tr><td>\n";

  my @parts = $entity->parts;

  if (scalar @parts == 0) {
    print '<pre>';
    $entity->print_body;
    print '</pre>';
  } else {
    foreach my $part ($entity->parts) {
      # We assume here that if this part is multipart/alternative then
      # there exists at least one part that is text/html and we favor
      # that (since we're outputing to a web page anyway...
      if ($part->mime_type eq 'multipart/alternative') {
        foreach my $subpart ($part->parts) {
          if ($subpart->mime_type eq 'text/html') {
            # There should be an easier way to get this but I couldn't find one.
            my $encoding = ${$subpart->{mail_inet_head}{mail_hdr_hash}{'Content-Transfer-Encoding'}[0]};
            if ($encoding =~ /base64/) {
              $subpart->bodyhandle->print();
            } else {
              $subpart->print_body;
            } # if
            last;
          } elsif ($subpart->mime_type eq 'multipart/related') {
            # This is stupid - multipart/related? When it's really just HTML?!?
            $subpart->print_body;
            last;
          } # if
        } # foreach
      } else {
        if ($part->mime_type =~ /text/) {
          print '<pre>';
          $part->print_body;
          print '</pre>';
        } # if
      } # if
    } # foreach
  } # if

  print "</td></tr>\n";
  print end_table;
  print "</td></tr>\n";
  print end_table;
  print end_table;
} # Body

$userid = Heading (
  'getcookie',
  '',
  "Email message from $sender",
  "Email message from $sender",
  '',
  $table_name,
);

SetContext $userid;
NavigationBar $userid;

Body $msg_nbr;

Footing $table_name;
