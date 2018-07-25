#
# ChangeLogger
#
# Module:   ChangeLogger
# Author:   Vladimir Strackovski <vladimir.strackovski@dlabs.si>
# Year:     2018
#
package ChangeLogger;

use strict;
use warnings;
use Tie::File;
use Time::Piece;
use JSON::PP;
use ChangeLogger::Tools;
use ChangeLogger::Printer;
use Par::Packer;
use Readonly;
use Data::Dumper;

our $VERSION                     = "0.1.0";
our @SUPPORTED_RELEASE_TYPES     = qw( minor major patch hotfix );
our @SUPPORTED_CHANGE_STRATEGIES = qw( tag commit auto );
our %releaseTypes                = map { $_ => 1 } @SUPPORTED_RELEASE_TYPES;
our %strategies                  = map { $_ => 1 } @SUPPORTED_CHANGE_STRATEGIES;

Readonly::Scalar my $GIT_TAG_COMMAND => 'git describe --tags --always --abbrev=0';
Readonly::Scalar my $GIT_LOG_CLEANUP => '--oneline --no-merges --no-decorate';

sub new {
    my ( $class, $projectDir, $strategy, $type, $printer, $verbose, $debug ) = @_;
    my $self = {
        repository_dir => $projectDir,
        release_type   => $type,
        release_date   => localtime->strftime('%d-%m-%Y'),
        version        => 0,
        config         => {},
        printer        => $printer,
        last_tag       => '',
        strategy       => $strategy,
        verbose        => $verbose,
        debug          => $debug
    };

    return bless $self, $class;
}

sub run() {
    my ( $self, $info ) = @_;

    if ( defined $info && $info == 1 ) {
        $self->printer->print_line(
            "ChangeLogger version $ChangeLogger::VERSION\nCopyright (c) 2018 Vladimir Strackovski");
        exit;
    }

    if ( $self->{release_type} eq 'none' ) {
        system 'clear';
        $self->printer->print_options(1);
        exit;
    }

    $self->validate();
    $self->readConfig();
    $self->execute();
}

sub execute() {
    my ($self) = @_;
    my @commits;

    if ( $self->{strategy} eq 'tag' ) {
        $self->{version} = Tools::question( 'Next version/tag', $self->incrementSemVer );
        @commits = $self->getCommitsSinceLastTag();
    }
    elsif ( $self->{strategy} eq 'auto' ) {
        @commits = $self->getCommitsSinceLastTag();
        $self->{version} = $self->incrementSemVer;
    }
    elsif ( $self->{strategy} eq 'commit' ) {
        my $hash = Tools::question('Commit hash');
        $self->{version} = Tools::question('Next version/tag');
        @commits = $self->getCommitsSinceCommitHash($hash);
    }

    if ( !@commits ) {
        return 0;
    }

    if ( $self->{strategy} ne 'auto' ) {
        $self->{release_date} = Tools::question( "Release date", $self->{release_date} );
    }

    $self->write(@commits);
    $self->printer->info("Changelog updated in $self->{repository_dir}/$self->{config}{file_name}.");
}

sub readConfig() {
    my ($self) = @_;

    $self->{config} = decode_json( Tools::read_file('changelogger.json') );
    #
    # if ( !-d $self->{repository_dir} . '/changelogger.json' ) {
    #     $self->{config} = decode_json( PAR::read_file('config.json') );
    # }
    # else {
    #     # $self->{config} = decode_json( Tools::read_file( $self->{repository_dir} . '/changelogger.json' ) );
    #     $self->{config} = decode_json( Tools::read_file( 'changelogger.json' ) );
    # }
}

sub validate() {
    my ($self) = @_;

    if ( !defined $self->{repository_dir} ) {
        $self->printer->error("Directory required.");
        exit;
    }

    if ( !-d $self->{repository_dir} || !-d $self->{repository_dir} . '/.git' ) {
        $self->printer->error("Directory '$self->{repository_dir}' does not exist or is not a git repository.");
        exit;
    }

    if ( exists $releaseTypes{ $self->{release_type} } != 1 ) {
        $self->printer->error("Unsupported release type '$self->{release_type}'.");
        exit;
    }

    if ( !exists( $strategies{ $self->{strategy} } ) ) {
        $self->printer->error("Unsupported change strategy '$self->{strategy}'.");
        exit;
    }
}

sub getLastTag() {
    my ($self) = @_;
    my $lastTagCmd = "cd $self->{repository_dir} && $GIT_TAG_COMMAND";

    if ( defined $self->{last_tag} && $self->{last_tag} ne '' ) {
        return $self->{last_tag};
    }

    $self->{last_tag} = `$lastTagCmd`;
    return $self->{last_tag};
}

sub getCommitsSinceLastTag() {
    my ($self) = @_;
    my $commits = "cd $self->{repository_dir} && git log `$GIT_TAG_COMMAND`..$self->{config}{branch} $GIT_LOG_CLEANUP";

    return $self->cleanCommitMessages(`$commits`);
}

sub getCommitsSinceCommitHash() {
    my ( $self, $hash ) = @_;
    my $commits = "cd $self->{repository_dir} && git log $hash..$self->{config}{branch} $GIT_LOG_CLEANUP";

    return $self->cleanCommitMessages(`$commits`);
}

sub cleanCommitMessages() {
    my ( $self, @commits ) = @_;
    my @output = ();

    foreach my $line (@commits) {
        if ( index( lc $line, lc $self->{config}{exclude_messages} ) == -1 ) {

            # $line = substr $line, 8;
            # if( $line =~ /(([A-Z])\w+-([0-9])\d+)/i ) {
            #     my $replace = ' ';
            #     my $replacement = ' -> ';
            #
            #     $line =~ s/$replace/$replacement/;
            # }

            push @output, $line;
        }
    }
    return @output;
}

sub incrementSemVer() {
    my ($self) = @_;
    my @latestTagSplit = split /\./, $self->getLastTag();

    if ( scalar @latestTagSplit != 3 ) {
        $self->printer->error("Project not using semver, aborting.");
        exit;
    }

    my ( $major, $minor, $patch ) = ( $latestTagSplit[0], $latestTagSplit[1], $latestTagSplit[2] );

    if ( $self->{release_type} eq 'major' ) {
        $major = $latestTagSplit[0] + 1;
        $minor = 0;
        $patch = 0;
    }
    elsif ( $self->{release_type} eq 'minor' ) {
        $minor = $latestTagSplit[1] + 1;
        $patch = 0;
    }
    elsif ( $self->{release_type} eq 'patch' || $self->{release_type} eq 'hotfix' ) {
        $patch = $latestTagSplit[2] + 1;
    }

    return "$major.$minor.$patch";
}

sub write() {
    my ( $self, @commits ) = @_;
    my $lineNr;
    my @changeLogContents;

    tie @changeLogContents, 'Tie::File', "$self->{repository_dir}/$self->{config}{file_name}" or die;

    foreach my $line ( keys @changeLogContents ) {
        if ( index( lc( $changeLogContents[$line] ), $self->{config}{file_placeholder} ) != -1 ) {
            $lineNr = $line + 1;
        }
    }

    splice @changeLogContents, $lineNr + 1, 0, "## [$self->{version}] - $self->{release_date}\n";
    $lineNr++;
    splice @changeLogContents, $lineNr + 1, 0, '';
    $lineNr++;

    foreach my $line (@commits) {
        my $txt = substr $line, 8;
        if ( index( lc $txt, lc $self->{config}{exclude_messages} ) == -1 ) {
            splice @changeLogContents, $lineNr + 1, 0, "- $txt";
            $lineNr++;
        }
    }

    splice @changeLogContents, $lineNr + 1, 0, '';
}

#@returns Printer
sub printer {
    my $self = shift;
    return $self->{printer};
}

1;
