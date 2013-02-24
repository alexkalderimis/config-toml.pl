package Config::TOML::Parser;

use DateTime;
use List::Util qw(reduce);
use Carp qw(croak confess);

sub getc {
    my $self = shift;
    my $nextc = $self->{src}->();
    if (defined $nextc) {
        if ("\n" eq $nextc) {
            $self->{line}++;
            $self->{col} = 0;
        } else {
            $self->{col}++;
        }
    }
    return $self->{lastc} = $nextc;
}

sub new {
    my ($cls, %opts) = @_;
    my $CLASS = ((ref $cls) || $cls);
    $opts{name} ||= "ANON";
    $opts{line} = 1;
    $opts{col} = 0;
    $opts{open_arrays} = 0;
    return bless \%opts, $CLASS;
}

my %IS_WHITESPACE = (
    "\t" => 1,
    " " => 1,
);

my %SPECIAL_CHARS = (
    '\\n' => "\n",
    '\\t' => "\t",
    '\\r' => "\r",
    '\\"'  => '"',
    '\\0' => "\\u00",
);

sub parse {
    my $self = shift;
    my $state = (shift || {});

    my @group = ();
    my $c;
    while (defined ($c = $self->getc)) {
        if ("\n" eq $c or $IS_WHITESPACE{$c}) {
            # DO NOTHING
        } elsif ('#' eq $c) {
            $self->read_newline(1);
        } elsif ('[' eq $c) {
            @group = $self->read_group;
            $self->read_newline;
        } else {
            my $key = $self->read_key($c);
            my ($value, $type) = $self->read_binding;
            set($state, $value, @group, $key);
            $self->read_newline;
        }
    }
    return $state;
}

sub throw {
    my $self = shift;
    my $err = shift;
    confess $err, sprintf(" in %s, at [line %d, column %d]",
        $self->{name}, $self->{line}, $self->{col});
}


sub read_newline {
    my $self = shift;
    return if ("\n" eq $self->{lastc});
    my $in_comment = shift;
    my $c;
    while (defined ($c = $self->getc)) {
        if ("\n" eq $c) {
            return;
        } elsif ($in_comment || $IS_WHITESPACE{$c}) {
            # DO_NOTHING;
        } elsif ('#' eq $c) {
            $in_comment = 1;
        } else {
            $self->throw("Expected WHITESPACE, COMMENT, EOL or EOF, got $c");
        }
    }
}

sub read_group {
    my $self = shift;
    my @members = ('');
    my $c;
    while (defined ($c = $self->getc)) {
        if (']' eq $c) {
            last;
        } elsif ("\n" eq $c) {
            $self->throw("Unexpected EOL");
        } elsif ('.' eq $c) {
            push @members, '';
        } else {
            $members[-1] .= $c;
        }
    }
    return @members;
}

sub read_key {
    my $self = shift;
    my $init = shift;
    my @buffer = ($init);
    my $c;
    while (defined ($c = $self->getc)) {
        if ("\t" eq $c or " " eq $c) {
            last;
        } elsif ("\n" eq $c) {
            $self->throw("Unexpected EOL");
        } else {
            push @buffer, $c;
        }
    }
    return join '', @buffer;
}

sub read_binding {
    my $self = shift;
    my ($c, $needs_eql);
    $needs_eql = 1;
    while ($needs_eql) {
        $c = $self->getc;
        $self->throw("Expected EQL, got EOF") unless defined $c;
        $needs_eql = ($c ne '=');
    }
    return $self->read_value();
}

sub read_value {
    my $self = shift;
    my $in_array = shift;
    my $c;
    my @buffer = ();
    while (defined ($c = $self->getc)) {
        if ($IS_WHITESPACE{$c} or "\n" eq $c) {
            if (@buffer) {
                last;
            } else {
                next;
            }
        } elsif ($in_array and (']' eq $c)) {
            $self->{open_arrays}--;
            last;
        } elsif ($in_array and (',' eq $c)) {
            $self->throw("Unexpected COMMA") unless @buffer;
            last;
        } elsif ('"' eq $c) {
            return $self->read_string;
        } elsif ('[' eq $c) {
            $self->{open_arrays}++;
            return $self->read_array;
        } else {
            push @buffer, $c;
        }
    }

    if (@buffer) {
        return $self->parse_value(join '', @buffer);
    } else {
        return;
    }
}

sub parse_value {
    my ($self, $data) = @_;
    $self->throw("No data") unless defined $data;
    if ($data eq 'true' or $data eq 'false') {
        return $data eq 'true';
    } elsif ($data =~ /^-?\d+(\.\d+)?$/) {
        return 0 + $data, 'NUMBER';
    } elsif ($data =~ /^(\d+)-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\w+)$/) {
        return DateTime->new(
            year => $1,
            month => $2,
            day => $3,
            hour => $4,
            minute => $5,
            second => $6,
            time_zone => $7), 'DATE';
    }
    $self->throw("Illegal data: '$data'");
}

sub read_string {
    my $self = shift;
    my @buffer = ();
    my $in_esc_seq = 0;
    my ($c, $found_terminator);
    until ($found_terminator) {
        $c = $self->getc;
        if (not defined $c) {
            $self->throw("Expected STRING_TERMINATOR, found EOF");
        } elsif ("\n" eq $c) {
            $self->throw("Expected STRING_TERMINATOR, found EOL");
        } elsif ("\t" eq $c) {
            $self->throw("Expected STRING_TERMINATOR, found TAB");
        }
        my $parsed;
        if ($in_esc_seq) {
            $parsed = $SPECIAL_CHARS{'\\' . $c};
            $self->throw("Illegal escape sequence \\$c") unless (defined $parsed);
            $in_esc_seq = 0;
        } elsif ('\\' eq $c) {
            $in_esc_seq = 1;
            next;
        } elsif ('"' eq $c) {
            $found_terminator = 1;
            next;
        } else {
            $parsed = $c;
        }
        push @buffer, $parsed;
    }

    return join('', @buffer), "STRING";
}

sub read_array {
    my $self = shift;
    my $level = $self->{open_arrays};
    my @values;
    my $has_more = 1;
    my $a_type;
    while ($has_more) {
        my ($next, $type) = $self->read_value(1);
        if (defined $next) {
            if ($a_type) {
                $self->throw("Expected $a_type, got $type") unless ($a_type eq $type);
            } else {
                $a_type = $type;
            }
            push @values, $next;
        }
        $has_more = $self->array_has_more($level);
    }
    return [@values], 'ARRAY';
}

sub array_has_more {
    my $self = shift;
    my $level = shift;
    return 1 if ($self->{lastc} eq ',');
    return 0 if ($self->{open_arrays} == $level - 1);

    my $c;
    while (defined ($c = $self->getc)) {
        if (("\n" eq $c) or ("\t" eq $c) or (' ' eq $c)) {
            # Do nothing.
        } elsif ('#' eq $c) {
            $self->read_newline(1);
        } elsif (',' eq $c) {
            return 1;
        } elsif (']' eq $c) {
            $self->{open_arrays}--;
            last
        } else {
            $self->throw("Expected WHITESPACE, COMMA or RIGHT-SQUARE-BRACKET, got '$c'");
        }
    }
    $self->throw("Expected RIGHT-ANGLE-BRACKET, got EOF") unless defined $c;
    return $self->{open_arrays} > $level;
}


sub set {
    my ($state, $value, @group) = @_;
    croak "No path" unless @group;
    my $key = pop @group;
    my $obj = reduce { ($a->{$b}) || ($a->{$b} = {}) } $state, @group;
    $obj->{$key} = $value;
}

