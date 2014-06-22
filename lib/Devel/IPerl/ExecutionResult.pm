package Devel::IPerl::ExecutionResult;

use strict;
use Moo;
use MooX::HandlesVia;

# Str
# can only be "ok", "error", or "abort"
has status => ( is => 'rw' );

sub status_ok    { $_[0]->status('ok')    }
sub status_error { $_[0]->status('error') }
sub status_abort { $_[0]->status('abort') }

sub is_status_ok    { $_[0]->status eq 'ok'    }
sub is_status_error { $_[0]->status eq 'error' }
sub is_status_abort { $_[0]->status eq 'abort' }

1;
