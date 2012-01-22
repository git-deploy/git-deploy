package Git::Deploy::Say;
use strict;
use warnings FATAL => "all";
use Exporter 'import';

our ($LOG_HANDLE,$LOG_FILE);
use POSIX 'strftime';

BEGIN {
    select( ( select(STDERR), $|++ )[0] ); $|++;    # flush ALL buffers!
    unless ( !$ENV{NO_COLOR} and -t STDOUT and eval "use Term::ANSIColor qw(color colored); 1" ) {
        eval '
            sub color { return "" }
            sub colored { return $_[1] }
            1
        ' or die "Failed to installed stub color functions: $@";
    }
}

our @EXPORT = qw(
    _error
    _die
    _warn
    _info
    _say
    _yay
    _tell
    _log
    _print
    _printf

    COLOR_WARN
    COLOR_INFO
    COLOR_SAY
    COLOR_MODIFIED
    COLOR_ADDED
    COLOR_DELETED
    COLOR_RENAMED
    COLOR_MODECHG

    color
    colored
    get_log_handle
    $LOG_HANDLE
);

sub _msg {
    my ( $pfx, @bits )= @_;
    my $msg= join "", @bits;
    $msg =~ s/\n*\z/\n/;
    $msg =~ s/^\s*#\s+//mg;
    $pfx ||= "###";
    my $qpfx= quotemeta($pfx);
    $msg =~ s/^(\s+$qpfx)?/$pfx /mg;
    return $msg;
}
use constant $ENV{WHITE_BACKGROUND}
    ? {
    COLOR_CONFESS   => 'red',
    COLOR_DIE       => 'red',
    COLOR_WARN      => 'red',
    COLOR_INFO      => 'black',
    COLOR_SAY       => 'blue',
    COLOR_TELL      => 'magenta',
    COLOR_YAY       => 'bold black',
    COLOR_MODIFIED  => 'black',
    COLOR_ADDED     => 'green',
    COLOR_DELETED   => 'red',
    COLOR_RENAMED   => 'magenta',
    COLOR_MODECHG   => 'cyan',
    }
    : {
    COLOR_CONFESS => 'bold red',
    COLOR_DIE     => 'bold red',
    COLOR_WARN    => 'bold red',
    COLOR_INFO    => 'white',
    COLOR_SAY     => 'cyan',
    COLOR_TELL    => 'yellow',
    COLOR_YAY     => 'bold white',
    COLOR_MODIFIED  => 'white',
    COLOR_ADDED     => 'green',
    COLOR_DELETED   => 'red',
    COLOR_RENAMED   => 'magenta',
    COLOR_MODECHG   => 'cyan',
    };


sub get_log_handle {
    if (!$LOG_HANDLE) {
        if (!defined $LOG_FILE) {
            my $log_dir;
            for my $d ("/var/log/deploy","/tmp") {
                if (-d $d) {
                    $log_dir= $d;
                    last;
                }
            }
            $LOG_FILE= $log_dir . "/git-Deploy.log";
        }

        open $LOG_HANDLE, ">>", $LOG_FILE
            or die "Can not append to global log file '$LOG_FILE': $!";
    }
    return $LOG_HANDLE;
}
# NOTE - THESE COLORS ARE CHOSEN WITH COLOR BLINDNESS IN MIND - DO NOT CHANGE THEM WITHOUT
# VERIFYING THAT A COLOR BLIND PROGRAMMER CAN SEE THE DIFFERENCE - 10% of MEN SUFFER SOME KIND
# OF COLOR BLINDNESS AND APPROXIMATELY 99% OF OUR CODERS ARE MEN.

sub __log {
    my $str= join("",@_);
    my $user = $ENV{USER} || ((getpwuid($<))[0]);
    my $pfx= sprintf "# %-12s | %s #",$user,strftime("%Y-%m-%d %H:%M:%S",localtime);
    $str=~s/\033\[[^m]+m//g;          # strip color
    $str=~s/^#([^:]+):/$pfx $1:/mg; # fix prefix
    $str=~s/\n*\z/\n/;
    my $fh= get_log_handle();
    print $fh $str;
}

sub __say(@) {
    my $color= shift;
    my $msg= _msg( @_ );
    __log($msg);
    print STDERR colored $color, $msg;
}

sub _log(@) {
    __log(_msg( "#   LOG:", @_ ));
}

sub _print {
    __log(_msg("#PRINT:", @_));
    print @_;
}

sub _printf {
    my $fmt= shift;
    my $msg= sprintf $fmt, @_; # i dont think you can use @_ here alone
    __log(_msg("#PRINT:",  $msg));
    print $msg;
}


sub _confess(@) {
    my $msg= Carp::longmess();
    $msg= _msg( "# FATAL:", @_, $msg );
    __log($msg);
    die colored [COLOR_CONFESS], $msg;
}    # very bad

sub _die(@) {
    # very bad
    my $msg= _msg( "# FATAL:", @_ );
    __log($msg);
    die colored [COLOR_DIE], $msg;
}

sub _error(@) {
    __say( [COLOR_DIE], "# ERROR:", @_ );
}                    # still bad, but not fatal


sub _warn(@) {
    __say([COLOR_WARN], "# WARN :", @_ );
}                                                                           # bad

sub _info(@) {
    __say([COLOR_INFO], "# INFO :", @_ );
}                                                                           # diags

sub _say(@) {
    __say([COLOR_SAY], "# NOTE :", @_ );
}                                                                           # ok

sub _yay(@) {
    __say([COLOR_YAY], "# YAY  :", @_ );
}                                                                           # great

sub _tell(@) {
    __say( [COLOR_TELL], "# USER :", @_ );
}                                                                           # tell user to do something

1;
