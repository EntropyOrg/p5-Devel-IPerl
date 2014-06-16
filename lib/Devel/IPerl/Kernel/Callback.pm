package Devel::IPerl::Kernel::Callback;

use strict;
use Moo;

sub heartbeat_message {
	my ($self, $data) = @_;
	# echo data back
	return $data;
}

sub shell_message {
	# TODO
	\&heartbeat_message;
}

1;
