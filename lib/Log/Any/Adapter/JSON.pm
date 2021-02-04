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
my $trace_level = Log::Any::Adapter::Util::numeric_level('trace');


sub init {
    my $self = shift;
    if ( exists $self->{log_level} && $self->{log_level} =~ /\D/ ) {
        my $numeric_level = Log::Any::Adapter::Util::numeric_level( $self->{log_level} );
        if ( !defined($numeric_level) ) {
            require Carp;
            Carp::carp( sprintf 'Invalid log level "%s". Defaulting to "%s"', $self->{log_level}, 'trace' );
        }
        $self->{log_level} = $numeric_level;
    }
    if ( !defined $self->{log_level} ) {
        $self->{log_level} = $trace_level;
    }
}



sub log {
    my ($self,$log_message) = @_;

    my $stack =  $self->stack_build();
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

foreach my $method ( Log::Any::Adapter::Util::logging_methods() ) {
    no strict 'refs';
    my $method_level = Log::Any::Adapter::Util::numeric_level( $method );
    *{$method} = sub {$_[0]->log($_[1])}
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

foreach my $method ( Log::Any::Adapter::Util::detection_methods() ) {
    no strict 'refs';
    my $base = substr($method,3);
    my $method_level = Log::Any::Adapter::Util::numeric_level( $base );
    *{$method} = sub {
        return !!(  $method_level <= $_[0]->{log_level} );
    };
}

1;
