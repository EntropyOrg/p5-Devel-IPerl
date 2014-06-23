package Devel::IPerl::ReadLine::Role::DevelREPL;

use strict;
use warnings;

use Moo::Role;

has last_output => ( is => 'rw' );

after run_once => sub {
	my $self = shift;
	$self->last_output(${$self->term->string});
	$self->term->clear_output;
};

1;
