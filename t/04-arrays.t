use strict;
use warnings;

use Test::More;

use Config::TOML;

plan(tests => 3);

my $data = Config::TOML->read_file('t/data/example.toml');

is_deeply(
    $data->{clients}{data},
    [ 
        ['gamma', 'delta'],
        [1, 2]
    ],
    "clients.data is correct"
) or diag explain $data;


my $pretties = Config::TOML->read_file('t/data/pretty-arrays.toml');

is_deeply(
    $pretties->{array_one},
    [qw/foo bar baz/],
    "Can parse a single pretty array"
);

is_deeply(
    $pretties->{array_two},
    [
        [1, 2, 3],
        [qw/quux quuz quuw/]
    ],
    "Can parse nested pretty arrays"
);

