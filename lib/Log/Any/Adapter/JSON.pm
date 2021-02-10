package Log::Any::Adapter::JSON;
our $VERSION = '0.01';

use Log::Any::Adapter::Util qw();
use Log::Dispatch;
use strict;
use warnings;
use JSON::MaybeUTF8 qw(:v1);
use Sys::Hostname;
use Time::HiRes;
use Config;
use Fcntl qw/:flock/;
use base qw(Log::Any::Adapter::Base);
my $host        = Sys::Hostname::hostname();
my $trace_level = Log::Any::Adapter::Util::numeric_level('trace');
my $HAS_FLOCK   = $Config{d_flock} || $Config{d_fcntl_can_lock} || $Config{d_lockf};

=head2 init

Description: Setup work for Log::Any
Takes the following arguments as named parameters

=over 4

=item - C<log_level> takes a log level specified by L<Log::Any> can be a word or numeric. 

=item - C<file> A string either specifying a file path name to use for output or the word C<STDERR>
If wanting log output sent to C<STDERR>

=back

Returns undef

=cut


sub init {
    my $self = shift;
    
    if (!$self->{file}) { die "Must supply file attribute" }

    if (exists $self->{log_level} && $self->{log_level} =~ /\D/) {
        my $numeric_level = Log::Any::Adapter::Util::numeric_level($self->{log_level});
        if (!defined($numeric_level)) {
            require Carp;
            Carp::carp(sprintf 'Invalid log level "%s". Defaulting to "%s"', $self->{log_level}, 'trace');
        }
        $self->{log_level} = $numeric_level;
    }
    if (!defined $self->{log_level}) {
        $self->{log_level} = $trace_level;
    }

    my $file = $self->{file};
    unless ($file eq 'STDERR') {
        my $binmode = $self->{binmode} || ':utf8';
        $binmode = ":$binmode" unless substr($binmode, 0, 1) eq ':';
        open($self->{fh}, ">>$binmode", $file)
            or die "cannot open '$file' for append: $!";
        $self->{fh}->autoflush(1);
    }
    return undef;
}

=head2 log

Description: Takes a string and outputs it to either a file or STDERR
Takes the following argument

=over 4

=item - C<$log_message> String message to be logged 

=back

Returns undef

=cut

sub log {
    my ($self, $log_message) = @_;

    my $stack        = $self->stack_build();
    my $logstructure = {
        severity => 'warn',
        message  => $log_message,
        host     => $host,
        epoch    => Time::HiRes::time(),
        pid      => $$,
        stack    => $stack,
    };
    my $json_string = encode_json_utf8($logstructure);
    if ($self->{file} eq 'STDERR') {
        print STDERR $json_string;
    } else {
        flock($self->{fh}, LOCK_EX) if $HAS_FLOCK;
        $self->{fh}->print($json_string . "\n");
        flock($self->{fh}, LOCK_UN) if $HAS_FLOCK;
    }
    return undef;
}

=head2 stack_build

Description: Builds an Arrayref of call stack details

Takes no arguments.

Returns an ArrayRef 
  [
      {
         "file":"./test.pl",
         "method":"some_method()",
         "line":28,
         "package":"main"
      }, 
      ...
 ]
   

=cut


sub stack_build {
    my $depth = 3;
    my @stack;
    while (my @caller = caller($depth)) {
        my %frame;
        @frame{qw(package file line method)} = @caller;
        push @stack, \%frame;
    } continue {
        ++$depth;
    }
    return (\@stack);
}

# These loops create the methods that Log::Any expects to be present for each 
# log level. 
foreach my $method (Log::Any::Adapter::Util::logging_methods()) {
    no strict 'refs';
    my $method_level = Log::Any::Adapter::Util::numeric_level($method);
    *{$method} = sub { $_[0]->log($_[1]) }
}

foreach my $method (Log::Any::Adapter::Util::detection_methods()) {
    no strict 'refs';
    my $base         = substr($method, 3);
    my $method_level = Log::Any::Adapter::Util::numeric_level($base);
    *{$method} = sub {
        return !!($method_level <= $_[0]->{log_level});
    };
}

1;
