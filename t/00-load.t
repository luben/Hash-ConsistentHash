#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Hash::ConstantHash' ) || print "Bail out!\n";
}

diag( "Testing Hash::ConstantHash $Hash::ConstantHash::VERSION, Perl $], $^X" );
