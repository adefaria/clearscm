package StdEnv;

use strict;
use warnings;

sub import {
    warnings->import();
    strict->import();

    require feature;
    feature->import( ':5.30', 'say' );

    require experimental;
    experimental->import('signatures');

    return;
}

1;
