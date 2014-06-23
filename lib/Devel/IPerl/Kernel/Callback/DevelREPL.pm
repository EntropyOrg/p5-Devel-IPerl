package Devel::IPerl::Kernel::Callback::DevelREPL;

use strict;
use Moo;
use Devel::IPerl::ExecutionResult;
use Devel::IPerl::Kernel::Message::Helper;
use Devel::REPL;
use Devel::IPerl::ReadLine::String;
use Capture::Tiny ':all';
use Try::Tiny;
use MIME::Base64;

extends qw(Devel::IPerl::Kernel::Callback);

with qw(Devel::IPerl::Kernel::Callback::Role::REPL);

has repl => ( is => 'lazy' );
sub _build_repl {
	my ($self) = @_;
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
  $repl->term->cmd($cmd);
  my ($stdout, $stderr) = capture {
    $repl->run_once;
  };
  return ($stdout, $stderr, $repl->last_output);
}

sub execute {
	my ($self, $kernel, $msg) = @_;
	my $exec_result = Devel::IPerl::ExecutionResult->new();

	# TODO: set $exec_result->status
	$exec_result->status_ok;

	my $exception;
	my ($stdout, $stderr, $string) = $self->run_repl(  $msg->content->{code} );
	if( defined $self->repl->error ) {
		$exception = $self->repl->error;
		$exec_result->status_error;
		$exec_result->exception_name( $exception->type );
		$exec_result->exception_value( $exception->message );

		# TODO get an actual traceback
		$exec_result->exception_traceback( [$exception->message] );
	}

	# send display_data / pyout
	my $output = $msg->new_reply_to(
		msg_type => 'pyout', # TODO this changes in v5.0 of protocol
		content => {
			execution_count => $self->execution_count,
			data => {
				'text/plain' => $stdout // '',
			},
			metadata => {},
		}
	);
	$kernel->send_message( $kernel->iopub, $output );

	my $stream_stderr = $msg->new_reply_to(
		msg_type => 'stream',
		content => { name => 'stderr', data => $stderr, }
	);
	$kernel->send_message( $kernel->iopub, $stream_stderr );

	$self->display_data( $kernel, $msg );

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
		my $data_formats = $self->_display_data_format( $data );
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

sub _display_data_format {
	my ($self, $data) = @_;
	if( $data =~ /^\x{89}PNG/  ) {
		return {
			"image/png" => $data,
			"text/plain" => '[PNG image]', # TODO get dimensions
			"text/html" =>
				q{<img
					src="data:image/png;base64,@{[encode_base64($data)]}"
				/>},

		};
	}
	undef;
}

sub msg_execute_request {
	my ($self, $kernel, $msg ) = @_;

	# send kernel status : busy
	my $status_busy = Devel::IPerl::Kernel::Message::Helper->kernel_status( $msg, 'busy' );
	$kernel->send_message( $kernel->iopub, $status_busy );

	my $exec_result = $self->execute( $kernel, $msg );
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

	# send kernel status : idle
	my $status_idle = Devel::IPerl::Kernel::Message::Helper->kernel_status( $msg, 'idle' );
	$kernel->send_message( $kernel->iopub, $status_idle );
}


1;
