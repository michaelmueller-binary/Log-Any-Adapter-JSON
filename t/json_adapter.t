use strict;
use warnings;
use lib '../lib';
use Test::More;
use File::Temp qw(tempdir);
use Log::Any::Adapter::Util qw(cmp_deeply read_file);
use Capture::Tiny ':all';
use JSON::MaybeUTF8 qw(:v1);
use Sys::Hostname;
use Test::MockTime::HiRes qw( set_fixed_time );
use File::Temp qw(tempdir);
plan tests => 3;
require Log::Any::Adapter;
use Syntax::Keyword::Try;

subtest "Launch validation" => sub {

    my $error;
    try {
        Log::Any::Adapter->set('JSON');
        ok(my $log = Log::Any->get_logger());
    } catch ($e) {
        $error = $e;
    }
    like($error, qr/Must supply file attribute/, "Error when file not supplied");
};
subtest "Should write valid JSON to STDERR" => sub {
    Log::Any::Adapter->set(
        'JSON',
        file      => 'STDERR',
        log_level => 'info'
    );

    ok(my $log = Log::Any->get_logger());

    ok($log->warn('This was logged to STDERR'), "Will Log warn");
    my ($stderr) = capture_stderr(
        sub {

            set_fixed_time(1612403081.70045);
            ok($log->warn('This was logged to STDERR'), "Will Log warn");
        });

    ok(my $error_data = decode_json_utf8($stderr));

    is($error_data->{message},  'This was logged to STDERR');
    is($error_data->{severity}, 'warn');
    is($error_data->{host},     Sys::Hostname::hostname());
    is($error_data->{epoch},    1612403081.70045);
    is($error_data->{pid},      $$);
    my $stack        = $error_data->{stack};
    my $array_length = scalar(@$stack);
    my $last_entry   = $array_length - 1;
    is($error_data->{stack}->[$last_entry]->{method}, 'Test::More::subtest');
    is($error_data->{stack}->[$last_entry]->{file},   $0);

};

subtest "Should write valid JSON to file" => sub {
    my $tempdir = tempdir(
        'name-XXXX',
        TMPDIR  => 1,
        CLEANUP => 1
    );
    my $file = "$tempdir/temp.log";
    Log::Any::Adapter->set(
        'JSON',
        file      => $file,
        log_level => 'info'
    );

    ok(my $log = Log::Any->get_logger());
    $log->warn("to file");
    my $log_string = read_file($file);
    ok(my $error_data = decode_json_utf8($log_string));
    is($error_data->{message}, 'to file', "Correct Message Logged to file");
    $log->debug("Should not be logged");
    is($log_string, read_file($file), "Content of file should not have changed");
    $log->info("This should Log");
    open my $handle, '<', $file;
    chomp(my @lines = <$handle>);
    close $handle;
    is(scalar(@lines), 2, " 2 lines have now been logged");

    ok($error_data = decode_json_utf8($lines[1]));
    is($error_data->{message}, 'This should Log', "Correct second message Logged to file");

    }

