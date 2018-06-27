#
# Tools
#
# Module:   ChangeLogger
# Author:   Vladimir Strackovski <vladimir.strackovski@dlabs.si>
# Year:     2018
#
package Tools;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = ('question');
use LWP::UserAgent;
use File::Basename;
use JSON::PP;
use Term::ANSIColor ('color');

our $VERSION = "0.1.0";

sub send_post {
    my ( $uri, $payload ) = @_;
    my $req = HTTP::Request->new( 'POST', $uri );
    $req->header( 'Content-Type' => 'application/json' );
    $req->content($payload);

    my $ua = LWP::UserAgent->new;
    $ua->ssl_opts( SSL_ca_file => '' );
    my $response = $ua->request($req);

    if ( $response->is_success ) {
        return $response->content;
    }

    return 1;
}

sub read_file {
    my ( $pathToFile, $createOnFalse ) = @_;
    my $output;

    if ( !-e $pathToFile and defined $createOnFalse and $createOnFalse == 1 ) {
    }

    open my $input, '<', $pathToFile or return 1;
    while (<$input>) {
        chomp;
        $output = $output . $_;

    }
    close $input or die "Error closing $pathToFile: $!";

    return $output;
}

sub hash_to_json {
    my ($contents) = @_;
    return encode_json($contents);
}

sub json_to_hash {
    my ($contents) = @_;
    return decode_json($contents);
}

sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s }

sub question {
    my ( $promptString, $defaultValue ) = @_;
    $promptString = "➜  " . $promptString;

    if ( $defaultValue && $defaultValue ne '' ) {
        print color("GREEN"), $promptString, color("YELLOW"), " [", $defaultValue, "]: ", color("reset");
    }
    else {
        print color("GREEN"), $promptString, ": ", color("reset");
    }

    $| = 1;
    $_ = <STDIN>;
    chomp;

    if ($defaultValue) {
        return $_ ? $_ : $defaultValue;
    }
    else {
        return $_;
    }
}

1;
