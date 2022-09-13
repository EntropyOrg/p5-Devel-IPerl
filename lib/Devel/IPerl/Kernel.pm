package Devel::IPerl::Kernel;

use strict;
use warnings;
use namespace::autoclean;

use Moo;
use Env qw(@PATH);
use if $^O eq 'MSWin32', 'Alien::ZMQ::latest';

BEGIN {
	if ( $^O eq 'MSWin32' ) {
		unshift @PATH, Alien::ZMQ::latest->bin_dir;
	}
}


use ZMQ::FFI 1.18 qw( ZMQ_PUB ZMQ_REP ZMQ_ROUTER );
use JSON::MaybeXS;
use Path::Class;
use IO::Async::Loop;
use IO::Async::Handle;
use IO::Handle;
use IO::Async::Routine;
use Net::Async::ZMQ 0.002;
use Net::Async::ZMQ::Socket;
use Devel::IPerl::Kernel::Callback::REPL;
use Devel::IPerl::Message::ZMQ;

has callback => (
		is => 'rw',
		default => sub {
			Devel::IPerl::Kernel::Callback::REPL->new;
		},
	);

has _heartbeat_child => ( is => 'rw' );

# the ZeroMQ context (not fork/thread-safe)
has zmq => ( is => 'lazy', clearer => 1 );
sub _build_zmq { ZMQ::FFI->new }
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
		signature_scheme => \&signature_scheme, # TODO check the signature_scheme eq "hmac-sha256"
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
has key => ( is => 'rw', predicate => 1 ); # has_key
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

	my $socket = $self->zmq->socket( $type );
	my $transport = $self->transport;
	my $ip = $self->ip;
	my $bind_address = "${transport}://${ip}:${port}";
	$socket->bind( $bind_address );
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

sub run {#{{{
	my ($self) = @_;
	STDOUT->autoflush(1);

	local $ENV{PERL_IPERL_RUNNING} = 1;

	local $ENV{PERL_IPERL_IPYTHON} = 1; # in IPython environment

	$self->_setup_heartbeat;

	my $zmq = Net::Async::ZMQ->new;

	my @socket_funcs = ( \&shell, \&control, \&stdin, \&iopub );
	for my $socket_fn (@socket_funcs) {
		my $socket = $self->$socket_fn();

		my $async_socket =  Net::Async::ZMQ::Socket->new(
			socket => $socket,
			on_read_ready => sub {
				# Keep reading for more messages because the
				# socket filehandle is edge-triggered.
				#
				# See:
				# - ZMQ_FD <http://api.zeromq.org/3-2:zmq-getsockopt#toc23>
				# - <https://funcptr.net/2012/09/10/zeromq---edge-triggered-notification/>
				while (1) {
					my @blobs;
					while ( $socket->has_pollin ) {
						push @blobs, $socket->recv_multipart;
					}
					last unless (@blobs);

					$self->route_message(\@blobs, $socket);
				}
			},
		);

		$zmq->add_child( $async_socket );
	}

	$self->_loop->add( $zmq );

	$self->_loop->loop_forever;
}

sub stop {
	my ($self) = @_;
	$self->_heartbeat_child->kill('INT');
	$self->_loop->loop_stop;
}

sub route_message {
	my ($self, $blobs, $socket) = @_;
	my @msgs = $self->message_format->messages_from_zmq_blobs(
		$blobs,
		(shared_key => $self->key) x !!( $self->has_key ),
	);
	for my $msg (@msgs) {
		my $fn = "msg_" . $msg->msg_type;
		if( $self->callback->can( $fn ) ) {
			$self->callback->$fn( $self, $msg, $socket );
		}
	}
}

sub send_message {
	my ($self, $socket, $message) = @_;
	my $blobs = $message->zmq_blobs_from_message;

	$socket->send_multipart( $blobs );
}

sub kernel_exit {
	my ($self) = @_;
	$self->_heartbeat_child->kill('INT');
	$self->clear_zmq;
}

sub _setup_heartbeat {
	my ($self) = @_;
	# heartbeat socket is just an echo server
	my $child = IO::Async::Routine->new(
		code => sub {
			$self->clear_zmq; # need to create new context for this process
			my $hb = $self->heartbeat;
			while(1) {
				sleep 1;
				until( $hb->has_pollin ) {
					$hb->send($hb->recv);
				}
			}
		},
		on_return => sub {
			$self->kernel_exit;
		},
	);
	$self->_loop->add( $child );
	$SIG{INT} = sub { $self->kernel_exit };
	$self->_heartbeat_child( $child );
}


#}}}

1;
# vim: fdm=marker
