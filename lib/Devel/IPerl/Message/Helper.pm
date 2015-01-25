package Devel::IPerl::Message::Helper;

use strict;
use warnings;

sub kernel_status {
	my ($self, $msg, $status) = @_;
	$msg->new_reply_to(
		msg_type => 'status',
		content => {
			execution_state => $status,
		},
	);

}

1;
