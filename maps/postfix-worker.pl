#!/usr/bin/perl

=pod

=head1 NAME postfix-worker.pl

Add offending phishing / spoofed domains directly to Postfix sender_access map and rebuild hash database.

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@DeFaria.com>

=item Created:

Mon Oct 19 09:50:00 PDT 2026

=back

=head1 SYNOPSIS

 Usage: postfix-worker.pl [-h|elp] [-v|erbose] [-d|ry-run]
                          [--access-file=<path>]
                          [--postmap=<path>]
                          [--no-wildcard]
                          [--action=<directive>]
                          <domain>

  Where:
   -h|elp         Print this help message
   -v|erbose      Verbose progress messages
   -d|ry-run      Show what would be added without modifying files
   --access-file  Path to Postfix sender_access file (Default: /etc/postfix/sender_access)
   --postmap      Path to postmap executable (Default: /usr/sbin/postmap)
   --action       Postfix action directive (Default: "REJECT Phishing / Spoofed domain")
   --no-wildcard  Do not add dot-prefixed wildcard entry (.domain)
   <domain>       The domain to block

=cut

use strict;
use warnings;

use Getopt::Long;
use File::Basename qw(dirname);
use Pod::Usage;

# Options
my $help        = 0;
my $verbose     = 0;
my $dry_run     = 0;
my $wildcard    = 1;
my $action      = 'REJECT Phishing / Spoofed domain';
my $access_file = $ENV{MAPS_POSTFIX_ACCESS_FILE} || '/etc/postfix/sender_access';
my $postmap_bin = $ENV{MAPS_POSTMAP_BIN}          || '/usr/sbin/postmap';
my $cli_domain  = '';

GetOptions(
  'help|h|?'       => \$help,
  'verbose|v'      => \$verbose,
  'dry-run|d'      => \$dry_run,
  'wildcard!'      => \$wildcard,
  'action=s'       => \$action,
  'access-file=s'  => \$access_file,
  'postmap=s'      => \$postmap_bin,
  'domain=s'       => \$cli_domain,
) or pod2usage(2);

pod2usage(1) if $help;

# Retrieve domain from positional argument if not passed as option
my $target_domain = $cli_domain || shift @ARGV;

if (!$target_domain) {
  warn "Error: No domain specified to block.\n";
  pod2usage(2);
}

# Normalize and sanitize domain
$target_domain = lc($target_domain);
$target_domain =~ s/^\.+//; # Remove leading dots
$target_domain =~ s/\s+//g; # Remove any whitespace

# Strict domain validation regex
if ($target_domain !~ /^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$/) {
  die "Error: Invalid domain format '$target_domain'\n";
}

# Sanitize action directive
$action =~ s/[\r\n]//g;

# Ensure parent directory exists
my $dir = dirname($access_file);
if (!-d $dir) {
  die "Error: Directory for access file does not exist: $dir\n";
}

# Read existing entries to prevent duplicates
my %existing_entries;
if (-f $access_file) {
  open my $rfh, '<', $access_file or die "Cannot read $access_file: $!\n";
  while (<$rfh>) {
    chomp;
    s/^\s+//;
    next if /^#/ || /^$/;
    if (/^(\S+)/) {
      $existing_entries{lc($1)} = 1;
    }
  }
  close $rfh;
}

my @lines_to_append;

# Base domain
if (!$existing_entries{$target_domain}) {
  push @lines_to_append, sprintf("%-30s %s\n", $target_domain, $action);
  $existing_entries{$target_domain} = 1;
}

# Subdomain wildcard entry (.domain)
if ($wildcard) {
  my $wildcard_entry = ".$target_domain";
  if (!$existing_entries{$wildcard_entry}) {
    push @lines_to_append, sprintf("%-30s %s\n", $wildcard_entry, $action);
    $existing_entries{$wildcard_entry} = 1;
  }
}

if (!@lines_to_append) {
  print "Domain '$target_domain' is already present in $access_file.\n" if $verbose;
  exit 0;
}

if ($dry_run) {
  print "--- DRY RUN: Would append to $access_file ---\n";
  print @lines_to_append;
  exit 0;
}

# Append entries to access_file
open my $wfh, '>>', $access_file or die "Cannot open $access_file for writing: $!\n";
for my $line (@lines_to_append) {
  print $wfh $line;
}
close $wfh;

print "Appended " . scalar(@lines_to_append) . " line(s) for '$target_domain' to $access_file.\n" if $verbose;

# Execute postmap to recompile hash map
if (-x $postmap_bin) {
  print "Rebuilding Postfix map: $postmap_bin $access_file\n" if $verbose;
  my $rc = system($postmap_bin, $access_file);
  if ($rc != 0) {
    my $err = $?;
    die "Error: postmap command failed with exit code $err ($!)\n";
  }
} else {
  warn "Warning: Postmap executable not found or not executable at $postmap_bin\n";
}

print "Domain '$target_domain' blocked successfully in Postfix.\n" if $verbose;
exit 0;
