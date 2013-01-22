#!/usr/bin/env/perl
use strict;
use warnings;
use lib 't/lib';
use Git::Deploy::Test;
use Test::More;

{
    my $git_version = qx[git version 2>&1];
    if (defined $git_version and $git_version =~ /git version/) {
        plan 'no_plan';
    } else {
        plan skip_all => "We don't have Git installed here";
    }
}

git_deploy_test(
    "A rollout etc.",
    sub {
        my $ctx = shift;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
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
            wanted_exit_code => 1,
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

        # Now let's do another rollout, but this time we're making a
        # local commit.
        _run_git_deploy(
            $ctx,
            args => "start",
        );
        like(
            `cat $ctx->{last_stderr}`,
            qr/Step 'start' finished/,
            "We finished the start step",
        );
        # Make a new local commit
        _system "echo CHANGES >README";
        _system qq[git commit -m"This is a commit message" README];
        # It's going to be shown by "log"
        _run_git_deploy(
            $ctx,
            args => "log",
        );
        like(
            `cat $ctx->{last_stdout}`,
            qr/This is a commit message/,
            "We have stuff in 'log'",
        );
        # And we're going to show it in "diff"
        _run_git_deploy(
            $ctx,
            args => "diff",
        );
        like(
            `cat $ctx->{last_stdout}`,
            qr/CHANGES/,
            "We have stuff in 'diff'",
        );
        # Let's get the current tag
        _run_git_deploy(
            $ctx,
            args => "show-tag",
        );
        my $before_rollout_tag = `cat $ctx->{last_stdout}`;
        like $before_rollout_tag, qr/^debug-/, "The tag we had before rollout is <$before_rollout_tag>";
        # Let's try to sync without having pushed
        _run_git_deploy(
            $ctx,
            args => "sync",
            wanted_exit_code => 1,
        );
        like(
            `cat $ctx->{last_stderr}`,
            qr/$_/,
            "Should be in output: $_",
        ) for
            "It looks like there are unpushed commits",
            "Most likely this is harmless";
        like(
            `cat $ctx->{last_stdout}`,
            qr/This is a commit message/,
            "We should get a commit message in the output",
        );
        # we still haven't synced
        _run_git_deploy(
            $ctx,
            args => "status",
            wanted_exit_code => 1,
        );
        like(`cat $ctx->{last_stderr}`, qr/debug rollout started - not synced yet/, "We note the correct status");
        # let's push our commits
        _system "git push 2>&1";
        # Let's sync
        _run_git_deploy(
            $ctx,
            args => "sync",
            wanted_exit_code => 0,
        );
        # And assert that we have the usual output (pasted from above)
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
        # we've synced, but we still have to finish
        _run_git_deploy(
            $ctx,
            args => "status",
            wanted_exit_code => 2,
        );
        # finish and check for the usual output (pasted from above)
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
        # let's revert to a previous commit
        _run_git_deploy(
            $ctx,
            args => "revert 2",
        );
        # checking output
        like(
            `cat $ctx->{last_stdout} && cat $ctx->{last_stderr} `,
            qr/$_/,
            "Should be in output: $_"
        ) for
            "You've selected the choice <2>",
            "The following commits are available";
        # let's finish the revert
        _run_git_deploy(
            $ctx,
            args => $_
        ) for qw(sync finish);
        like(
            `git rev-list $before_rollout_tag..`,
            qr/^$/,
            "We're now back to where we started out"
        );
    }
);
