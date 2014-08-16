package Devel::IPerl::Kernel;
$Devel::IPerl::Kernel::VERSION = '0.001';
use strict;
use warnings;
use namespace::autoclean;

use Moo;

use ZMQ::LibZMQ3;
use ZMQ::Constants
	qw( ZMQ_PUB ZMQ_REP ZMQ_ROUTER
	    ZMQ_FD
	    ZMQ_RCVMORE ZMQ_SNDMORE
	    ZMQ_FORWARDER );
use JSON::MaybeXS;
use Path::Class;
use IO::Async::Loop;
use IO::Async::Handle;
use IO::Handle;
use Devel::IPerl::Kernel::Callback::DevelREPL;
use Devel::IPerl::Message::ZMQ;

has callback => (
		is => 'rw',
		default => sub {
			Devel::IPerl::Kernel::Callback::DevelREPL->new;
		},
	);

has _heartbeat_child => ( is => 'rw' );

# the ZeroMQ context (not fork/thread-safe)
has zmq => ( is => 'lazy', clearer => 1 );
sub _build_zmq { zmq_init(); }
after clear_zmq => sub {
	my ($self) = @_;
	for my $clear_fn ( \&clear_heartbeat, \&clear_shell, \&clear_control, \&clear_stdin, \&clear_iopub ) {
		$self->$clear_fn();
	}
};

has message_format => (
	is => 'ro',
	default => sub { 'Devel::IPerl::Message::ZMQ'; },
);

# Loop {{{
has _loop => ( is => 'lazy' );
sub _build__loop { IO::Async::Loop->new; }
#}}}

# Connection configuration {{{
# Read in connection info from JSON file {{{
# path to JSON file with connection data
has connection_file => ( is => 'ro', trigger => 1 );
sub _trigger_connection_file {
	my ($self) = @_;
	$self->connection_data;
}

has connection_data => ( is => 'lazy' );
sub _build_connection_data {
	my ($self) = @_;
	# read JSON file
	my $data = decode_json file($self->connection_file)->slurp;
	$self->_connection_data_config( $data );
	$data;
}
# set configuration attributes using the connection data
sub _connection_data_config {
	my ($self, $data) = @_;
	my $conf_dispatch = {
		ip => \&ip,
		signature_scheme => \&signature_scheme,
		transport => \&transport,
		key => \&key,
	};
	for my $conf_name ( keys %$conf_dispatch ) {
		my $conf_fn = $conf_dispatch->{ $conf_name };
		$self->$conf_fn( $data->{$conf_name} ) if exists $data->{$conf_name};
	}
	$self->_assign_ports_from_data( $data );
};
#}}}
# Misc configuration {{{
has ip => ( is => 'rw' );
has transport => ( is => 'rw' );
has signature_scheme => ( is => 'rw' );
has key => ( is => 'rw' );
#}}}
# Ports {{{
# Heartbeat {{{
# REP socket
has hb_port => ( is => 'rw' );
has heartbeat => ( is => 'lazy', clearer => 1 );
sub _build_heartbeat {
	my ($self) = @_;
	$self->_create_and_bind_socket( ZMQ_REP, $self->hb_port);
}
#}}}
# Shell {{{
# ROUTER socket
has shell_port => ( is => 'rw' );
has shell => ( is => 'lazy', clearer => 1 );
sub _build_shell {
	my ($self) = @_;
	$self->_create_and_bind_socket( ZMQ_ROUTER, $self->shell_port);
}
#}}}
# Control {{{
# ROUTER socket
has control_port => ( is => 'rw' );
has control =>  ( is => 'lazy', clearer => 1 );
sub _build_control {
	my ($self) = @_;
	$self->_create_and_bind_socket( ZMQ_ROUTER, $self->control_port);
}
#}}}
# Stdin {{{
# ROUTER socket
has stdin_port => ( is => 'rw' );
has stdin => ( is => 'lazy', clearer => 1 );
sub _build_stdin {
	my ($self) = @_;
	$self->_create_and_bind_socket( ZMQ_ROUTER, $self->stdin_port);
}
#}}}
# IOPub {{{
# PUB socket
has iopub_port => ( is => 'rw' );
has iopub => ( is => 'lazy', clearer => 1 );
sub _build_iopub {
	my ($self) = @_;
	$self->_create_and_bind_socket( ZMQ_PUB, $self->iopub_port);
}
#}}}

# Helper functions {{{
sub _create_and_bind_socket {
	my ($self, $type, $port) = @_;
	die "type of socket not given" unless $type;
	die "port not given" unless $port;

	my $socket = zmq_socket( $self->zmq, $type );
	my $transport = $self->transport;
	my $ip = $self->ip;
	my $bind_address = "${transport}://${ip}:${port}";
	zmq_bind( $socket, $bind_address );
	$socket;
}

sub _assign_ports_from_data {
	my ($self, $data) = @_;
	my $port_dispatch = {
		control_port => \&control_port,
		shell_port => \&shell_port,
		iopub_port => \&iopub_port,
		stdin_port => \&stdin_port,
		hb_port => \&hb_port,
	};
	for my $port_name (keys %$port_dispatch) {
		my $port_fn = $port_dispatch->{ $port_name };
		$self->$port_fn( $data->{$port_name} ) if exists $data->{$port_name};
	}
}
#}}}
#}}}
#}}}

my @io_handles;
sub run {#{{{
	my ($self) = @_;
	STDOUT->autoflush(1);

	$self->_setup_heartbeat;

	my @socket_funcs = ( \&shell, \&control, \&stdin, \&iopub );
	for my $socket_fn (@socket_funcs) {
		my $socket = $self->$socket_fn();
		my $socket_fd = zmq_getsockopt( $socket, ZMQ_FD );
		my $io_handle = IO::Handle->new_from_fd( $socket_fd, 'r' );
		my $handle =  IO::Async::Handle->new(
			handle => $io_handle,
			on_read_ready => sub {
				my @blobs;
				while ( my $recvmsg = zmq_recvmsg( $socket, ZMQ_RCVMORE ) ) {
					my $msg = zmq_msg_data($recvmsg);
					push @blobs, $msg;
					#print "|$msg|", "\n"; #DEBUG
				}
				if( @blobs ) {
					$self->route_message(\@blobs);
				}
			},
			on_write_ready => sub { },
		);
		$self->_loop->add( $handle );
	}
	$self->_loop->loop_forever;
}

sub stop {
	my ($self) = @_;
	kill 1, $self->_heartbeat_child;

	# TODO find out why this gives the error
	# "Bad file descriptor (epoll.cpp:67)"
	$self->_loop->loop_stop;
}

sub route_message {
	my ($self, $blobs) = @_;
	my $msg = $self->message_format->message_from_zmq_blobs($blobs);
	my $fn = "msg_" . $msg->msg_type;
	if( $self->callback->can( $fn ) ) {
		$self->callback->$fn( $self, $msg );
	}
}

sub send_message {
	my ($self, $socket, $message) = @_;
	my $blobs = $message->zmq_blobs_from_message;

	zmq_msg_send($_, $socket, ZMQ_SNDMORE) for @$blobs[0..@$blobs-2];
	zmq_msg_send($blobs->[-1], $socket, 0); # done
}

sub _setup_heartbeat {
	my ($self) = @_;
	# heartbeat socket is just an echo server
	my $child = $self->_loop->spawn_child(
		code => sub {
			$self->clear_zmq; # need to create new context for this process
			zmq_device( ZMQ_FORWARDER, $self->heartbeat, $self->heartbeat );
		},
		on_exit => sub {
			zmq_close( $self->heartbeat );
			zmq_term( $self->zmq );
		},
	);
	$self->_heartbeat_child( $child );
}


#}}}

1;
# vim: fdm=marker

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Kernel

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
