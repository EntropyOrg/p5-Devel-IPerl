package Devel::IPerl::ExecutionResult;

use strict;
use Moo;
use MooX::HandlesVia;

# Str
# can only be "ok", "error", or "abort"
has status => ( is => 'rw' );

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

has exception_name => ( is => 'rw' );
has exception_value => ( is => 'rw' );
has exception_traceback => ( is => 'rw' );

1;
