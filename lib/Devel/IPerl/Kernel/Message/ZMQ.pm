package Devel::IPerl::Kernel::Message::ZMQ;

use strict;
use Moo;
use JSON::MaybeXS;
use Devel::IPerl::Kernel::Message;

use constant DELIMITER => '<IDS|MSG>';

has shared_key => ( is => 'rw', predicate => 1 );

# reads in message from ZMQ wire protocol
# see spec: <http://ipython.org/ipython-doc/dev/development/messaging.html#the-wire-protocol>
sub message_from_zmq_blobs {
	my ($self, $blobs) = @_;
	my $number_of_blobs = @$blobs;

	# [
	# TODO there may be multiple UUIDs, so we have to read until the delimiter
	my $uuid           = $blobs->[0]; # b'u-u-i-d',         # zmq identity(ies)
	my $delimiter      = $blobs->[1]; # b'<IDS|MSG>',       # delimiter
	my $hmac_signature = $blobs->[2]; # b'baddad42',        # HMAC signature
	my $header         = $blobs->[3]; # b'{header}',        # serialized header dict
	my $parent_header  = $blobs->[4]; # b'{parent_header}', # serialized parent header dict
	my $metadata       = $blobs->[5]; # b'{metadata}',      # serialized metadata dict
	my $content        = $blobs->[6]; # b'{content},        # serialized content dict

	#   b'blob',            # extra raw data buffer(s)
	#   ...
	my $blobs_rest = @$blobs[7..$number_of_blobs-1];
	# ]
	use DDP; p $header;
	use DDP; p $parent_header;
	use DDP; p $metadata;
	use DDP; p $content;
	Devel::IPerl::Kernel::Message->new(
		header => decode_json($header),
		parent_header => decode_json($parent_header),
		metadata => decode_json($metadata),
		content => decode_json($content),
		blobs => [ map { decode_json $_ } @$blobs_rest ]
	);
}

sub zmq_blobs_from_message {
	my ($self, $msg) = @_;

	# TODO implement HMAC signature
	my $hmac_signature = ( $self->has_shared_key ? 'TODO' : '' ); # if auth is disabled, signature is empty string

	[
		$msg->uuid,
		DELIMITER,
		$hmac_signature,
		encode_json($msg->header),
		encode_json($msg->parent_header),
		encode_json($msg->metadata),
		encode_json($msg->content),
		( map { encode_json($_) } @{ $msg->blobs } ),
	];
}

1;
