package Devel::IPerl::Kernel::Callback::DevelREPL;

use strict;
use Moo;
use Devel::IPerl::ExecutionResult;
use Devel::IPerl::Kernel::Message::Helper;

extends qw(Devel::IPerl::Kernel::Callback);

with qw(Devel::IPerl::Kernel::Callback::Role::REPL);

has repl => ( is => 'rw', lazy => 1 );
sub _build_repl {
	# TODO
}

sub execute {
	my ($self, $kernel, $msg) = @_;
	my $exec_result = Devel::IPerl::ExecutionResult->new();

	# TODO: set $exec_result->status
	$exec_result->status_ok;

	# TODO send display_data / pyout
	my $output = $msg->new_reply_to(
		msg_type => 'pyout', # this changes in v5.0 of protocol
		content => {
			execution_count => $self->execution_count,
			data => {
				'text/plain' => 'test',
			},
			metadata => {},
		}
	);
	$kernel->send_message( $kernel->iopub, $output );

	$exec_result;
}

sub msg_execute_request {
	my ($self, $kernel, $msg ) = @_;

	# send kernel status : busy
	my $status_busy = Devel::IPerl::Kernel::Message::Helper->kernel_status( $msg, 'busy' );
	$kernel->send_message( $kernel->iopub, $status_busy );

	my $exec_result = $self->execute( $kernel, $msg );
	my $execute_reply = $msg->new_reply_to(
		msg_type => 'execute_reply',
		content => {
			status => $exec_result->status,
			execution_count => $self->execution_count,
			payload => [],
			user_variables => {},
			user_expressions => {},
		}
	);
	$kernel->send_message( $kernel->shell, $execute_reply );

	# send kernel status : idle
	my $status_idle = Devel::IPerl::Kernel::Message::Helper->kernel_status( $msg, 'idle' );
	$kernel->send_message( $kernel->iopub, $status_idle );
}


1;
