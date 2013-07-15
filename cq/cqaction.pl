#!/usr/bin/perl
use strict;
use warnings;

=pod

=pod

=head1 NAME $RCSfile: cqaction.pl,v $

Clearquest Action

This script attempt to apply an action to a statefull Clearquest record. 

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 2.2 $

=item Created:

Mon Jul 30 12:05:45 PDT 2012

=item Modified:

$Date: 2012/12/18 19:44:10 $

=back

=head1 SYNOPSIS

 Usage: cqaction.pl [-u|sage] [-v|erbose] [-d|ebug]
                    [-username <username>] [-password <password>]
                    [-database <dbname>] [-dbset <dbset>]
                    [-record <record>] [-key <key>]
                    [-action <action>]
                    [-module] [-server <server>] [-port <port>]
                         
                  
 Where:
   -u|sage:     Displays usage
   -v|erbose:   Be verbose
   -de|bug:     Output debug messages

   -record:     Record to apply the action to (Default: Defect)
   -key:        Key to locate the record with (Note that if you supply simply
                a number (e.g. 1234) then we will expand that with leading
                zeroes to the length of 8 digits and prepend the database name)   
   -action:     Action to apply (Default: Modify)

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

=head1 Modifying fields while changing state

If you need to modify fields while changing state then feed them to this 
script's stdin in the form of:

 <field>=<value>

B<Note:> Don't forget that you will be prompted field=value and you'll need
to signal that you have entered all of the field/value pairs you intended with
Ctrl-D (or Ctrl-Z on Windows). You can short circut this by feeding something
like /dev/null to stdin like so:

  $ cat /dev/null > cqaction.pl <parms>
 
=cut

use FindBin;
use Getopt::Long;

use lib "$FindBin::Bin/../lib";

use Display;
use Utils;

my %opts;

sub getFields () {
  my %values;
  
  verbose "Enter <field>=<value> pairs and Ctrl-D to end input";
  
  while (<STDIN>) {
    if (/^(\s+)(=|:)(\.*)/) {
      $values{$1} = $2;
    } # if
  } # while
  
  verbose "All <field>=<value> pairs accepted";
  
  return %values;
} # getFields

$opts{module} = 'rest';

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
  'action=s',
) || Usage;

Usage "You must specify -key" unless $opts{key};

# Default to Defect
my $record = delete $opts{record} || 'Defect';
my $key    = delete $opts{key};
my $action = delete $opts{action} || 'Modify';

# Translate any options to ones that the lib understands
$opts{CQ_USERNAME} = delete $opts{username};
$opts{CQ_PASSWORD} = delete $opts{password};
$opts{CQ_DATABASE} = delete $opts{database};
$opts{CQ_DBSET}    = delete $opts{dbset};
$opts{CQ_SERVER}   = delete $opts{server};
$opts{CQ_PORT}     = delete $opts{port};

my $cq;

my $module = lc delete $opts{module};

if ($module eq 'rest') {
  require Clearquest::REST;
  
  $cq = Clearquest::REST->new (%opts);
} elsif ($module eq 'client') {
  require Clearquest::Client;
  
  $cq = Clearquest::Client->new (%opts);
  
  $cq->connect;
} elsif ($module eq 'api') {
  require Clearquest;
  
  $cq = Clearquest->new (%opts);

  $cq->connect;
} else {
  Usage "Invalid module - $opts{module}";
} # if

# Fix key if necessary
if ($key =~ /^(\d+)$/) {
  $key = $cq->{database} . 0 x (8 - length $1) . $1;
} # if 

my %values = getFields;

my $errmsg = $cq->modify ($record, $key, $action, %values);

unless ($cq->cqerror) {
  verbose "Successfully applied $action to $record:$key";
  
  exit 0;
} else {
  error "Unable to apply $action to $record:$key\n" . $cq->cqerrmsg, $cq->cqerror;
} # unless