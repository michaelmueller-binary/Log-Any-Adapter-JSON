package Log::Any::Adapter::JSON;
our $VERSION = '0.01';
 
use Log::Any::Adapter::Util qw();
use Log::Dispatch;
use strict;
use warnings;
use base qw(Log::Any::Adapter::Base);
use JSON::MaybeUTF8 qw(:v1);
use Sys::Hostname;
use Time::HiRes;
my $host = Sys::Hostname::hostname();
sub is_warning{
    return 1;
}

sub warning{
    my ($self,$log_message) = @_;
my ($depth, $caller, $stack) = stack_build ();


      $stack =  $self->stack_build();
    my $logstructure = {
        severity=> 'warn',
        message => $log_message,
        host => $host,
        epoch => Time::HiRes::time(),
        pid => $$,
        stack => $stack,
    };

    print STDERR encode_json_utf8($logstructure)
}


sub stack_build {
    
      my $depth = 3;
        my @stack;
        while(my @caller = caller($depth)) {
            my %frame;
            @frame{qw(package file line method)} = @caller;
            push @stack, \%frame;
        } continue {
            ++$depth;
        } 
    return (\@stack);
}



1;
