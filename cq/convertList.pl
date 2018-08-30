#!/usr/bin/perl
use strict;
use warnings;

=pod

=head1 NAME $RCSfile: convertList.pl,v $

This script allows you to convert a Clearquest Dynamic List to a stateless
table. You must specify what the dynamic list name is, the stateless table name
you wish to convert it to and the field name that serves as the key.

This script will note duplicate and skip them. It will not remove the dynamic
list.

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 2.2 $

=item Created:

Mon Oct 24 16:19:15 PDT 2011

=item Modified:

$Date: 2012/12/18 19:44:10 $

=back

=head1 SYNOPSIS

 Usage: convertList.pl -list <list> -table <table> -field <field>
                       [-u|sage] [-v|erbose] [-d|ebug]
                       [-username <username>] [-password <password>]
                       [-database <database>] [-dbset <dbset>]
                       [-module] [-server <server>] [-port <port>]

 Where:
   -l|ist:      Dynamic list name to convert
   -t|able:     Name of the stateless table to convert the dynamic
                list to
   -field:      Name of the field to fill in with the values from
                -list

   -usa|ge:     Displays usage
   -v|erbose:   Be verbose
   -de|bug:     Output debug messages

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
use Logger;
use TimeUtils;
use Utils;

my $VERSION  = '$Revision: 2.2 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my (%opts, $cq, $log, %totals);

## Main
local $| = 1;

my $startTime = time;

GetOptions (
  \%opts,
  usage   => sub { Usage },
  verbose => sub { set_verbose },
  debug   => sub { set_debug },
  'module=s',
  'username=s',
  'database=s',
  'password=s',
  'dbset=s',
  'list=s',
  'table=s',
  'field=s',
  'server=s',
  'port=i',
) || Usage;

$log = Logger->new;

$log->msg ("$FindBin::Script v$VERSION");

Usage 'Must specify -list'  unless $opts{list};
Usage 'Must specify -table' unless $opts{table};
Usage 'Must specify -field' unless $opts{field};

# Translate any options to ones that the lib understands
$opts{CQ_USERNAME} = delete $opts{username};
$opts{CQ_PASSWORD} = delete $opts{password};
$opts{CQ_DATABASE} = delete $opts{database};
$opts{CQ_DBSET}    = delete $opts{dbset};
$opts{CQ_SERVER}   = delete $opts{server};
$opts{CQ_PORT}     = delete $opts{port};
$opts{CQ_MODULE}   = delete $opts{module};

$cq = Clearquest->new (%opts);

my $connection  = $cq->username . '@' . $cq->database . '/' . $cq->dbset; 
   $connection .= ' (Server: ' . $cq->host . ':' . $cq->port . ')'
     if ref $cq eq 'Clearquest::Client';

$log->msg ("Connecting to $connection...", 1);
     
$cq->connect;

$log->msg (' connected');

foreach ($cq->getDynamicList ($opts{list})) {
  verbose_nolf '.';

  $totals{Processed}++;
  
  my $errmsg = $cq->add ($opts{table}, ($opts{field} => $_));
  
  if ($errmsg ne '') {
    if ($errmsg =~ /duplicate entries in the database/ or
        $errmsg =~ /Record with same displayname exists/) {
      $totals{Duplicates}++;
    } else {
      $log->err ($errmsg);
    } # if
  } else {
    $totals{Added}++;
  } # if
} # foreach

$totals{Errors} = $log->errors;

error 'Errors occured - check ' . $log->fullname . ' for more info' 
  if $totals{Errors};

Stats \%totals, $log;

display_duration $startTime, $log;

$cq->disconnect;

exit $log->errors;
