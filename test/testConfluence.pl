#/usr/bin/env perl
use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";

use Confluence;

my $confluence = Confluence->new (
  username => 'adefaria',
  server   => 'confluence',
  port     => 8080,
);

my $content = $confluence->getContent (
  title => 'Knowles Migration',
);

