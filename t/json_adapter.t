use strict;
use warnings;
use lib '../lib';
use Test::More;
use File::Temp qw(tempdir);
use Log::Any::Adapter::Util qw(cmp_deeply read_file);
plan tests => 1;
require Log::Any::Adapter;
subtest "should write valid JSON to file" => sub  {
    my $tempdir = tempdir( 'name-XXXX', TMPDIR => 1, CLEANUP => 1 );
    my $file = "$tempdir/temp.log";
    Log::Any::Adapter->set( 'JSON', file=>$file,  log_level => 'info' );
    my $log;

    ok( $log=Log::Any->get_logger());
    $DB::single=1;    
    ok( $log->warn('asdasd'), "Will Log warn" );
};
