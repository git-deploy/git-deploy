package Git::Deploy::Test;
use strict;
use warnings FATAL => 'all';
use Cwd qw(getcwd);
use File::Spec::Functions qw(catfile catdir);
use File::Temp qw(tempfile tempdir);
use Test::More;
use Exporter qw(import);

our @EXPORT = qw(
    git_deploy_test
    _run_git_deploy
    _system
);

sub _system {
    my ($cmd, $wanted_exit_code) = @_;
    $wanted_exit_code ||= 0;

    my $raw_exit_code = system $cmd;
    my $exit_code = $raw_exit_code >> 8;

    if ($exit_code != 0 && $wanted_exit_code == -1) {
        pass "The command <$cmd> exited with code <$exit_code>, which is non-0 like we wanted";
    } elsif ($exit_code != $wanted_exit_code) {
        fail "The command <$cmd> exited with <$exit_code>, but we wanted <$wanted_exit_code>: $!"
    } else {
        pass "The command <$cmd> exited with code <$exit_code> like we wanted";
    }
    return $exit_code;
}

sub _mkdir {
    my $dir = shift;
    mkdir $dir or do {
        fail "We couldn't mkdir <$dir>: $!";
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

sub git_deploy_test {
    my ($name, $test) = @_;

    my $cwd = getcwd();
    my $ctx = {
        git_deploy => "$^X -I$cwd/git-deploy-lib $cwd/bin/git-deploy",
    };

    subtest $name => sub {
        # Dir to store our test repo
        my $dir = tempdir( "git-deploy-XXXXX", CLEANUP => !$ENV{GIT_DEPLOY_DEBUG}, TMPDIR => 1 );
        ok(-d $dir, "The test directory $dir was created");
        _chdir $dir;

        # Dir with temporary output
        my $out_dir = catdir($dir, 'output');
        _mkdir $out_dir;
        # Dir with our logs
        my $log_dir = catdir($dir, 'log');
        _mkdir $log_dir;
        ok(-d $_, "The directory $_ was created") for $out_dir, $log_dir;
        $ctx->{out_dir} = $out_dir;

        # Can we copy the git dir?
        _system <<'SETUP_TEST_REPOSITORY';
            (
                git init swamp-1 &&
                cd swamp-1 &&
                echo "A git-deploy test repository" >README &&
                git add README &&
                git commit -m"A git-deploy test commit" README
            ) 2>&1
SETUP_TEST_REPOSITORY
        _system "git clone --bare swamp-1 swamp-2 >/dev/null 2>&1";
        _system "git clone swamp-2 swamp-3 >/dev/null 2>&1";
        ok(-d $_, "We created $_") for qw(swamp-1 swamp-2 swamp-3);

        _chdir 'swamp-3';

        # Set some custom configuration
        _system "echo .deploy >>.git/info/exclude";
        _system "git config deploy.tag-prefix debug";
        _system "git config deploy.log-directory $log_dir";

        # Run the user's tests
        $test->($ctx);

        _chdir $cwd;
        done_testing();
    };
}

sub _slurp {
    my ($file) = @_;
    open my $fh, "<", $file or die $!;
    do {
        local $/,
        <$fh>;
    }
}

sub _run_git_deploy {
    my ($ctx, %args) = @_;
    my $wanted_exit_code = $args{wanted_exit_code} || 0;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $out_dir = $ctx->{out_dir};
    $ctx->{"last_$_"} = catfile($out_dir, "last_$_") for qw(stdout stderr);
    _system "LC_ALL=C $ctx->{git_deploy} $args{args} >$ctx->{last_stdout} 2>$ctx->{last_stderr}", $wanted_exit_code;

    # Print out any fail we had on stderr that isn't debug output
    _system "grep -v ^# $ctx->{last_stderr} 1>&2 || :";
}

1;
