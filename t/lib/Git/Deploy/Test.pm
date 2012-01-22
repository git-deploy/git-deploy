package Git::Deploy::Test;
use strict;
use warnings FATAL => 'all';
use Cwd qw(getcwd);
use File::Spec::Functions qw(catfile catdir);
use File::Temp qw(tempfile tempdir);
use Test::More;
use Exporter qw(import);

our @EXPORT = qw(git_deploy_test);

sub _system;
sub _chdir;

sub git_deploy_test {
    my ($name, $test) = @_;

    my $cwd = getcwd();
    chomp(my $git_dir = `git rev-parse --git-dir`);
    my $git_deploy_git_dir = catdir($cwd, $git_dir);

    subtest $name => sub {
        # Dir to store our test repo
        my $dir = tempdir( "git-deploy-XXXXX", CLEANUP => 1, TMPDIR => 1 );
        ok(-d $dir, "The test directory $dir was created");
        _chdir $dir;

        # Can we copy the git dir?
        ok(-d $git_deploy_git_dir, "The <$git_deploy_git_dir> exists");
        _system "git clone $git_deploy_git_dir swamp-1 >/dev/null 2>&1";
        _system "git clone swamp-1 swamp-2 >/dev/null 2>&1";
        _system "git clone swamp-2 swamp-3 >/dev/null 2>&1";
        ok(-d $_, "We created $_") for qw(swamp-1 swamp-2 swamp-3);

        _chdir 'swamp-3';

        # Run the user's tests
        _system "git config deploy.tag-prefix debug";
        $test->("$^X -I$cwd/git-deploy-lib $cwd/git-deploy");

        _chdir $cwd;
        done_testing();
    };
}

sub _system {
    my $cmd = shift;
    system $cmd and do {
        fail "The command <$cmd> failed: $!";
        exit 1;
    };
}

sub _chdir {
    my $dir = shift;
    chdir $dir or do {
        fail "We couldn't chdir to <$dir>: $!";
        exit 1;
    };
}

1;
