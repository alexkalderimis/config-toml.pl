use strict;
use warnings;

use Test::More;
use DateTime;

use Config::TOML;

plan(tests => 7);

my $data = Config::TOML->read_file('t/data/example.toml');

is($data->{owner}{organization}, "GitHub", "owner.organization is correct")
    or diag explain $data;

is($data->{database}{server}, "192.168.1.1", "database.server is correct")
    or diag explain $data;

my $expected_bio = "GitHub Cofounder & CEO\nLikes tater tots and beer.";
is($data->{owner}{bio}, $expected_bio, "owner.bio is correct")
    or diag explain $data;

is($data->{database}{connection_max}, 5_000, "database.server is correct")
    or diag explain $data;

is($data->{servers}{alpha}{ip}, "10.0.0.1", "servers.alpha.ip is correct")
    or diag explain $data;

ok($data->{database}{enabled}, "database.enabled is set to a truthy value");

my $exp_dob = DateTime->new(
    year => 1979,
    month => 05,
    day => 27,
    hour => 07,
    minute => 32,
    second => 00,
    time_zone => 'UTC');

is(DateTime->compare($data->{owner}{dob}, $exp_dob), 0, "owner.dob is correct")
    or diag $data->{owner}{dob};
