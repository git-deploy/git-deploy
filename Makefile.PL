
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "automate the git steps required for a deploying code from a git repository",
  "AUTHOR" => "\306var Arnfj\366r\360 Bjarmason <avarab\@gmail.com>, Yves Orton <demerphq\@gmail.com>",
  "BUILD_REQUIRES" => {
    "File::Temp" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "git-deploy",
  "EXE_FILES" => [
    "bin/git-deploy"
  ],
  "LICENSE" => "perl",
  "NAME" => "git::deploy",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Cwd" => 0,
    "Data::Dumper" => 0,
    "Exporter" => 0,
    "Fcntl" => 0,
    "File::Basename" => 0,
    "File::Find" => 0,
    "File::Spec::Functions" => 0,
    "FindBin" => 0,
    "Getopt::Long" => 0,
    "POSIX" => 0,
    "Pod::Usage" => 0,
    "Sys::Hostname" => 0,
    "Term::ReadLine" => 0,
    "Time::HiRes" => 0,
    "base" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "5.00",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



