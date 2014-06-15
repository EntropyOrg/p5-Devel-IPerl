package Devel::IPerl::Kernel;

use strict;
use warnings;

use Moo;

use ZMQ::LibZMQ3;
use ZMQ::Constants
	qw( ZMQ_PUB ZMQ_REP ZMQ_ROUTER
	    ZMQ_FD ZMQ_RCVMORE );
use JSON::MaybeXS;
use Path::Class;
use IO::Async::Loop;
use IO::Async::Handle;
use IO::Handle;

has zmq => ( is => 'lazy' );
sub _build_zmq { zmq_init(); }

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
	$self->_after_connection_data( $data );
	$data;
}
sub _after_connection_data {
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
has heartbeat => ( is => 'lazy' );
sub _build_heartbeat {
	my ($self) = @_;
	$self->_create_and_bind_socket( ZMQ_REP, $self->hb_port);
}
#}}}
# Shell {{{
# ROUTER socket
has shell_port => ( is => 'rw' );
has shell => ( is => 'lazy' );
sub _build_shell {
	my ($self) = @_;
	$self->_create_and_bind_socket( ZMQ_ROUTER, $self->shell_port);
}
#}}}
# Control {{{
# ROUTER socket
has control_port => ( is => 'rw' );
has control =>  ( is => 'lazy' );
sub _build_control {
	my ($self) = @_;
	$self->_create_and_bind_socket( ZMQ_ROUTER, $self->control_port);
}
#}}}
# Stdin {{{
# ROUTER socket
has stdin_port => ( is => 'rw' );
has stdin => ( is => 'lazy' );
sub _build_stdin {
	my ($self) = @_;
	$self->_create_and_bind_socket( ZMQ_ROUTER, $self->stdin_port);
}
#}}}
# IOPub {{{
# PUB socket
has iopub_port => ( is => 'rw' );
has iopub => ( is => 'lazy' );
sub _build_iopub {
	my ($self) = @_;
	$self->_create_and_bind_socket( ZMQ_PUB, $self->iopub_port);
}
#}}}

sub _create_and_bind_socket {
	my ($self, $type, $port) = @_;
	my $socket = zmq_socket( $self->zmq, $type );
	# TODO check this
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

sub run {
	my ($self) = @_;
	STDOUT->autoflush(1);
	my @socket_funcs = ( \&heartbeat, \&shell, \&control, \&stdin, \&iopub );
	for my $socket_fn (@socket_funcs) {
		my $socket = $self->$socket_fn();
		my $socket_fd = zmq_getsockopt( $socket, ZMQ_FD );
		my $io_handle_r = IO::Handle->new_from_fd( $socket_fd, 'r' );
		my $io_handle_w = IO::Handle->new_from_fd( $socket_fd, 'w' );
		my $handle =  IO::Async::Handle->new(
			read_handle => $io_handle_r,
			write_handle => $io_handle_w,
			on_read_ready => sub {
				while ( my $recvmsg = zmq_recvmsg( $socket, ZMQ_RCVMORE ) ) {
					my $msg = zmq_msg_data($recvmsg);
					print $msg, "\n";
				}
			}
		);
		$self->_loop->add( $handle );
	}
	$self->_loop->loop_forever;
}

1;
# vim: fdm=marker
