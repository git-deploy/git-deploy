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

        # We should be friendlier on the first sync
        _run_git_deploy(
            $ctx,
            args => "sync",
            wanted_exit_code => 0,
        );
        like(
            `cat $ctx->{last_stderr}`,
            qr/It seems like there is nothing to sync/,
            "XXX: On our first sync we bitch about the tag we just made. We shouldn't do that."
        );

        # Just force it for now
        _run_git_deploy(
            $ctx,
            args => "--force sync",
            wanted_exit_code => 0,
        );
        like(
            `cat $ctx->{last_stderr}`,
            qr/--force enabling rolling out same thing you had when you started/,
            "XXX: On our first sync we bitch about the tag we just made. We shouldn't do that."
        );
        like(
            `cat $ctx->{last_stderr}`,
            qr/You must now hand execute the synchronization process and then execute/,
            "We don't have any sync hook yet"
        );
        like(
            `cat $ctx->{last_stderr}`,
            qr/$_/,
            "Should be in output: $_",
        ) for
            "Step 'sync' finished",
            "git push --tags origin",
            "Not sending mail on action 'sync'",
            "\[new tag\]";

        _run_git_deploy(
            $ctx,
            args => "status",
            wanted_exit_code => 2,
        );
        like(`cat $ctx->{last_stderr}`, qr/debug rollout tagged - awaiting sync/, "We note the correct status");

        _run_git_deploy(
            $ctx,
            args => "finish",
        );
        like(
            `cat $ctx->{last_stderr}`,
            qr/$_/,
            "Should be in output: $_"
        ) for
            "Looks like you are all done! Have a nice day",
            "git push --tags origin",
            "Step 'finish' finished.";

        _run_git_deploy(
            $ctx,
            args => "status",
        );
        like(`cat $ctx->{last_stderr}`, qr/No debug deployment currently in progress/, "No deployment in progress");
    }
);
