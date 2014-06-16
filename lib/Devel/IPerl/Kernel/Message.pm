package Devel::IPerl::Kernel::Message;
# ABSTRACT: implements the IPython message specification version 5.0

use strict;
use Moo;
use MooX::HandlesVia;

# header: HashRef {{{
has header => (
	is => 'rw',
	handles_via => 'Hash',
	# Header fields {{{
	handles => {
		msg_id   => [ accesor  => 'msg_id'   ], # msg_id   : UUID
		session  => [ accessor => 'session'  ], # session  : UUID
		msg_type => [ accessor => 'msg_type' ], # msg_type :  Str
		username => [ accessor => 'username' ], # username :  Str
		version  => [ accessor => 'version'  ], # version  :  Str
	}, #}}}
);
#}}}
# parent_header: HashRef {{{
has parent_header => ( is => 'rw' );
#}}}
# metadata: HashRef {{{
has metadata => ( is => 'rw' );
#}}}
# content: HashRef {{{
has content => ( is => 'rw' );
#}}}
# blobs: ArrayRef {{{
# extra raw data buffers
has blobs => ( is => 'rw', default => sub { [] } );
#}}}

1;
# vim: fdm=marker
