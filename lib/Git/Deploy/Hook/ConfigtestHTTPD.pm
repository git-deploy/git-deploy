package Git::Deploy::Hook::ConfigtestHTTPD;
use strict;
use warnings FATAL => "all";
use Git::Deploy::Say;
use base qw(Git::Deploy::Hook);

sub run {
    my ($self) = @_;

    my $cmd = $self->{command};
    _info "Config testing httpd using:";
    _info "    $cmd";
    my $code = system $cmd;

    if ($code == 0) {
        _yay "Config testing the httpd was successful!";
    } else {
        _error "Config testing the httpd didn't work. The testing command exited with code $code!";
    }

    return $code >> 8;
}

1;
