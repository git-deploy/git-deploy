package Git::Deploy::Say;
use strict;
use warnings FATAL => "all";
use Exporter 'import';
use File::Spec::Functions qw(catfile);

use POSIX 'strftime';
use Memoize;

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
    _fatal_exit
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
    $LOG_HANDLE
);

sub _msg {
    # don't call _die() in here
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

use constant SKIP_LOGGING => $ENV{GIT_DEPLOY_SAY_SKIP_LOGGING};

sub _get_log_handle {
    return if SKIP_LOGGING;

    require Git::Deploy;
    my $log_dir  = Git::Deploy::log_directory();
    my $log_file = catfile($log_dir, 'git-deploy.log');
    open my $fh, ">>", $log_file or do {
        warn "Can not append to global log file '$log_file': $!";
        return;
    };

    return $fh;
}
memoize('_get_log_handle');

# NOTE - THESE COLORS ARE CHOSEN WITH COLOR BLINDNESS IN MIND - DO NOT CHANGE THEM WITHOUT
# VERIFYING THAT A COLOR BLIND PROGRAMMER CAN SEE THE DIFFERENCE - 10% of MEN SUFFER SOME KIND
# OF COLOR BLINDNESS AND APPROXIMATELY 99% OF OUR CODERS ARE MEN.

our $SKIP_LOGING_DUE_TO_DEEP_RECURSION_WITH_GIT_DEPLOY_DEBUG;

sub __log {
    return if $SKIP_LOGING_DUE_TO_DEEP_RECURSION_WITH_GIT_DEPLOY_DEBUG;

    my $str= join("",@_);
    my $user = $ENV{USER} || ((getpwuid($<))[0]);
    my $pfx= sprintf "# %-12s | %s #",$user,strftime("%Y-%m-%d %H:%M:%S",localtime);
    $str=~s/\033\[[^m]+m//g;          # strip color
    $str=~s/^#([^:]+):/$pfx $1:/mg; # fix prefix
    $str=~s/\n*\z/\n/;
    if (my $fh= _get_log_handle()) {
        print $fh $str;
    }
}

sub __say(@) {
    my $color= shift;
    my $msg= _msg( @_ );
    __log($msg);
    eval {
        print STDERR colored $color, $msg;
        1;
    } or Carp::confess("wtf! $@");
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

{
    my($already_in_die, @errors);
    sub _die(@) {
        # very bad
        my $msg= _msg( "# FATAL:", @_ );
        push @errors, $msg;
        if ( ! $already_in_die++ ) {
            __log($msg);
        }
        else {
            $msg = join "\n",
                        "_die() called itself due to an error in __log().",
                        "This output will not be logged (screen only).",
                        "The errors collected so far:\n",
                        @errors,
                    ;
        }
        chomp $msg;
        die colored([COLOR_DIE], $msg), "\n";
    }
}

sub _fatal_exit(@) {
    my $code= shift;
    my $msg= _msg( "# FATAL:", @_ );
    __log($msg);
    chomp $msg;
    warn colored([COLOR_DIE], $msg), "\n";
    exit($code);
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
