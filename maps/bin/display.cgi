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

use utf8;
use Encode;

use FindBin;
local $0 = $FindBin::Script;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use MAPS;
use MAPSWeb;

use CGI qw/:standard *table/;
use CGI::Carp "fatalsToBrowser";

use MIME::Parser;
use MIME::Base64;
use MIME::QuotedPrint;
use MIME::Words qw(:all);

binmode STDOUT, ':encoding(UTF-8)';

my $userid = cookie ('MAPSUser');
my $sender = param ('sender');
my $view   = param ('view');

# CGI will replace '+' with ' ', which many mailers are starting to do,
# so add it back
$sender =~ s/ /\+/;

my $msg_date   = param ('msg_date');
my $table_name = 'message';

sub ParseEmail(@) {
  my (@header) = @_;

  my %header;

  # First output the header information. Note we'll skip uninteresting stuff
  for (@header) {
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
    }    # if
  }    # for

  return %header;
}    # ParseEmail

sub GetDecodedContent($) {
  my ($part) = @_;

  my $encoding = $part->head->mime_attr ('Content-Transfer-Encoding') || '';
  my $charset  = $part->head->mime_attr ('Content-Type.charset') || 'Latin-1';
  my $body     = $part->bodyhandle->as_string;

  if ($encoding =~ /base64/i) {
    $body = decode_base64 ($body);
  } elsif ($encoding =~ /quoted-printable/i) {
    $body = decode_qp ($body);
  }

  eval {$body = decode ($charset, $body)};
  $body = decode ('Latin-1', $body) if $@;

  return $body;
}    # GetDecodedContent

sub FindBestPart($) {
  my ($entity) = @_;

  return $entity if $entity->mime_type !~ /multipart/;

  my $html_part;
  my $text_part;

  # Recursive search for best part
  my @queue = $entity->parts;
  while (@queue) {
    my $part = shift @queue;
    if ($part->mime_type eq 'text/html') {
      $html_part = $part;
      last;
    } elsif ($part->mime_type =~ /multipart/) {
      unshift @queue, $part->parts;
    } elsif ($part->mime_type =~ /text\/plain/) {
      $text_part ||= $part;
    }
  } ## end while (@queue)

  return $html_part || $text_part || ($entity->parts)[0];
}    # FindBestPart

if ($view && $view eq 'body') {
  my ($err, $msg) = FindEmail (
    userid    => $userid,
    sender    => $sender,
    timestamp => $msg_date,
  );

  my $rec    = GetEmail;
  my $parser = MIME::Parser->new ();
  $parser->output_to_core (1);
  $parser->tmp_to_core    (1);
  my $entity = $parser->parse_data ($rec->{data});

  my $part    = FindBestPart ($entity);
  my $content = GetDecodedContent ($part);
  my $type    = $part->mime_type;
  $type = 'text/plain' if $type !~ /text/;

  if ($type eq 'text/html') {

    # Disable links to prevent accidental clicking on malicious URLs
    my $css =
      qq{<style>a[title] { cursor: help; text-decoration: underline; }</style>};

    if ($content =~ /<\/head>/i) {
      $content =~ s/<\/head>/$css\n<\/head>/i;
    } else {
      $content = $css . "\n" . $content;
    }

    $content =~ s{<a\b([^>]*?)\bhref\s*=\s*(?:(["'])(.*?)\2|([^>\s]+))([^>]*)>}{
      my $pre = $1;
      my $url = defined $3 ? $3 : $4;
      my $post = $5;
      $url =~ s/"/&quot;/g;
      qq{<a$pre title="$url"$post>};
    }geisi;
  } ## end if ($type eq 'text/html')

  print header (-type => "$type; charset=utf-8");
  print $content;
  exit;
}    # if ($view && $view eq 'body')

sub Body($) {
  my ($date) = @_;

  # Find unique message using $date
  my ($err, $msg) = FindEmail (
    userid    => $userid,
    sender    => $sender,
    timestamp => $date,
  );

  my $rec = GetEmail;

  my $parser = MIME::Parser->new ();

  # For some strange reason MIME::Parser has started having some problems
  # with writing out tmp files...
  $parser->output_to_core (1);
  $parser->tmp_to_core    (1);

  my $entity = $parser->parse_data ($rec->{data});

  my %header = ParseEmail @{($entity->header)[0]};

  print p . "\n";
  print start_table ({
      -align       => "center",
      -id          => $table_name,
      -border      => 0,
      -cellspacing => 0,
      -cellpadding => 0,
      -width       => "100%"
    }
  );
  print start_table ({
      -align   => "center",
      -bgcolor => 'steelblue',

      #-bgcolor      => "#d4d0c8",
      -border      => 0,
      -cellspacing => 2,
      -cellpadding => 2,
      -width       => "100%"
    }
  ) . "\n";
  print "<tbody><tr><td>\n";
  print start_table ({
      -align       => "center",
      -border      => 0,
      -cellspacing => 0,
      -cellpadding => 2,
      -bgcolor     => 'black',

      #-bgcolor      => "#ece9d8",
      -width => "100%"
    }
  ) . "\n";

  for (keys (%header)) {
    next if /base64/;

    my $str = decode_mimewords ($header{$_});

    print Tr ([
        th ({
            -align   => 'right',
            -bgcolor => 'steelblue',
            -style   => 'color: white',

            #-bgcolor  => "#ece9d8",
            -width => "8%"
          },
          ucfirst "$_:"
          )
          . "\n"
          . td ({-bgcolor => 'white'}, $str)
      ]
    );
  }    # for

  print end_table;
  print "</td></tr>";
  print end_table;

  print start_table ({
      -align       => 'center',
      -bgcolor     => 'steelblue',
      -border      => 0,
      -cellspacing => 0,
      -cellpadding => 2,
      -width       => "100%"
    }
  ) . "\n";
  print "<tbody><tr><td>\n";
  print start_table ({
      -align       => "center",
      -border      => 0,
      -cellspacing => 0,
      -cellpadding => 2,
      -bgcolor     => 'white',
      -width       => "100%"
    }
  ) . "\n";
  print "<tbody><tr><td>\n";

  my $safe_sender = CGI::escape ($sender);
  my $safe_date   = CGI::escape ($msg_date);

  print
qq{<iframe src="display.cgi?sender=$safe_sender;msg_date=$safe_date;view=body"
                   width="100%"
                   height="600"
                   frameborder="0"
                   sandbox>
           </iframe>};

  print "</td></tr>\n";
  print end_table;
  print "</td></tr>\n";
  print end_table;
  print end_table;
}    # Body

$userid = Heading (
  'getcookie', '',
  "Email message from $sender",
  "Email message from $sender",
  '', $table_name,
);

$userid //= $ENV{USER};

SetContext    ($userid);
NavigationBar ($userid);

Body ($msg_date);

Footing ($table_name);
