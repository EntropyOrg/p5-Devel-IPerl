package Devel::IPerl::Kernel::Backend::Reply;
$Devel::IPerl::Kernel::Backend::Reply::VERSION = '0.006';
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

	my @autocomplete_plugins = qw( Autocomplete::Functions Autocomplete::Globals
		Autocomplete::Keywords Autocomplete::Lexicals Autocomplete::Methods
		Autocomplete::Packages);
	my $repl = Reply->new(
		# needs these at a minimum
		plugins => [ qw[IPerl Packages LexicalPersistence Hints],
			@autocomplete_plugins ]


	);

	$repl;
}

sub completion {
	my ($self, $line, $cursor_location) = @_;

	my $repl = $self->repl;
	my $line_up_to_cursor = substr $line, 0, $cursor_location;
	my @matches = $repl->_concatenate_plugin('tab_handler', $line_up_to_cursor);
}

sub run_line {
	my ($self, $cmd) = @_;
	my $repl = $self->repl;
	$log->tracef('Running command: %s', $cmd);

	$repl->_concatenate_plugin('clear_data');

	capture {
		$repl->step( $cmd, 0 );
	};

	my $exec_result = Devel::IPerl::ExecutionResult->new();
	$exec_result->stdout( $repl->_concatenate_plugin('stdout') );
	$exec_result->stderr( $repl->_concatenate_plugin('stderr') );

	my @last_output = $repl->_concatenate_plugin('last_output');
	$last_output[0] = "" unless defined $last_output[0];
	$last_output[0] =~ s/^\n+$//g; # not sure why, but the output can just be a newline?
	$exec_result->last_output( $last_output[0] );

	$exec_result->results( $repl->_concatenate_plugin('results') );

	my $status_ok = 1;

	my $warn = [ $repl->_concatenate_plugin('warning') ];
	$exec_result->warning( @$warn ) if defined $warn->[0];
	if( defined $exec_result->warning ) {
		$status_ok = 0;
		my $warning_string = join "\n", @{$exec_result->warning};
		$exec_result->status_error; # TODO not really an error?
		$exec_result->warning_name( 'Warning' );
		$exec_result->warning_value( $warning_string );

		# TODO get an actual traceback
		$exec_result->warning_traceback( [$warning_string] );
	}

	# capture exceptions
	my @error = $repl->_concatenate_plugin('error');
	$exec_result->error( $error[0] );
	if( defined $exec_result->error ) {
		$status_ok = 0;
		my $exception = $exec_result->error;
		$exec_result->status_error;
		$exec_result->exception_name( ref($exception) || 'Error' );
		$exec_result->exception_value( $exception );

		# TODO get an actual traceback
		$exec_result->exception_traceback( [$exception] );
	}

	if( $status_ok ) {
		$exec_result->status_ok; # TODO
	}

	$exec_result;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Kernel::Backend::Reply

=head1 VERSION

version 0.006

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
