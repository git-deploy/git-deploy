package Git::Deploy::Question;
use strict;
use warnings FATAL => "all";
use Exporter 'import';
use Term::ReadLine;
use Git::Deploy::Say;

our @EXPORT = qw(
    _question
);

sub _question {
    my %opts = (
        question => "Continue anyway? [Y/n]",
        answer_positive => qr/^Y(?:es)?/i,
        answer_negative => qr/^N(?:o)?/i,

        @_,  # this goes last, for hobo default overriding
    );

    my $term = Term::ReadLine->new($0);
    while (defined (my $line = $term->readline("$opts{question}> "))) {
        for ($line) {
            if ( /$opts{answer_positive}/ ) { return 1 }
            elsif ( /$opts{answer_negative}/ )  { return 0 }
            else {
                _warn "I can't understand you, try again\n";
            }
        }
    }
}

1;
