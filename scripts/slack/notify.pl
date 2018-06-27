#!/usr/bin/perl

# ============================================================
#
# Slack integrations for ChangeLogger CI
#
# Version:  1.0.0
# Author:   Vladimir Strackovski <vladimir.strackovski@dlabs.si>
# Year:     2018
#
# ============================================================

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use POSIX qw/strftime/;
use ChangeLogger::Tools;

my ($action_data, $info_data, $report_url, $download_url, $error_message) = @ARGV;

if (!defined $action_data || !defined $info_data) {
    die;
}

my %action = split /[;:]/, $action_data;
my %info = split /[;:]/, $info_data;

my $action = $action{action};
my $status = $action{status};
my $user = $action{user};

my $id = $info{id};
my $display_name = $info{name};
my $version = $info{version};
my $branch = $info{branch};
my $architecture = $info{architecture};

my $message = {};

if ($status eq 'success') {
    $message = Tools::json_to_hash(Tools::read_file('scripts/slack/messages/success.json'));
    $message->{attachments}[0]->{actions}[0]->{url} = $report_url;
    $message->{attachments}[0]->{fields}[1]->{value} = $user;

    if ($action eq 'release') {
        $message->{attachments}[0]->{title} = "Release finished: $display_name :boom:";
        $message->{attachments}[0]->{text} = "_Build ID: $id _";
        $message->{attachments}[0]->{fields}[0]->{value} = "<https://bitbucket.org/nv3/project-installer|$branch>";;
        $message->{attachments}[0]->{actions}[1]->{title} = "Download";
        $message->{attachments}[0]->{actions}[1]->{url} = "$download_url/dist/current/64/clogger";
        $message->{attachments}[0]->{fields}[2]->{title} = "Target";
        $message->{attachments}[0]->{fields}[2]->{value} = "S3";
    }
    elsif ($action eq 'build') {
        $message->{attachments}[0]->{title} = "Build finished: $display_name :boom:";
        $message->{attachments}[0]->{text} = "_Build ID: $id _";
        $message->{attachments}[0]->{fields}[0]->{value} = "<https://bitbucket.org/nv3/changelogger|$branch>";;
        $message->{attachments}[0]->{fields}[2] = {};
        $message->{attachments}[0]->{actions}[1] = {};
        $message->{attachments}[0]->{footer} = "";
        $message->{attachments}[0]->{footer_link} = "";
    }
}
elsif ($status eq 'fail') {
    $message = Tools::json_to_hash(Tools::read_file('scripts/slack/messages/fail.json'));
    $message->{attachments}[0]->{color} = 'danger';
    $message->{attachments}[0]->{fields}[0]->{value} = $user;
    $message->{attachments}[0]->{actions}[0]->{url} = $report_url;

    if ($action eq 'release') {
        $message->{attachments}[0]->{title} = "RELEASE FAILED: $display_name :bangbang:";
        $message->{attachments}[0]->{text} = "_Error: $error_message _";
        $message->{attachments}[0]->{fields}[1]->{value} = 120;
        $message->{attachments}[0]->{actions}[1]->{text} = "Restart release";
    }
    elsif ($action eq 'build') {
        $message->{attachments}[0]->{title} = "BUILD FAILED: ChangeLogger version $display_name :bangbang:";
        $message->{attachments}[0]->{text} = "_Error: $error_message _";
        $message->{attachments}[0]->{fields}[1]->{value} = 110;
        $message->{attachments}[0]->{actions}[1]->{text} = "Restart build";
    }
}
elsif ($status eq 'start') {
    $message = Tools::json_to_hash(Tools::read_file('scripts/slack/messages/start.json'));

    if ($action eq 'release') {
        $message->{attachments}[0]->{title} = "$user is releasing $display_name";
        $message->{attachments}[0]->{text} = "_Build ID: $id _";
    }
    elsif ($action eq 'build') {
        $message->{attachments}[0]->{title} = "$user is building $display_name";
        $message->{attachments}[0]->{text} = "_Building branch $branch _";
    }
}

my $json = Tools::hash_to_json($message);
my $url = qq(https://hooks.slack.com/services/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);

Tools::send_post($url, $json);
