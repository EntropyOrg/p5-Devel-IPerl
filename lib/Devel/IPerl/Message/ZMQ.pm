package Devel::IPerl::Message::ZMQ;

use strict;
use warnings;
use Moo;
use JSON::MaybeXS;
use namespace::autoclean;
use Digest::SHA qw(hmac_sha256_hex);

extends qw(Devel::IPerl::Message);

use constant DELIMITER => '<IDS|MSG>';

has zmq_uuids => ( is => 'rw', default => sub { [] } );
has shared_key => ( is => 'rw', predicate => 1 ); # has_shared_key

# reads in message from ZMQ wire protocol
# see spec: <http://ipython.org/ipython-doc/dev/development/messaging.html#the-wire-protocol>
sub message_from_zmq_blobs {
	my ($self, $blobs, %opt) = @_;

	# Read in all identifiers
	my @uuids = ();
	while (1) {
		if ($blobs->[0] eq DELIMITER) {
			shift @$blobs;
			last;
		} else {
			push @uuids, $blobs->[0];
			shift @$blobs;
		}
	}

	my $hmac_signature = $blobs->[0]; # b'baddad42',        # HMAC signature
	my $header         = $blobs->[1]; # b'{header}',        # serialized header dict
	my $parent_header  = $blobs->[2]; # b'{parent_header}', # serialized parent header dict
	my $metadata       = $blobs->[3]; # b'{metadata}',      # serialized metadata dict
	my $content        = $blobs->[4]; # b'{content},        # serialized content dict

	#   b'blob',            # extra raw data buffer(s)
	my $number_of_blobs = @$blobs;
	my @blobs_rest = ( @$blobs[5..$number_of_blobs-1] );

	# TODO check the signature
	$self->new(
		zmq_uuids => \@uuids,
		header => decode_json($header),
		parent_header => decode_json($parent_header),
		metadata => decode_json($metadata),
		content => decode_json($content),
		blobs => [ @blobs_rest ],
		%opt,
	);
}

sub messages_from_zmq_blobs {
	my ($self, $blobs, %opt) = @_;

	# UUID is at the start of the blobs
	my $uuid = $blobs->[0];

	# each messages starts with the UUID
	my @message_starts = grep { $blobs->[$_] eq $uuid } 0..@$blobs-1;
	# each message ends right before the next one starts
	my @message_ends = map { $message_starts[$_] - 1 } 1..@message_starts-1;
	# last message goes to the very end
	push @message_ends, @$blobs - 1;

	my @messages;
	for my $idx (0..@message_starts-1) {
		my $message_blobs = [ @{$blobs}[  $message_starts[$idx]..$message_ends[$idx] ] ];
		push @messages, $self->message_from_zmq_blobs( $message_blobs, %opt );
	}
	@messages;
}

sub zmq_blobs_from_message {
	my ($self) = @_;

	my $serialized;
	my @blob_order = qw( header parent_header metadata content );
	$serialized->{$_} = encode_json( $self->$_ ) for @blob_order;

	# implement HMAC signature
	my $hmac_signature;
	if( $self->has_shared_key ) {
		my $data = "";
		$data .= $serialized->{$_} for @blob_order;
		$hmac_signature = hmac_sha256_hex( $data, $self->shared_key );
	} else {
		# if auth is disabled, signature is empty string
		$hmac_signature = '';
	}

	[
		@{$self->zmq_uuids},
		DELIMITER,
		$hmac_signature,
		@$serialized{@blob_order},
		( map { encode_json($_) } @{ $self->blobs } ),
	];
}

around new_reply_to => sub {
	my $orig = shift;
	my $ret = $orig->(@_);
	$ret->shared_key( $ret->reply_to->shared_key )
		if $ret->reply_to->has_shared_key;
	$ret->zmq_uuids( $ret->reply_to->zmq_uuids );
	$ret;
};

1;
