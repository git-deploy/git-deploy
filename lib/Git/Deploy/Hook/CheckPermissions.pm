package Git::Deploy::Hook::CheckPermissions;
use strict;
use warnings FATAL => "all";
use base qw(Git::Deploy::Hook);
use Git::Deploy::Say;
use Git::Deploy::Question;
use File::Find;

sub run {
    my ($self) = @_;

    _info "looking for files without ug+rw permissions\n";
    my $found_errors = 0;
    find(
        sub {
            if (my ( $dev, $ino, $mode, $nlink, $uid, $gid ) = lstat($_)) {
                if (( $mode & 0664 ) != 0664) {
                    # incorrect mode
                    $found_errors++;
                    _error( sprintf("%6o $File::Find::name\n", $mode) );
                }
            }
        },
        glob "*"
    );

    if ($found_errors) {
        _error  "Found $found_errors files with incorrect permissions";
        my $should_rollout = _question();
        if ($should_rollout) {
            _info "Proceeding with rollout";
            return 0;
        } else {
            _error "Aborting rollout";
            return 1;
        }
    } else {
        return 0;
    }
}

1;
