package Git::Deploy::Hook::LoadBalancerCheck;
use strict;
use warnings FATAL => "all";
use base qw(Git::Deploy::Hook);
use Git::Deploy::Say;
use Git::Deploy::Question;

sub run {
    my ($self) = @_;

    # This script can either complain about us being in or being out
    my $lb_status_should_be_ok = $self->{should_be_in};

    chomp(my $this_box = qx[hostname -s]);
    die "Can't find host name for this box" unless $this_box;
    my $status = lb_status($this_box) || die  "Can't get lb status for $this_box";

    if ($status eq ($lb_status_should_be_ok ? "ok" : "rollout")) {
        # We're in the load balancer as expected
        if ($lb_status_should_be_ok) {
            _info "$this_box is in the load balancer as we expected, all OK!"
        } else {
            _info "$this_box is not in the load balancer as we expected, all OK!";
        }
        return 0;
    } else {
        if ($lb_status_should_be_ok) {
            _warn "$this_box is not in the load balancer as expected, instead it is ";
            _warn "in status '$status'. Ssomeone else may be using it for developing,";
            _warn "or there may be maintenance going on on it.";
        } else {
            _error "$this_box did not go to status 'rollout' as expected and is in";
            _error "status '$status' instead.\n";
            _error "You need to manually take it out, or maybe there was just some lag";
            _error "and it's already not needed:";
            _error "";
            _error "   lb $this_box rollout";
            _error "";
            _error "If this happens tell avar\@booking.com about it.";
        }
        my $should_rollout = _question();
        if ($should_rollout) {
            _info "Proceeding with rollout";
            return 0;
        } else {
            _error "Aborting rollout";
            return 1;
        }
    }
}

my $statusmap = {
    0 => 'ok',
    1 => 'rollout',
    2 => 'maintenance',
    3 => 'error',
    4 => 'unscheduled downtime',
    default => '',
};

sub lb_status {
    my ($host) = @_;
    my ($status, $output) = executeCommand('lb', $host);
    return $statusmap->{$status} || $statusmap->{'default'};
}

sub executeCommand {
    my $command = join ' ', @_;
    reverse ( $_ = qx{$command 2>&1}, $?>>8);
}
1;
