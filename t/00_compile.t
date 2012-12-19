#!/usr/bin/env/perl
use strict;
use warnings;
use Test::More 'no_plan';

use_ok $_ for qw(
    Git::Deploy::Timing
    Git::Deploy::Question
    Git::Deploy::Say
    Git::Deploy::Hook
    Git::Deploy
);
