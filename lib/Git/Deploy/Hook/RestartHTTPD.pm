package Git::Deploy::Hook::RestartHTTPD;
use strict;
use warnings FATAL => "all";
use Git::Deploy::Say;
use base qw(Git::Deploy::Hook);

sub run {
    my ($self) = @_;

    my $name = $self->{name};
    my $default_test_url = ( $name =~ m/[.]/ ? $name : "$name.booking.com" );
    my $urls = $self->{test_urls} ||= [ "https://$default_test_url" ];
    my $cmd = $self->{command};
    _info "Restarting the $name httpd using:";
    _info "    $cmd";
    my $code = system $cmd;

    if ($code == 0) {
        _yay "Restarting the $name httpd was successful!";
        _yay "Now test " . join(" and ", @$urls);
    } else {
        _error "Restarting the $name httpd didn't work. The restart command exited with code $code!";
    }

    return $code >> 8;
}

1;
