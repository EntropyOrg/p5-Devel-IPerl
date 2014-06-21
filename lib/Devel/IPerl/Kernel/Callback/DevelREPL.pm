package Devel::IPerl::Kernel::Callback::DevelREPL;

use strict;
use Moo;

extends qw(Devel::IPerl::Kernel::Callback);

has execution_count => ( is => 'rw', default => sub { 0 } );

sub msg_execute_request {
	my ($self, $kernel, $blobs, $msg ) = @_;

	my $uuid = $blobs->[0];

	# send kernel status : busy
	my $status_busy = Devel::IPerl::Kernel::Message->new(
		msg_type => 'status',
		reply_to => $msg,
		content => {
			execution_state => 'busy',
		},
	);
	$kernel->send_message( $kernel->iopub, $status_busy, $uuid );

	$self->execute( $msg );
	my $execute_reply = Devel::IPerl::Kernel::Message->new(
		msg_type => 'execute_reply',
		reply_to => $msg,
		content => {
			status => 'ok',
			execution_count => $self->execution_count,
			payload => [],
			user_variables => {},
			user_expressions => {},
		}
	);
	$kernel->send_message( $kernel->shell, $execute_reply, $uuid );

	# TODO send display_data / pyout
	my $output = Devel::IPerl::Kernel::Message->new(
		msg_type => 'pyout', # this changes in v5.0 of protocol
		reply_to => $msg,
		content => {
			execution_count => $self->execution_count,
			data => {
				'text/plain' => 'test',
			},
			metadata => {},
		}
	);
	$kernel->send_message( $kernel->iopub, $output, $uuid );


	# TODO send kernel status : idle
	my $status_idle = Devel::IPerl::Kernel::Message->new(
		msg_type => 'status',
		reply_to => $msg,
		content => {
			execution_state => 'idle',
		},
	);
	$kernel->send_message( $kernel->iopub, $status_idle, $uuid );
}

sub execute {
	my ($self, $execute_request) = @_;
	$self->execution_count( $self->execution_count +  1 );
	# TODO
}

1;
