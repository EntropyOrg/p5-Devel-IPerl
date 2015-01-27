package Devel::IPerl::Kernel::Backend::Reply;

use strict;
use warnings;

use Log::Any qw($log);
use Reply;
use Devel::IPerl::ExecutionResult;
use Capture::Tiny ':all';
use Moo;

has repl => ( is => 'lazy' );

sub _build_repl {
	my ($self) = @_;
	$log->trace('Creating REPL: Reply');

	my $repl = Reply->new(
		# needs these at a minimum
		plugins => [ qw[Packages IPerl LexicalPersistence] ]
		
	);

	$repl;
}

sub run_line {
	my ($self, $cmd) = @_;
	my $repl = $self->repl;
	$log->tracef('Running command: %s', $cmd);

	my ($stdout, $stderr) = capture {
		$repl->step( $cmd, 0 );
	};

	my $exec_result = Devel::IPerl::ExecutionResult->new();
	$exec_result->status_ok; # TODO
	$exec_result->stdout( $stdout );
	$exec_result->stderr( $stderr );

	$exec_result;
}


1;
