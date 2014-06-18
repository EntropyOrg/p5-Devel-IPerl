package Devel::IPerl::Kernel::Callback::DevelREPL;

use strict;
use Moo;

extends qw(Devel::IPerl::Kernel::Callback);

has execution_counter => ( is => 'rw' );

sub msg_execute_request {
	my ($self, $kernel, $blobs, $msg ) = @_;

	my $uuid = $blobs->[0];

	# send kernel status : busy
	my $status_busy = Devel::IPerl::Kernel::Message->new(
		header => {
			msg_type => 'status',
			msg_id => create_uuid_as_string(),
			session => $msg->session,
			username => $msg->username,
		},
		parent_header => $msg->header,
		content => {
			execution_state => 'busy',
		},
	);
	$kernel->send_message( $kernel->iopub, $status_busy, $uuid );

	$self->execute( $msg );
	my $execute_reply = Devel::IPerl::Kernel::Message->new(
		header => {
			msg_type => 'execute_reply',
			msg_id => create_uuid_as_string(),
			session => $msg->session,
			username => $msg->username,
		},
		parent_header => $msg->header,
		content => {
			status => 'ok',
			execution_count => $self->execution_count,
		}
	);
	$kernel->send_message( $kernel->shell, $execute_reply, $uuid );

	# TODO send display_data / pyout

	# TODO send kernel status : idle
	my $status_idle = Devel::IPerl::Kernel::Message->new(
		header => {
			msg_type => 'status',
			msg_id => create_uuid_as_string(),
			session => $msg->session,
			username => $msg->username,
		},
		parent_header => $msg->header,
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
