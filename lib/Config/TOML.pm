package Config::TOML;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Config::TOML::Parser;
use IO::All qw/io/;

=head1 NAME

Config::TOML - The great new Config::TOML!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01_alpha';


=head1 SYNOPSIS

    use Config::TOML;

    my $data = Config::TOML->read_file('path/to/file.toml');

    print "Foo.bar.baz is: ", $data->{foo}{bar}{baz};
    ...


=head1 Functions.

At present the factory methods are meant to be called as class methods on the
Config::TOML class.


use IO::All qw/io/;
use Carp qw(croak confess);

use Config::TOML::Parser;

=head2 read_file($path): HashRef

Reads a file given as a path. As we are using IO::All, you can use a variety
of different things here.

Returns the parsed data structure.
Confesses if it cannot parse the configuration.

=cut

sub read_file {
    my ($cls, $path) = @_;
    my $io = io($path);
    my $parser = Config::TOML::Parser->new(
        name => $path,
        src => sub { $io->getc },
    );
    my $ret = $parser->parse;
    $io->close;
    return $ret;
}

=head2 parse($text): HashRef

Reads configuration given as a string.

Returns the parsed data structure.
Confesses if it cannot parse the configuration.

=cut

sub parse {
    my ($cls, $text) = @_;
    my @chars = split '', $text;
    my $parser = Config::TOML::Parser->new(
        src => sub { shift @chars },
    );
    $parser->parse;
}
    

=head1 AUTHOR

Alex Kalderimis, C<< <alex.kalderimis at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-config-toml at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-TOML>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::TOML


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-TOML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-TOML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-TOML>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-TOML/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Alex Kalderimis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Config::TOML
