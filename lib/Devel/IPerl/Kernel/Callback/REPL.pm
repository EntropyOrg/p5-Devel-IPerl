package Devel::IPerl::Kernel::Callback::REPL;
$Devel::IPerl::Kernel::Callback::REPL::VERSION = '0.012';
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
	# send display_data / execute_result
	if( defined $exec_result->stdout && length $exec_result->stdout ) {
		my $stream_stdout = $msg->new_reply_to(
			msg_type => 'stream',
			content => { name => 'stdout', text => $exec_result->stdout, }
		);
		$kernel->send_message( $kernel->iopub, $stream_stdout );
	}

	if( defined $exec_result->stderr && length $exec_result->stderr ) {
		my $stream_stderr = $msg->new_reply_to(
			msg_type => 'stream',
			content => { name => 'stderr', text => $exec_result->stderr, }
		);
		$kernel->send_message( $kernel->iopub, $stream_stderr );
	}

	# REPL output
	# NOTE using execute_result
	my $results_all_displayable = List::AllUtils::all
		{ blessed($_) && $_->can('iperl_data_representations')  }
		@{ $exec_result->results // [] };
	if( defined $exec_result->last_output
		&& !$results_all_displayable
		&& length $exec_result->last_output > 0
		&& length $exec_result->last_output < REPL_OUTPUT_TOO_LONG ) {

		my $output_str = $exec_result->last_output;
		chomp($output_str);
		my $repl_output = $msg->new_reply_to(
			msg_type => 'execute_result',
			content => {
				execution_count => $self->execution_count,
				data => {
					'text/plain' => $output_str,
				},
				metadata => {},
			}
		);
		$kernel->send_message( $kernel->iopub, $repl_output );
	}

	### Send back data representations
	$self->display_data_from_exec_result( $kernel, $msg, $exec_result );

	### Send back warnings
	if( defined $exec_result->warning ) {
		# send back exception
		my $err = $msg->new_reply_to(
			msg_type => 'error',
			content => {
				ename => $exec_result->warning_name,
				evalue => "@{[ $exec_result->warning_value ]}", # must be string
				traceback => $exec_result->warning_traceback,
			}
		);
		$kernel->send_message( $kernel->iopub, $err );
	}

	### Send back errors
	if( defined $exec_result->error ) {
		# send back exception
		my $err = $msg->new_reply_to(
			msg_type => 'error',
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
					metadata => {},
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
		my @ename;
		my @evalue;
		my @traceback;
		if( $exec_result->warning_name ) {
			push @ename, $exec_result->warning_name;
			push @evalue, $exec_result->warning_value;
			push @traceback, @{ $exec_result->warning_traceback };
		}
		if( $exec_result->error ) {
			push @ename, $exec_result->exception_name;
			push @evalue, $exec_result->exception_value;
			push @traceback, @{ $exec_result->exception_traceback };
		}
		%extra_fields = (
			ename => (join " ", @ename),
			evalue => (join "\n", @evalue), # must be string
			traceback => \@traceback,
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

sub msg_complete_request {
	my ($self, $kernel, $msg, $socket ) = @_;

	### send kernel status : busy
	my $status_busy = Devel::IPerl::Message::Helper->kernel_status( $msg, 'busy' );
	$kernel->send_message( $kernel->iopub, $status_busy );

	my $code = $msg->content->{code};
	my $cursor_pos = $msg->content->{cursor_pos};

	my @matches = ();
	my $metadata = {};
	my ($status, $cursor_start, $cursor_end);
	my $matched_text = "";
	if( $self->backend->can('completion') ) {
		try {
			@matches = $self->backend->completion( $code, $cursor_pos );
			$cursor_start = $cursor_pos;
			my $len = 0;
			if( @matches ) {
				my $line_end = substr $msg->content->{code}, 0, $cursor_pos;
				my $first_match = $matches[0];
				my $first_match_len = length $first_match;
				for my $z ( reverse 0..$first_match_len ) {
					my $suffix = substr $line_end, -$z;
					my $prefix = substr $first_match, 0, $z;
					if( $suffix eq $prefix ) {
						$cursor_start = $cursor_pos - $z;
						$len = $z;
						last;
					}
				}
				$matched_text = substr($msg->content->{code}, $cursor_start, $len)
			}
			$cursor_end = $cursor_pos;
			$status = 'ok';
		} catch {
			$status = $_;
		};
	} else {
		$cursor_start = $cursor_pos;
		$cursor_end = $cursor_pos;
		$matched_text = "";
		$status = 'ok';
	}
	my $content = {
		status => $status,
		cursor_start => $cursor_start,
		cursor_end => $cursor_end,
		metadata => $metadata,
		#matched_text => $matched_text,
		matches => \@matches,
	};
	my $complete_reply = $msg->new_reply_to(
		msg_type => 'complete_reply',
		content => $content,
	);
	#use DDP; p $complete_reply;
	$kernel->send_message( $kernel->shell, $complete_reply );

	### send kernel status : idle
	my $status_idle = Devel::IPerl::Message::Helper->kernel_status( $msg, 'idle' );
	$kernel->send_message( $kernel->iopub, $status_idle );
}

sub msg_is_complete_request {
    my ($self, $kernel, $msg, $socket ) = @_;

    ### send kernel status : busy
    my $status_busy = Devel::IPerl::Message::Helper->kernel_status( $msg, 'busy' );
    $kernel->send_message( $kernel->iopub, $status_busy );

    my $content;
    if ($self->backend->is_complete( $msg->{content}{code} )) {
        $content = {
            status => 'complete',
        };
    } else {
        $content = {
            status => 'incomplete',
            indent => '',
        };
    }
    my $is_complete_reply = $msg->new_reply_to(
        msg_type => 'is_complete_reply',
        content => $content,
    );
    $kernel->send_message( $kernel->shell, $is_complete_reply );

    ### send kernel status : idle
    my $status_idle = Devel::IPerl::Message::Helper->kernel_status( $msg, 'idle' );
    $kernel->send_message( $kernel->iopub, $status_idle );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Kernel::Callback::REPL

=head1 VERSION

version 0.012

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
