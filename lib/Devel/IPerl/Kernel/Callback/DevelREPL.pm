package Devel::IPerl::Kernel::Callback::DevelREPL;

use strict;
use Moo;
use Devel::IPerl::ExecutionResult;
use Devel::IPerl::Kernel::Message::Helper;
use Devel::REPL;
use Devel::IPerl::ReadLine::String;
use Capture::Tiny ':all';
use Try::Tiny;

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

	my ($stdout, $stderr, $string);
	my $exception;
	try {
		($stdout, $stderr, $string) = $self->run_repl(  $msg->content->{code} );
	} catch {
		$exception = $_;
		$exec_result->status_error;
	};

	# send display_data / pyout
	my $output = $msg->new_reply_to(
		msg_type => 'pyout', # this changes in v5.0 of protocol
		content => {
			execution_count => $self->execution_count,
			data => {
				'text/plain' => $stdout // '',
			},
			metadata => {},
		}
	);
	$kernel->send_message( $kernel->iopub, $output );

	if( defined $exception ) {
		# TODO send back exception
	}


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
