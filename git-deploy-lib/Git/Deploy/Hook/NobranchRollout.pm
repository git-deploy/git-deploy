package Git::Deploy::Hook::NobranchRollout;
use strict;
use warnings FATAL => "all";
use Git::Deploy::Say;
use Git::Deploy::Question;
use base qw(Git::Deploy::Hook);

sub run {
    my ($self) = @_;

    my $branch = $self->{branch} || "trunk";
    chomp(my $on_branch = qx[git symbolic-ref -q HEAD]);
    $on_branch =~ s[^refs/heads/][];

    if ($on_branch ne $branch) {
        _info "You are about to rollout the branch '$on_branch' instead of '$branch'";
        my $should_rollout = _question();
        if ($should_rollout) {
            _info "Proceeding with rollout of '$on_branch'";
            return 0;
        } else {
            _error "Aborting rollout of '$on_branch'";
            return 1;
        }
    } else {
        return 0;
    }
}

1;
