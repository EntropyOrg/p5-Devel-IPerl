package Devel::IPerl::Kernel::Message::Helper;

use strict;

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
