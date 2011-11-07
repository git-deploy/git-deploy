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
    my $question = "Continue anyway? [Y/n]";

    my $term = Term::ReadLine->new($0);
    while (defined (my $line = $term->readline("$question> "))) {
        for ($line) {
            if (/^Y(?:es)?/i) { return 1 }
            elsif (/^N(?:o)?/i)  { return 0 }
            else {
                _warn "I can't understand you, try again\n";
            }
        }
    }
}

1;
