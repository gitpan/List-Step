#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'List::Step' );
}

diag( "Testing List::Step $List::Step::VERSION, Perl $], $^X" );
