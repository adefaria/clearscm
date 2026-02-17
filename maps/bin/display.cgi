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
my $theme  = cookie ('theme');
if (!$theme && $ENV{HTTP_COOKIE}) {
  if ($ENV{HTTP_COOKIE} =~ /theme=([^;]+)/) {
    $theme = $1;
  }
}

# Default to light mode for mobile users if no specific theme is set
if (!$theme
  && $ENV{HTTP_USER_AGENT}
  && $ENV{HTTP_USER_AGENT} =~ /(Mobile|Android|iPhone|iPad|iPod)/i)
{
  $theme = 'light';
} ## end if (!$theme && $ENV{HTTP_USER_AGENT...})

$theme //= '';
my $sender = param ('sender');
my $view   = param ('view');

# CGI will replace '+' with ' ', which many mailers are starting to do,
# so add it back
$sender =~ s/ /\+/;

my $msg_date   = param ('msg_date');
my $table_name = 'message';

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

  if ($charset =~ /^(Latin-1|ISO-8859-1)$/i) {

    # Try UTF-8 first for default charsets
    eval {$body = decode ('UTF-8', $body, Encode::FB_CROAK)};
    if ($@) {

      # Fallback to declared charset
      eval {$body = decode ($charset, $body)};
    }
  } else {
    eval {$body = decode ($charset, $body)};
  }
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

  if ($type eq 'text/plain') {
    $content = escapeHTML ($content);
    my $style_time = time ();
    $content = $content =
"<html data-theme='$theme'><head><link rel='stylesheet' href='/css/style.css'><link rel='stylesheet' href='/maps/css/MAPSStyle.css'></head><body style='background-color: var(--bg-color); color: var(--text-color);'><pre>$content</pre></body></html>";
    $type = 'text/html';
  } ## end if ($type eq 'text/plain')

  if ($type eq 'text/html') {

    # Disable links to prevent accidental clicking on malicious URLs
    my $style_time = time ();
    my $css =
qq{<script>if('$theme')document.documentElement.setAttribute('data-theme','$theme');</script><link rel='stylesheet' href='/css/style.css'><link rel='stylesheet' href='/maps/css/MAPSStyle.css'><style>body { background-color: var(--bg-color) !important; color: var(--text-color) !important; } a[title] { cursor: copy; text-decoration: underline; color: var(--google-blue); }</style>};

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

  print header (
    -type          => "$type; charset=utf-8",
    -cache_control => 'no-cache, no-store, must-revalidate',
    -pragma        => 'no-cache',
    -expires       => '0',
  );
  print $content;
  exit;
}    # if ($view && $view eq 'body')

$userid = Heading (
  'getcookie', '',
  "Email message from $sender",
  "Email message from $sender",
  '', $table_name,
);

$userid //= $ENV{USER};

SetContext    ($userid);
NavigationBar ($userid);

print MAPSWeb::GetMessageDisplay (
  userid     => $userid,
  sender     => $sender,
  msg_date   => $msg_date,
  table_name => $table_name
);

Footing ($table_name);
