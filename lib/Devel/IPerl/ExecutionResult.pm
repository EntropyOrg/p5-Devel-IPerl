package Devel::IPerl::ExecutionResult;

use strict;
use warnings;

use Moo;
use MooX::HandlesVia;

# Str
# can only be "ok", "error", or "abort"
has status => ( is => 'rw' );

has stdout => ( is => 'rw' );

has stderr => ( is => 'rw' );

has last_output => ( is => 'rw' );

has error => ( is => 'rw' );

has warning => ( is => 'rw' );

has results => ( is => 'rw', default => sub { [] } );

use constant {
	STATUS_OK    => 'ok',
	STATUS_ERROR => 'error',
	STATUS_ABORT => 'abort',
};

sub status_ok    { $_[0]->status(STATUS_OK)    }
sub status_error { $_[0]->status(STATUS_ERROR) }
sub status_abort { $_[0]->status(STATUS_ABORT) }

sub is_status_ok    { $_[0]->status eq STATUS_OK    }
sub is_status_error { $_[0]->status eq STATUS_ERROR }
sub is_status_abort { $_[0]->status eq STATUS_ABORT }

has [qw(exception_name exception_value exception_traceback)] => ( is => 'rw' );
has [qw(warning_name warning_value warning_traceback)] => ( is => 'rw' );

1;
