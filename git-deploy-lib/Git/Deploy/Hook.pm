package Git::Deploy::Hook;
use strict;
use warnings FATAL => "all";

sub new {
    my ($class, %args) = @_;
    bless \%args => $class;
}

1;
