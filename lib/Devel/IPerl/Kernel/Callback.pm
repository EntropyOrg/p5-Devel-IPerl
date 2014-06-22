package Devel::IPerl::Kernel::Callback;

use strict;
use namespace::autoclean;
use Moo;

sub msg_kernel_info_request {
	my ($self, $kernel, $msg ) = @_;

	my $reply = $msg->new_reply_to(
		msg_type => 'kernel_info_reply',
		content => {
			protocol_version => '5.0',
			implementation => 'iperl',
			implementation_version => $Devel::IPerl::VERSION // '0.0.0',
			language => 'perl',
			language_version => substr($^V, 1), # 1 character past the 'v' prefix
			banner => 'IPerl!'
		}
	);
	$kernel->send_message( $kernel->shell, $reply );
}

sub msg_shutdown_request {
	my ($self, $kernel, $msg) = @_;
	my $shutdown_reply = $msg->new_reply_to(
		msg_type => 'shutdown_reply',
		content => {
			restart => 0, # TODO take $msg->restart into account
		}
	);
	$kernel->send_message( $kernel->shell, $shutdown_reply );
	$kernel->stop;
}

1;
