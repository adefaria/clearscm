#!/usr/bin/perl
use strict;
use warnings;

=pod

=pod

=head1 NAME $RCSfile: cqinfo.pl,v $

Clearquest Info

This script takes some parameters and gets information from a Clearquest
database.

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 1.6 $

=item Created:

Mon Jul 30 12:05:45 PDT 2012

=item Modified:

$Date: 2013/03/15 00:19:36 $

=back

=head1 SYNOPSIS

 Usage: cqinfo.pl [-u|sage] [-v|erbose] [-d|ebug]
                  [-username <username>] [-password <password>]
                  [-database <dbname>] [-dbset <dbset>]
                  [-record <record>] [-key <key>]
                  [-fields <field1>,<field2>,...]
                  [-module] [-server <server>] [-port <port>]
                  
 Where:
   -u|sage:     Displays usage
   -v|erbose:   Be verbose
   -de|bug:     Output debug messages

   -r|ecord:    Record to interrogate (Default: Defect)
   -k|ey:       Key to locate the record with (Note that if you supply
                simply a number (e.g. 1234) then we will expand that with
                leading zeroes to the length of 8 digits and prepend the
                database name)
   -f|ields:    List of fields to display (Default: All fields)
                
   -use|rname:  Username to open database with (Default: from config file) 
   -p|assword:  Password to open database with (Default: from config file) 
   -da|tabase:  Database to open (Default: from config file)
   -db|set:     Database Set to use (Default: from config file)
   -m|odule:    Type of Clearquest module to use. Must be one of 'api', 
                'client', or 'rest'. The 'api' module can only be used if
                Clearquest is installed locally. The 'client' module can
                only be successful if a corresponding server is running. And
                the 'rest' module can only be used if a CQ Web server has
                been set up and configured (Default: rest)
   -s|erver:    For module = client or rest this is the name of the server 
                that will be providing the service
   -p|ort:      For module = client, this is the point on the server to talk
                through.

=head1 Options

Options are keep in the cq.conf file in etc. They specify the default options
listed below. Or you can export the option name to the env(1) to override the
defaults in cq.conf. Finally you can programmatically set the options when you
call new by passing in a %parms hash. To specify the %parms hash key remove the
CQ_ portion and lc the rest.

=for html <blockquote>

=over

=item CQ_WEBHOST

The web host to contact with leading http://

=item CQ_DATABASE

Name of database to connect to (Default: from config file)

=item CQ_USERNAME

User name to connect as (Default: from config file)

=item CQ_PASSWORD

Password for CQ_USERNAME

=item CQ_DBSET

Database Set name (Default: from config file)

=item CQ_SERVER

Clearquest::Server name to connect to (Default: from config file)

=item CQ_PORT

Clearquest::Server port to connect to (Default: from config file)

=back

=cut

use FindBin;
use Getopt::Long;

use lib "$FindBin::Bin/../lib";

use Clearquest;
use Display;
use Utils;

my %opts;

GetOptions (
  \%opts,
  usage   => sub { Usage },
  verbose => sub { set_verbose },
  debug   => sub { set_debug },
  'module=s',
  'username=s',
  'password=s',
  'database=s',
  'dbset=s',
  'record=s',
  'key=s',
  'server=s',
  'port=i',
  'fields=s@',
) || Usage;

Usage "You must specify -key" unless $opts{key};

$opts{module} = lc $opts{module} if $opts{module};

# Default to Defect
my $record = delete $opts{record} || 'Defect';
my $key    = delete $opts{key};
my @fields;

if ($opts{fields}) {
  push @fields, split /\s*,\s*/ foreach (@{$opts{fields}});
} # if

# Translate any options to ones that the lib understands
$opts{CQ_USERNAME} = delete $opts{username};
$opts{CQ_PASSWORD} = delete $opts{password};
$opts{CQ_DATABASE} = delete $opts{database};
$opts{CQ_DBSET}    = delete $opts{dbset};
$opts{CQ_SERVER}   = delete $opts{server};
$opts{CQ_PORT}     = delete $opts{port};

my $cq;

my $module = delete $opts{module};

$cq = Clearquest->new (%opts);

$cq->connect;

# Fix key if necessary
if ($key =~ /^(\d+)$/) {
  $key = $cq->{database} . 0 x (8 - length $1) . $1;
} # if 

my %record = $cq->get ($record, $key, @fields);

unless ($cq->error) {
  foreach my $field (sort keys %record) {
    if (ref $record{$field} eq 'ARRAY') {
      display "$field (LIST):";
      
      display "\t$_" foreach (@{$record{$field}});
    } else {
      display_nolf "$field: ";
      
      if ($record{$field}) {
        display $record{$field};
      } else {
        display '<undef>';
      } # if
    } # if
  } # foreach

  exit 0;
} else {
  error "Unable to get $record with key $key\n" . $cq->errmsg, $cq->error;
} # unless
