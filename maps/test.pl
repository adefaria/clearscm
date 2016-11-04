#!/usr/bin/perl
use strict;
use warnings;

use lib "/opt/clearscm/lib";

use Display;
use Utils;
use Net::SMTP;

my %config = (
  SMTPHOST => 'defaria.com',
);

sub DeliverMsg ($) {
  my ($msg) = @_;
  
  my $smtp = Net::SMTP->new ($config{SMTPHOST})
    or error "Unable to connect to mail server: $config{SMTPHOST}", 1;
  
  $smtp->mail ('Andrew@DeFaria.com');
  
  $smtp->to ('adefaria@gmail.com');
  
  $smtp->data;
  $smtp->datasend ('From: Andrew@DeFaria.com');
  $smtp->datasend ('To: adefaria@gmail.com');
  $smtp->datasend ('Subject: Forwarded mail');
  $smtp->datasend ('Content-Type: plain/text');
  $smtp->datasend ("\n");
  $smtp->datasend ($msg);
  $smtp->dataend;
  $smtp->quit;
  
  return;    
} # DeliverMsg

my $msg = ReadFile 'test.msg';

DeliverMsg ($msg);

display 'done';