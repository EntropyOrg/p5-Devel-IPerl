package Devel::IPerl::Kernel::Callback;

use strict;
use namespace::autoclean;
use Moo;
use UUID::Tiny ':std';

sub msg_kernel_info_request {
	my ($self, $kernel, $blobs, $msg ) = @_;

	my $uuid = $blobs->[0];
	my $reply = Devel::IPerl::Kernel::Message->new(
		header => {
			msg_type => 'kernel_info_reply',
			msg_id => create_uuid_as_string(),
			session => $msg->session,
			username => $msg->username,
		},
		parent_header => $msg->header,
		content => {
			protocol_version => '5.0',
			implementation => 'iperl',
			implementation_version => $Devel::IPerl::VERSION // '0.0.0',
			language => 'perl',
			language_version => substr($^V, 1), # 1 character past the 'v' prefix
			banner => 'IPerl!'
		}
	);
	$kernel->send_message( $kernel->shell, $reply, $uuid );
}

1;
