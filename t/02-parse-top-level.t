use strict;
use warnings;

use Test::More;

use Config::TOML;

plan(tests => 1);

my $data = Config::TOML->read_file('t/data/example.toml');

is($data->{title}, "TOML Example", "Title is correct")
    or note explain $data;
