package Devel::IPerl::Kernel::Callback::REPL;

use strict;
use warnings;

use Moo;
use Devel::IPerl::Message::Helper;
#use Devel::IPerl::Kernel::Backend::DevelREPL;
use Devel::IPerl::Kernel::Backend::Reply;
use Try::Tiny;
use Devel::IPerl::DisplayableHandler;
use namespace::autoclean;
use List::AllUtils;
use Scalar::Util qw(blessed);

use constant REPL_OUTPUT_TOO_LONG => 1024;

use Log::Any qw($log);

extends qw(Devel::IPerl::Kernel::Callback);

with qw(Devel::IPerl::Kernel::Callback::Role::REPL);

#has backend => ( is => 'rw', default => sub { Devel::IPerl::Kernel::Backend::DevelREPL->new } );
has backend => ( is => 'rw', default => sub {
		my $backend = Devel::IPerl::Kernel::Backend::Reply->new;
		$backend->run_line( q|use IPerl; IPerl->load_plugin('Default')| );
		$backend;
	} );

sub execute {
	my ($self, $kernel, $msg) = @_;

	# This is so that the current state is available for IPerl->display() [ see display_data() ].
	local $IPerl::REPL = $self;
	local $IPerl::current_msg = $msg;
	local $IPerl::current_kernel = $kernel;

	### Run code
	### Store execution status
	### e.g., any errors, exceptions
	my $exec_result = $self->backend->run_line( $msg->content->{code} );

	### Send back stdout/stderr
	# send display_data / pyout
	if( defined $exec_result->stdout && length $exec_result->stdout ) {
		my $output = $msg->new_reply_to(
			msg_type => 'pyout', # TODO this changes in v5.0 of protocol
			content => {
				execution_count => $self->execution_count,
				data => {
					'text/plain' => $exec_result->stdout,
				},
				metadata => {},
			}
		);
		$kernel->send_message( $kernel->iopub, $output );
	}

	if( defined $exec_result->stderr && length $exec_result->stderr ) {
		my $stream_stderr = $msg->new_reply_to(
			msg_type => 'stream',
			content => { name => 'stderr', data => $exec_result->stderr, }
		);
		$kernel->send_message( $kernel->iopub, $stream_stderr );
	}

	# REPL output
	# NOTE using stderr
	# TODO can IPython handle any other streams?
	# maybe only show REPL output if now display data can be shown?
	my $results_all_displayable = List::AllUtils::all
		{ blessed($_) && $_->can('iperl_data_representations')  }
		@{ $exec_result->results // [] };
	if( defined $exec_result->last_output
		&& !$results_all_displayable
		&& length $exec_result->last_output > 0
		&& length $exec_result->last_output < REPL_OUTPUT_TOO_LONG ) {
		my $stream_repl_output = $msg->new_reply_to(
			msg_type => 'stream',
			content => { name => 'stderr', data => $exec_result->last_output, }
		);
		$kernel->send_message( $kernel->iopub, $stream_repl_output );

	}

	### Send back data representations
	$self->display_data_from_exec_result( $kernel, $msg, $exec_result );

	### Send back errors
	if( defined $exec_result->error ) {
		# send back exception
		my $err = $msg->new_reply_to(
			msg_type => 'pyerr', # TODO this changes in v5.0 of protocol
			content => {
				ename => $exec_result->exception_name,
				evalue => "@{[ $exec_result->exception_value ]}", # must be string
				traceback => $exec_result->exception_traceback,
			}
		);
		$kernel->send_message( $kernel->iopub, $err );
	}

	$exec_result;
}

sub display_data {
	my ($self, @data) = @_;
	my $msg = $IPerl::current_msg;
	my $kernel = $IPerl::current_kernel;
	for my $data (@data) {
		my $data_formats = Devel::IPerl::DisplayableHandler->display_data_format_handler( $data );
		if( defined $data_formats ) {
			my $display_data_msg = $msg->new_reply_to(
				msg_type => 'display_data',
				content => {
					data => $data_formats,
				},
				metadata => {},
			);
			$kernel->send_message( $kernel->iopub, $display_data_msg );
		}
	}
}

sub display_data_from_exec_result {
	my ($self, $kernel, $msg, $exec_result) = @_;
	$self->display_data( @{ $exec_result->results || [] } );
}


sub msg_execute_request {
	my ($self, $kernel, $msg ) = @_;

	### send kernel status : busy
	my $status_busy = Devel::IPerl::Message::Helper->kernel_status( $msg, 'busy' );
	$log->tracef('send kernel status: %s', 'busy');
	$kernel->send_message( $kernel->iopub, $status_busy );

	### Send back execution status
	my $exec_result = $self->execute( $kernel, $msg );
	$self->execute_reply( $kernel, $msg, $exec_result );

	### send kernel status : idle
	my $status_idle = Devel::IPerl::Message::Helper->kernel_status( $msg, 'idle' );
	$log->tracef('send kernel status: %s', 'idle');
	$kernel->send_message( $kernel->iopub, $status_idle );
}

sub execute_reply {
	my ($self, $kernel, $msg, $exec_result) = @_;
	$log->tracef('send back execution result: %s', $exec_result);
	my %extra_fields;
	if( $exec_result->is_status_ok ) {
		%extra_fields = (
			payload => [],
			user_variables => {},
			user_expressions => {},
		);
	} elsif( $exec_result->is_status_error ) {
		%extra_fields = (
			ename => $exec_result->exception_name,
			evalue => "@{[ $exec_result->exception_value ]}", # must be string
			traceback => $exec_result->exception_traceback,
		);
	}
	my $execute_reply = $msg->new_reply_to(
		msg_type => 'execute_reply',
		content => {
			status => $exec_result->status,
			execution_count => $self->execution_count,
			%extra_fields,
		}
	);
	$kernel->send_message( $kernel->shell, $execute_reply );
}


1;
