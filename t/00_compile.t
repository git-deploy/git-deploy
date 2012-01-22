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

use_ok $_ for qw(
    Git::Deploy::Hook::CheckPermissions
    Git::Deploy::Hook::ConfigtestHTTPD
    Git::Deploy::Hook::RestartHTTPD
    Git::Deploy::Hook::ControlLoadBalancer
    Git::Deploy::Hook::NobranchRollout
    Git::Deploy::Hook::LoadBalancerCheck
);
