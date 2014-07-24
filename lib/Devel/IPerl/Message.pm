package Devel::IPerl::Message;
# ABSTRACT: implements the IPython message specification version 5.0

use strict;
use namespace::autoclean;
use Moo;
use MooX::HandlesVia;
use UUID::Tiny ':std';
use MooseX::HandlesConstructor;

# header: HashRef {{{
has header => (
	is => 'rw',
	default => sub { {
		msg_id => create_uuid_as_string(),
	} },
	handles_via => 'Hash',
	# Header fields {{{
	handles => {
		msg_id   => [ accessor  => 'msg_id'  ], # msg_id   : UUID
		session  => [ accessor => 'session'  ], # session  : UUID
		msg_type => [ accessor => 'msg_type' ], # msg_type :  Str
		username => [ accessor => 'username' ], # username :  Str
		version  => [ accessor => 'version'  ], # version  :  Str
	}, #}}}
);
#}}}
# parent_header: HashRef {{{
has parent_header => ( is => 'rw', default => sub { {} }, );
#}}}
# metadata: HashRef {{{
has metadata => ( is => 'rw', default => sub { {} }, );
#}}}
# content: HashRef {{{
has content => ( is => 'rw', default => sub { {} }, );
#}}}
# blobs: ArrayRef {{{
# extra raw data buffers
has blobs => ( is => 'rw', default => sub { [] } );
#}}}

# isa Devel::IPerl::Message
has reply_to => ( is => 'rw', trigger => 1 );
sub _trigger_reply_to {
	my ($self) = @_;
	my $msg = $self->reply_to;
	$self->parent_header( $msg->header );
	$self->session( $msg->session );
	$self->username( $msg->username );
}

sub new_reply_to {
	my $msg = shift;
	my $class = ref $msg;
	$class->new( reply_to => $msg, @_ );
}

1;
# vim: fdm=marker
