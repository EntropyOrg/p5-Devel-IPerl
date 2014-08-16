package Devel::IPerl::Message::ZMQ;
$Devel::IPerl::Message::ZMQ::VERSION = '0.001';
use strict;
use namespace::autoclean;
use Moo;
use JSON::MaybeXS;

extends qw(Devel::IPerl::Message);

use constant DELIMITER => '<IDS|MSG>';

has zmq_uuids => ( is => 'rw', default => sub { [] } );
has shared_key => ( is => 'rw', predicate => 1 ); # has_shared_key

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
	my @blobs_rest = ( @$blobs[7..$number_of_blobs-1] );
	# ]
	# TODO check the signature
	$self->new(
		zmq_uuids => [ $uuid ],
		header => decode_json($header),
		parent_header => decode_json($parent_header),
		metadata => decode_json($metadata),
		content => decode_json($content),
		blobs => [ map { decode_json($_) } @blobs_rest ],
	);
}

sub zmq_blobs_from_message {
	my ($self) = @_;

	# TODO implement HMAC signature
	my $hmac_signature = ( $self->has_shared_key ? 'TODO' : '' ); # if auth is disabled, signature is empty string

	[
		@{$self->zmq_uuids},
		DELIMITER,
		$hmac_signature,
		encode_json($self->header),
		encode_json($self->parent_header),
		encode_json($self->metadata),
		encode_json($self->content),
		( map { encode_json($_) } @{ $self->blobs } ),
	];
}

around new_reply_to => sub {
	my $orig = shift;
	my $ret = $orig->(@_);
	$ret->zmq_uuids( $ret->reply_to->zmq_uuids );
	$ret;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Message::ZMQ

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
