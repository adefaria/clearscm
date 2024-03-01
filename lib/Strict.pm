package Strict;

use strict;
use warnings;

sub import {
    warnings->import();
    strict->import();

    require feature;
    feature->import( ':5.30', 'signatures', 'say' );
    warnings->unimport('experimental::signatures');

    return;
}

1;
