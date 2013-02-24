use strict;
use warnings;

use Test::More;
use Test::Exception;

use Config::TOML;

plan(tests => 4);

my $data;
my $text = <<EOF
title = "Example"

[owner]
name = "Alex Kalderimis"
EOF
;

lives_ok { $data = Config::TOML->parse( $text ); } "Can parse a string";

ok $data, "And we got something back";

is $data->{title}, 'Example';
is $data->{owner}{name}, 'Alex Kalderimis';
