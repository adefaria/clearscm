#!cqperl
use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";

use Clearquest::Client;
use Display;
use TimeUtils;

$| = 1;

# Let's time this...
my $startTime = time;

my $cq = Clearquest::Client->new;

my $dbname = $cq->username () . '@' . $cq->database () . '/' . $cq->dbset ();
           
display_nolf "Connecting to Clearquest database $dbname";

unless ($cq->connect) {
  display ' Failed!';

  error "Unable to connect to database $dbname", 1;
} # unless

display_duration $startTime;

my ($result, $nbrRecs) = $cq->find ('defect', 'assert == 0', ('id', 'title'));

while (my %record = $cq->getNext ($result)) {
  display "$_: $record{$_}" foreach (sort keys %record);
} # while

display 'done';