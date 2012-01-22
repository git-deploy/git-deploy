#!/usr/bin/env/perl
use strict;
use warnings;
use lib 't/lib';
use Git::Deploy::Test;
use Test::More 'no_plan';

git_deploy_test(
    "a simple 'status'",
    sub {
        my ($git_deploy) = @_;
        system "$git_deploy start";
        like(`git tag -l`, qr/debug/, "We created a tag because there wasn't one already");
    }
);
