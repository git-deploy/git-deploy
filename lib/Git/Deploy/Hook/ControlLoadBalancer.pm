package Git::Deploy::Hook::ControlLoadBalancer;
use strict;
use warnings FATAL => "all";
use base qw(Git::Deploy::Hook);
use Git::Deploy::Say;

sub run {
    my ($self) = @_;

    my $new_status = $self->{new_status};

    chomp(my $this_box = qx[hostname -s]);
    my $cmd = "lb $this_box $new_status";
    my $ret = system $cmd;
    if ($ret == 0) {
        _info "We've executed:";
        _info "    $cmd";
        if ($new_status eq "rollout") {
            _info "To take this box out of the load balancer for the rollout";
        } elsif ($new_status eq "ok") {
            _info "To put this this box back in the load balancer";
        } else {
            _warn "No message for action $new_status";
        }
        return 0;
    } else {
        _error "Executing:";
        _error "    $cmd;";
        if ($new_status eq "rollout") {
            _error "To take this box out of the load balancer didn't work";
        } elsif ($new_status eq "ok") {
            _info "To put this this box back in the load didn't work";
        } else {
            _warn "No message for action $new_status";
        }

        return $ret;
    }
}

1;
