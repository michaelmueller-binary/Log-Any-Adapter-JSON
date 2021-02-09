#!/usr/bin/perl
use strict;
use warnings;
use Log::Any::Adapter;
use lib './lib';
Log::Any::Adapter->set( 'JSON',file=>'./out.json',log_level => 'info' );
my $log=Log::Any->get_logger();
level1();
sub level1 {
    level2()
}
sub level2 { level3() }
sub level3 {level4()}
sub level4 {level5()}
sub level5 {my @array = caller(3); 

    my $depth = 3;
    my @stack;
    while(my @caller = caller($depth)) {
        my %frame;
        @frame{qw(package file line method)} = @caller;
        push @stack, \%frame;
    } continue {
        ++$depth;
    } 
    #use Data::Dumper::Concise;
    #warn Dumper(\@stack);
    $log->warn(\@stack);
        }




