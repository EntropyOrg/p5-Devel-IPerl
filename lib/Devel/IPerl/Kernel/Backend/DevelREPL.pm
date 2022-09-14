package Devel::IPerl::Kernel::Backend::DevelREPL;
$Devel::IPerl::Kernel::Backend::DevelREPL::VERSION = '0.012';
use strict;
use warnings;

use Log::Any qw($log);
use Devel::IPerl::ExecutionResult;
use Devel::IPerl::ReadLine::String;
use Capture::Tiny ':all';
use Moo;

has repl => ( is => 'lazy' );

sub _build_repl {
	my ($self) = @_;
	require Devel::REPL;
	$log->trace('Creating REPL: Devel::REPL');
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
sub run_line {
	my ($self, $cmd) = @_;
	my $repl = $self->repl;
	$log->tracef('Running command: %s', $cmd);
	$repl->term->cmd($cmd);
	my ($stdout, $stderr) = capture {
		$repl->run_once;
	};

	my $exec_result = Devel::IPerl::ExecutionResult->new();
	$exec_result->stdout( $stdout );
	$exec_result->stderr( $stderr );

	$exec_result->last_output( $repl->last_output );
	$exec_result->results( $repl->results );

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

	return $exec_result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Kernel::Backend::DevelREPL

=head1 VERSION

version 0.012

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
