#!cqperl
use strict;
use warnings;

=pod

=head1 NAME $RCSfile: cqd.pl,v $

Clearquest Daemon - Daemon to provide access to Clearquest database

This daemon instanciates an instance of the Clearquest::DBService to service 
requests for information of a Clearquest database or to update a Clearquest
database.

=head1 VERSION

=over

=item Author

Andrew DeFaria <Andrew@ClearSCM.com>

=item Revision

$Revision: 2.4 $

=item Created:

Mon Oct 24 16:19:15 PDT 2011

=item Modified:

$Date: 2013/03/15 00:15:32 $

=back

=head1 SYNOPSIS

 Usage: cqd.pl [-u|sage] [-v|erbose] [-d|ebug]
               [-logfile <logfile>] [-[no]daemon]
               [-s|erver <server>] [-p|ort <n>]

 Where:
   -u|sage:     Displays usage
   -v|erbose:   Be verbose
   -de|bug:     Output debug messages

   -s|erver <server>:   Server to talk to (Default: from conf file or
                        environment)
   -p|ort <n>           Port nbr to use (Default: from conf file or
                        environment)
   -m|ultithreaded
   -logfile <logfile>:  Where to log output (Default: STDOUT)
   -[no]daemon:         Enter daemon mode (Default: Enter daemon mode)

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

=item CQ_SERVER

Clearquest::Server name to connect to (Default: from config file)

=item CQ_PORT

Clearquest::Server port to connect to (Default: from config file)

=back

=cut

use Config;
use File::Spec;
use FindBin;
use Getopt::Long;

use CQPerlExt;

use lib "$FindBin::Bin/../lib";

use Clearquest::Server;
use Display;
use Utils;

my $VERSION  = '$Revision: 2.4 $';
  ($VERSION) = ($VERSION =~ /\$Revision: (.*) /);

my %opts;

GetOptions (
  \%opts,
  verbose => sub { set_verbose },
  debug   => sub { set_debug },
  usage   => sub { Usage },
  'server=s',
  'port=i',
  'logfile=s',
  'multithreaded!',
  'daemon!',
  'serviceClient=s',
  'socket=s',
) || Usage;

my %parms = (
  CQ_SERVER        => $opts{server},
  CQ_PORT          => $opts{port},
  CQ_MULTITHREADED => $opts{multithreaded},
);

my $cqservice = Clearquest::Server->new (%parms);

if ($opts{serviceClient}) {
  $cqservice->{clientname} = $opts{serviceClient};
  
  debug "In cqd.pl with -serviceClient $cqservice->{clientname} - opening socket";
  
  open my $client, '+<&=', *STDIN
    or error "Unable to open socket connection to client", 1;
  
  $client->autoflush (1);
  
  debug "Socket open - servicing client = $client";
  $cqservice->_serviceClient ($client);
  debug "Returned from servicing client";
  
  exit;
} # if

my $announcement  = "$FindBin::Script v$VERSION ";
   $announcement .= $cqservice->multithreaded 
                  ? '(Multithreaded)' 
                  : '(Singlethreaded)';

verbose $announcement;

if ($opts{daemon} and !get_debug and !defined $DB::OUT) {
  print $DB::OUT "Debugging\n" if get_debug;
  
  my ($logfile) = ($FindBin::Script =~ /(.*)\.pl$/);
   
  $opts{logfile} ||= "$logfile.log";
  
  $logfile = File::Spec->rel2abs ($opts{logfile});
  
  verbose "Entering daemon mode (Server pid: $$ - logging to $logfile)";
  
  if ($Config{perl} eq 'ratlperl') {
    error "Unable to daemonize with cqperl", 1;
  } else {
    EnterDaemonMode $opts{logfile}, $opts{logfile};
  } # if
} # if

delete $opts{daemon};
delete $opts{multithreaded};

verbose 'Starting Server';
$cqservice->startServer;

verbose 'Shutting down server';

exit;