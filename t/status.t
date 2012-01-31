#!/usr/bin/env/perl
use strict;
use warnings;
use lib 't/lib';
use Git::Deploy::Test;
use Test::More 'no_plan';

git_deploy_test(
    "a simple 'status'",
    sub {
        my $ctx = shift;
        _run_git_deploy(
            $ctx,
            args => "start",
        );
        like(`git tag -l`, qr/debug/, "We created a tag because there wasn't one already");
        like(`cat $ctx->{last_stderr}`, qr/Deploy procedure has started/, "We print a notice about the deploy being started");
        like(`cat $ctx->{last_stderr}`, qr/Not sending mail on action/, "By default we don't send mail on 'start'");
        like(`cat $ctx->{last_stderr}`, qr/git push --tags origin/, "We push any tags we have to origin on startup");

        _run_git_deploy(
            $ctx,
            args => "status",
            wanted_exit_code => 1,
        );
        like(`cat $ctx->{last_stderr}`, qr/debug rollout started - not synced yet/, "We note the correct status");
    }
);
