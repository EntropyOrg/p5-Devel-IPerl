package Devel::IPerl::DisplayableHandler;

use strict;
use warnings;
use Scalar::Util qw(blessed);

sub display_data_format_handler {
	my ($self, $object) = @_;
	return unless defined $object;
	if( blessed($object) && $object->can('iperl_data_representations') ) {
		return $object->iperl_data_representations;
	}
}

1;
