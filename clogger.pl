#!/usr/bin/perl

# ============================================================
#
# ChangeLogger
#
# <description>
#
# Version:  0.1.0
# Author:   Vladimir Strackovski <vladimir.strackovski@dlabs.si>
# Year:     2018
#
# ============================================================

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Getopt::Long;
use ChangeLogger::ChangeLogger;
use ChangeLogger::Printer;
use Par::Packer;
use Cwd;

my %args;
my ($info, $verbose, $debug);
my ($strategy, $dir, $command) = ('tag', getcwd(), @ARGV);
GetOptions(
    \%args,
    "-i"           => \$info,
    "-v"           => \$verbose,
    "-d"           => \$debug,
    "--dir=s"      => \$dir,
    "--strategy=s" => \$strategy
) or die "Invalid arguments!";

$command = defined $command ? $command : 'none';
chomp($command);

my $printer = Printer->new(
    {
        verbose => $verbose,
        debug   => $debug
    }
);

my $logger = ChangeLogger->new($dir, $strategy, $command, $printer, $verbose, $debug);
$logger->run($info);
