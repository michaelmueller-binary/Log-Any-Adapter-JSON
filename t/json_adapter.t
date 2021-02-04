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
plan tests => 1;
require Log::Any::Adapter;
subtest "should write valid JSON to file" => sub  {
    Log::Any::Adapter->set( 'JSON',log_level => 'info' );
    my $log;

    ok( $log=Log::Any->get_logger());

    ok( $log->warn('This was logged to STDERR'), "Will Log warn" );
   my ($stderr) = capture_stderr( sub {

    set_fixed_time(1612403081.70045);
    ok( $log->warn('This was logged to STDERR'), "Will Log warn" );
    });
    
    my $error_data;
    ok($error_data = decode_json_utf8($stderr));
    
    is($error_data->{message}, 'This was logged to STDERR');
    is($error_data->{severity}, 'warn');
    is($error_data->{host},  Sys::Hostname::hostname());
    is($error_data->{epoch}, 1612403081.70045);
    is($error_data->{pid}, $$);
    is($error_data->{stack}->[6]->{method},'Test::More::subtest'); 
    is($error_data->{stack}->[6]->{file},$0); 
    
};


