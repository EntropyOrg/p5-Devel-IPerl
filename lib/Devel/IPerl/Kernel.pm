package Devel::IPerl::Kernel;

use strict;
use warnings;

use Moo;

use ZMQ::LibZMQ3;
use ZMQ::Constants qw(ZMQ_PUB ZMQ_REP ZMQ_ROUTER);
use JSON::MaybeXS;
use Path::Class;
use IO::Async::Loop;

has zmq => ( is => 'lazy' );
sub _build_zmq { zmq_init(); }

# Loop {{{
has _loop => ( is => 'lazy' );
sub _build__loop { IO::Async::Loop->new; }
#}}}

# Connection configuration {{{
# Read in connection info from JSON file {{{
# path to JSON file with connection data
has connection_file => ( is => 'ro' );

has connection_data => ( is => 'lazy' );
sub _build_connection_data {
	my ($self) = @_;
	# read JSON file
	decode_json file($self->connection_file)->slurp;
}
after _build_connection_data => sub {
	my ($self) = @_;
	my $data = $self->connection_data;
	$self->_assign_ports_from_data( $data );
};
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
	zmq_bind( $socket, "tcp://*:$port" );
}

sub _assign_ports_from_data {
	my ($self, $data) = @_;
	for my $port_info ( qw( control_port shell_port iopub_port stdin_port hb_port ) ) {
		$self->$port_info( $data->{$port_info} ) if exists $data->{$port_info};
	}
}
#}}}
#}}}

sub run {
	my ($self) = @_;
	$self->_loop->loop_forever;
}

1;
# vim: fdm=marker
