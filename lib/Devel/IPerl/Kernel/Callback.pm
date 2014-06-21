package Devel::IPerl::Kernel::Callback;

use strict;
use namespace::autoclean;
use Moo;

sub msg_kernel_info_request {
	my ($self, $kernel, $blobs, $msg ) = @_;

	my $uuid = $blobs->[0];
	my $reply = Devel::IPerl::Kernel::Message->new(
		msg_type => 'kernel_info_reply',
		reply_to => $msg,
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
