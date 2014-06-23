package Devel::IPerl::ReadLine::Role::DevelREPL;

use strict;
use warnings;

use Moo::Role;

has last_output => ( is => 'rw' );

has error => ( is => 'rw' );

has results => ( is => 'rw', default => sub { [] } );

before run_once => sub {
	my $self = shift;
	$self->last_output(undef);
	$self->error(undef);
};

before format_result => sub {
	my ($self, @stuff) = @_;
	$self->results( \@stuff );
};

before format_error => sub {
	my ($self, $error) = @_;
	$self->error( $error );
};

after run_once => sub {
	my $self = shift;
	$self->last_output(${$self->term->string});
	$self->term->clear_output;
};

1;
