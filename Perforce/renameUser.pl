#!/usr/bin/env perl
use strict;
use warnings;

=pod

=head1 NAME RenameUser.pl

Renames a Perforce user in Perforce

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: #1 $

=item Created

Fri Oct 30 12:16:39 PDT 2015

=item Modified

$Date: $

=back

=head1 SYNOPSIS

  $ RenameUser.pl [-oldusername <username> -newusername <username> |
                  -file <filename>] [-p4port <p4port>]
                  [-username <user>] [-password <password>]
                  [-[no]exec]  
                 
                  [-verbose] [-debug] [-help] [-usage]

  Where:

    -o|ldusername:  Old username to rename
    -ne|wusername:  New username
    -f|ile:         File of usernames to process 
                    (<oldusername> <newusername>)
    -p|4port:       Perforce port (Default: perforce:1666)
    -use|rname:     Username to log in as (Default: root)
    -p|assword:     Password for -username (Defaul: <root's password>)
    -[no]e|xec:     Whether or not to update the database

    -v|erbose:      Display verbose info about actions being taken
    -d|ebug:        Display debug info
    -h|elp:         Display full documentation
    -usa|ge:        Display usage

Note that -file is a list of whitespace separated usernames, one per line listed
as <oldusername> <newusername>

=head1 DESCRIPTION

This script will rename a Perforce user from -oldusername to -newusername. It
will also update the users email address.

=cut

use Getopt::Long;
use Pod::Usage;
use FindBin;

use lib "$FindBin::Bin/../lib";

use CMUtils;
use Display;
use Logger;
use Perforce;
use Utils;
use TimeUtils;

my ($p4, $log, $keys);

my %total;

my %opts = (
  p4port       => $ENV{P4PORT},
  username     => $ENV{P4USER},
  password     => $ENV{P4PASSWD},
  verbose      => $ENV{VERBOSE}        || sub { set_verbose },
  debug        => $ENV{DEBUG}          || sub { set_debug },
  usage        => sub { pod2usage },
  help         => sub { pod2usage (-verbose => 2)},
);

sub check4Dups (%) {
  my (%users) = @_;
  
  my %newusers;
  
  for my $key (keys %users) {
    my $value = $users{$key};
    
    if ($users{$value}) {
      $log->warn ("$value exists as both a key and a value");
    } else {
      $newusers{$key} = $users{$key};
    } # if
  } # for
  
  return %newusers;
} # check4Dups

sub renameUsers (%) {
  my (%users) = @_;

  for my $olduser (keys %users) {
    my $newuser = $users{$olduser};
    
    if ($opts{exec}) {
      if ($p4->getUser ($olduser)) {
        my $status = $p4->renameUser ($olduser, $newuser);
      
        unless ($status) {
          $log->msg ("Renamed $olduser -> $newuser");
          
          $total{'Users renamed'}++;
        } else {
          $log->err ("Unable to rename $olduser -> $newuser");
          
          return 1;
        } # unless
      } else {
        $total{'Non Perforce users'}++;
        
        $log->msg ("$olduser is not a Perforce user");
        
        next;
      } # if
    } else {
      $total{'Users would be renamed'}++;
        
      next;
    } # if

    my %user = $p4->getUser ($newuser);
    
    $log->err ("Unable to retrieve user info for $newuser", 1) unless %user;
    
    my $email = getUserEmail ($newuser);
    
    if ($user{Email} ne $email) {
      $user{Email} = $email;
      
      my $result = $p4->updateUser (%user);
      
      $log->err ("Unable to update user $newuser", 1) unless $result;
      
      $log->msg ("Updated ${newuser}'s email to $email");
      
      $total{'User email updated'}++;
    } # if
  } # for
  
  return $log->errors;
} # renameUsers

sub main () {
  GetOptions (
    \%opts,
    'verbose',
    'debug',
    'usage',
    'help',
    'jiradbserver=s',
    'username=s',
    'password=s',
    'file=s',
    'oldusername=s',
    'newusername=s',
    'exec!',
  ) or pod2usage;

  $opts{debug}   = get_debug   if ref $opts{debug}   eq 'CODE';
  $opts{verbose} = get_verbose if ref $opts{verbose} eq 'CODE';
  
  $log = Logger->new;
  
  if ($opts{username} && !$opts{password}) {
    $opts{password} = GetPassword;
  } # if

  $p4 = Perforce->new (%opts);

  my %users;

  my $startTime = time;

  if ($opts{oldusername} and $opts{newusername}) {
    $opts{oldusername} = lc $opts{oldusername};
    $opts{newusername} = lc $opts{newusername};
    
    $users{$opts{oldusername}} = $opts{newusername}; 
  } elsif ($opts{file}) {
    for (ReadFile $opts{file}) {
      my ($olduser, $newuser) = split;
      
      $users{lc $olduser} = lc $newuser;
    } # while
  } else {
    pod2usage "You must specify either -file or -oldname/-newname";
  } # if

  %users = check4Dups %users;
  
  my $status = renameUsers (%users);
  
  display_duration $startTime, $log;
  
  Stats \%total, $log;
  
  return $status;
} # main

exit main;