use strict;
use warnings;

use Test::More;
use Test::Exception;

use Config::TOML;

my $file = 't/data/example.toml';
my $data;

plan(tests => 2);

lives_ok { $data = Config::TOML->read_file($file) } "Can read a file";

ok $data, "And we got something back";
