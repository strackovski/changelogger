#
# Printer - console output helper
#
# Module:   ChangeLogger
# Author:   Vladimir Strackovski <vladimir.strackovski@dlabs.si>
# Year:     2018
#
package Printer;

use strict;
use warnings;
use Term::ANSIColor ('color');

our $VERSION = "0.1.0";

sub new {
    my ( $class, $args ) = @_;
    my $self = {
        verbose    => $args->{verbose} || 0,
        debug      => $args->{debug}   || 0,
        lineLength => $args->{debug}   || 58
    };

    return bless $self, $class;
}

sub verbose {
    my ( $self, $content ) = @_;
    if ( defined $self->{verbose} and $self->{verbose} == 1 ) {
        $self->print_line( $content, 'BRIGHT_BLACK' );
    }
}

sub error {
    my ( $self, $content, $color, $compact ) = @_;
    $color = defined $color ? $color : 'bright_red';
    $compact = defined $compact && $compact == 1 ? "" : "\n";
    $self->print_line( $compact . '✗  ' . $content . $compact, $color );
}

sub info {
    my ( $self, $content, $color ) = @_;
    $color = defined $color ? $color : 'bright_magenta';
    $self->print_line( '➜  ' . $content, $color );
}

sub warning {
    my ( $self, $content, $color ) = @_;
    $color = defined $color ? $color : 'bright_red';
    $self->print_line( "** " . $content . " **", $color );
}

sub print_separator {
    my ( $self, $char, $color ) = @_;
    my $line = $char;

    for ( my $i = 0 ; $i <= $self->{lineLength} ; $i++ ) {
        $line = $line . $char;
    }

    print color($color), $line . "\n", color("reset");
}

sub print_line_with_sep {
    my ( $self, $text, $sep, $sepColor, $textColor ) = @_;
    print color($textColor), $text, "\n", color("reset");
    $self->print_separator( $sep, $sepColor );
}

sub print_header {
    my $self = shift;
    print color("bright_yellow"), PAR::read_file('header.txt'), "\n", color("reset");
}

sub print_line {
    my ( $self, $text, $color ) = @_;
    if ($color) {
        print color($color), $text, "\n", color("reset");
    }
    else {
        print color("reset"), $text, "\n";
    }
}

sub print_color {
    my ( $self, $text, $color, $currentLength ) = @_;
    if ($currentLength) {
        $currentLength = 60 - $currentLength;
        $text = sprintf '%' . $currentLength . 's', $text;
    }

    if ( $color && $color ne '' ) {
        print color($color), $text, color("reset");
    }
    else {
        print color("reset"), $text;
    }

    return length $text;
}

sub print_options {
    my ( $self, $withHeader ) = @_;
    if ( defined $withHeader ) {
        $self->print_header();
    }

    $self->print_separator( '*', 'cyan' );
    $self->print_line_with_sep( ' ➜  Usage:', '-', 'cyan', 'yellow' );
    print "\n clogger <RELEASE_TYPE> [-dir] [-strategy]\n\n Where release type is one of:\n\n";
    print " ➜  major\n ➜  minor\n ➜  patch (alias hotfix)\n\n";
    $self->print_line_with_sep( ' ➜  Options:', '-', 'cyan', 'yellow' );
    print "\n -dir          Absolute path to project directory.\n               Defaults to current directory.\n\n";
    print " -strategy     Change detection strategy:\n";
    print "               ➜  tag: all commits since last tag (default). \n";
    print "               ➜  commit: all commits since given commit.  \n\n";
    $self->print_line_with_sep( ' ➜  Examples:', '-', 'cyan', 'yellow' );
    print " clogger major\n";
    print " clogger minor -dir=/home/project -strategy=commit\n";
    $self->print_separator( '-', 'cyan' );
}

1;
