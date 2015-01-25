package Devel::IPerl::Kernel::Callback::Role::REPL;

use strict;
use warnings;

use Moo::Role;

requires 'execute';

has execution_count => ( is => 'rw', default => sub { 0 } );

before execute => sub {
	my ($self, $execute_request) = @_;

	# increment counter
	$self->execution_count( $self->execution_count +  1 );
};

1;
