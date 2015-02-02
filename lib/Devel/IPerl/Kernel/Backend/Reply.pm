package Devel::IPerl::Kernel::Backend::Reply;

use strict;
use warnings;

use Log::Any qw($log);
use Devel::IPerl::ExecutionResult;
use Capture::Tiny ':all';
use Moo;

has repl => ( is => 'lazy' );

sub _build_repl {
	my ($self) = @_;
	require Reply;
	$log->trace('Creating REPL: Reply');

	my $repl = Reply->new(
		# needs these at a minimum
		plugins => [ qw[Packages IPerl LexicalPersistence Hints] ]
		
	);

	$repl;
}

sub run_line {
	my ($self, $cmd) = @_;
	my $repl = $self->repl;
	$log->tracef('Running command: %s', $cmd);

	capture {
		$repl->step( $cmd, 0 );
	};

	my $exec_result = Devel::IPerl::ExecutionResult->new();
	$exec_result->stdout( $repl->_concatenate_plugin('stdout') );
	$exec_result->stderr( $repl->_concatenate_plugin('stderr') );

	my @last_output = $repl->_concatenate_plugin('last_output');
	$exec_result->last_output( $last_output[0] );

	$exec_result->results( $repl->_concatenate_plugin('results') );

	# TODO capture exceptions
	$exec_result->status_ok; # TODO

	$exec_result;
}


1;
