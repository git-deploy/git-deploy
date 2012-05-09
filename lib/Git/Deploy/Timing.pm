package Git::Deploy::Timing;
use strict;
use warnings FATAL => "all";
use Exporter 'import';
use Time::HiRes;

our @EXPORT = qw(
    push_timings
    should_write_timings
    write_timings
);

our (@timings, $write_timings, @real_argv);
BEGIN {
    # @timings is a set of 4-tuples: [ $tag, $time_stamp, $time_since_last_step, $time_since_start_tag ]
    @timings= (
            [
                'gdt_start',  # tagname
                $^T,                  # process start time (set by Perl at perl startup)
                -1,                   # time since last step (-1 == Not Applicable)
                -1,                   # time since start tag - only relevant on _end tags (-1 == Not Applicable)
            ]
    );
    # if this is true then we will write a timings file at process conclusion
    $write_timings= 0;
    @real_argv= @ARGV;
}

sub should_write_timings {
    $write_timings= 1;
}

sub push_timings {
    my $tag= shift;
    $tag =~ s/[^a-zA-Z0-9_]+/_/g; # strip any bogosity from the tag
    my $time= Time::HiRes::time();
    my $elapsed= -1;
    if ($tag=~/_end\z/) {
        (my $start= $tag)=~s/_end\z/_start/;
        foreach my $timing (@timings) {
            next unless $timing->[0] eq $start;
            $elapsed= $time - $timing->[1];
            last;
        }
    }
    push @timings, [ $tag, $time, $time - $timings[-1][1], $elapsed ];
}

sub write_timings {
    return unless $write_timings;
    # Do we even have to write the timing data?
    require Git::Deploy;
    return unless Git::Deploy::get_config_bool("log-timing-data",'false');
    # Where do we write it?
    my $log_directory;
    unless ( $log_directory = Git::Deploy::log_directory() ) {
        warn "Not writing timing data: 'log_directory' has not been configured.";
        return;
    }

    my $timing_file= "$log_directory/timing_gdt-$timings[0][1].txt";
    open my $fh, '>', $timing_file
        or do {
            warn "Not writing timing data: failed to open timing file '$timing_file': $!";
            return;
        };
    print $fh "# ". join("\t",$0,@real_argv),"\n";
    for my $timing (@timings) {
        print $fh join("\t",@$timing),"\n";
    }
    close $fh;
}

1;
