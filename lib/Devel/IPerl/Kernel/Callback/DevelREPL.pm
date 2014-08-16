package Devel::IPerl::Kernel::Callback::DevelREPL;
$Devel::IPerl::Kernel::Callback::DevelREPL::VERSION = '0.001';
use strict;
use Moo;
use Devel::IPerl::ExecutionResult;
use Devel::IPerl::Message::Helper;
use Devel::REPL;
use Devel::IPerl::ReadLine::String;
use Capture::Tiny ':all';
use Try::Tiny;
use Devel::IPerl::Display;

use constant REPL_OUTPUT_TOO_LONG => 1024;

use Log::Any qw($log);

extends qw(Devel::IPerl::Kernel::Callback);

with qw(Devel::IPerl::Kernel::Callback::Role::REPL);

has repl => ( is => 'lazy' );
sub _build_repl {
	my ($self) = @_;
	$log->trace('Creating REPL');
	my $repl = Devel::REPL->new;

	my $term = Devel::IPerl::ReadLine::String->new;
	$repl->term( $term );
	Moo::Role->apply_roles_to_object($repl, 'Devel::IPerl::ReadLine::Role::DevelREPL');

	# Devel::REPL::Plugin::LexEnv
	$repl->load_plugin('LexEnv');
	# Devel::REPL::Plugin::OutputCache
	$repl->load_plugin('OutputCache');

	# Devel::REPL::Plugin::Completion, etc.
	$repl->load_plugin('Completion');
	$repl->no_term_class_warning(1);
		# Plugin::Completion
		# do not warn that the ReadLine is not isa
		# Term::ReadLine::Gnu or Term::ReadLine::Perl
	$repl->load_plugin($_) for (
		'CompletionDriver::Keywords', # substr, while, etc
		'CompletionDriver::LexEnv',   # current environment
		'CompletionDriver::Globals',  # global variables
		'CompletionDriver::INC',      # loading new modules
		'CompletionDriver::Methods',  # class method completion
	);

	$repl->eval("no strict;");

	$repl;
}

# return the STDOUT, STDERR, and Devel::REPL's Term::Readline output
sub run_repl {
	my ($self, $cmd) = @_;
	my $repl = $self->repl;
	$log->tracef('Running command: %s', $cmd);
	$repl->term->cmd($cmd);
	my ($stdout, $stderr) = capture {
		$repl->run_once;
	};
	return ($stdout, $stderr, $repl->last_output);
}

sub execute {
	my ($self, $kernel, $msg) = @_;

	### Run code
	my ($stdout, $stderr, $repl_output) = $self->run_repl(  $msg->content->{code} );

	### Store execution status
	### e.g., any errors, exceptions
	my $exec_result = Devel::IPerl::ExecutionResult->new();
	my $exception;
	if( defined $self->repl->error ) {
		$exception = $self->repl->error;
		$exec_result->status_error;
		$exec_result->exception_name( $exception->type );
		$exec_result->exception_value( $exception->message );

		# TODO get an actual traceback
		$exec_result->exception_traceback( [$exception->message] );
	} else {
		# no exception
		$exec_result->status_ok;
	}

	### Send back stdout/stderr
	# send display_data / pyout
	if( defined $stdout && length $stdout ) {
		my $output = $msg->new_reply_to(
			msg_type => 'pyout', # TODO this changes in v5.0 of protocol
			content => {
				execution_count => $self->execution_count,
				data => {
					'text/plain' => $stdout,
				},
				metadata => {},
			}
		);
		$kernel->send_message( $kernel->iopub, $output );
	}

	if( defined $stderr && length $stderr ) {
		my $stream_stderr = $msg->new_reply_to(
			msg_type => 'stream',
			content => { name => 'stderr', data => $stderr, }
		);
		$kernel->send_message( $kernel->iopub, $stream_stderr );
	}

	# REPL output
	# NOTE using stderr
	# TODO can IPython handle any other streams?
	# maybe only show REPL output if now display data can be shown?
	if( defined $repl_output && length $repl_output > 0 && length $repl_output < REPL_OUTPUT_TOO_LONG ) {
		my $stream_repl_output = $msg->new_reply_to(
			msg_type => 'stream',
			content => { name => 'stderr', data => $repl_output, }
		);
		$kernel->send_message( $kernel->iopub, $stream_repl_output );

	}

	### Send back data representations
	$self->display_data( $kernel, $msg );

	### Send back errors
	if( defined $exception ) {
		# send back exception
		my $err = $msg->new_reply_to(
			msg_type => 'pyerr', # TODO this changes in v5.0 of protocol
			content => {
				ename => $exec_result->exception_name,
				evalue => $exec_result->exception_value,
				traceback => $exec_result->exception_traceback,
			}
		);
		$kernel->send_message( $kernel->iopub, $err );
	}

	$exec_result;
}

sub display_data {
	my ($self, $kernel, $msg) = @_;
	for my $data ( @{ $self->repl->results }) {
		my $data_formats = Devel::IPerl::Display->display_data_format_handler( $data );
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
			evalue => $exec_result->exception_value,
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Kernel::Callback::DevelREPL

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
