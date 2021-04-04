package Devel::IPerl::Kernel::Callback;

use strict;
use warnings;

use Moo;
use Devel::IPerl::Message::Helper;
use namespace::autoclean;

sub msg_kernel_info_request {
	my ($self, $kernel, $msg ) = @_;

	### send kernel status : busy
	my $status_busy = Devel::IPerl::Message::Helper->kernel_status( $msg, 'busy' );
	$kernel->send_message( $kernel->iopub, $status_busy );

	my $reply = $msg->new_reply_to(
		msg_type => 'kernel_info_reply',
		content => {
			protocol_version => '5.0',
			implementation => 'iperl',
			implementation_version => $Devel::IPerl::VERSION // '0.0.0',
			language_info => {
				name => 'perl',
				version => substr($^V, 1), # 1 character past the 'v' prefix
				mimetype => 'text/x-perl',
				file_extension => '.pl',
			},
			banner => 'IPerl!',
			help_links => [
				{ text => 'MetaCPAN', url => 'https://metacpan.org/' },
				{ text => 'Perldoc', url => 'http://perldoc.perl.org/' },
				{ text => 'PDL', url => 'http://pdl.perl.org/?docs=Index&title=PDL::Index' },
			],
		}
	);
	$kernel->send_message( $kernel->shell, $reply );

	### send kernel status : idle
	my $status_idle = Devel::IPerl::Message::Helper->kernel_status( $msg, 'idle' );
	$kernel->send_message( $kernel->iopub, $status_idle );
}

sub msg_shutdown_request {
	my ($self, $kernel, $msg) = @_;

	### send kernel status : busy
	my $status_busy = Devel::IPerl::Message::Helper->kernel_status( $msg, 'busy' );
	$kernel->send_message( $kernel->iopub, $status_busy );

	my $shutdown_reply = $msg->new_reply_to(
		msg_type => 'shutdown_reply',
		content => {
			restart => 0, # TODO take $msg->restart into account
		}
	);
	$kernel->send_message( $kernel->shell, $shutdown_reply );
	$kernel->stop;

	### send kernel status : idle
	my $status_idle = Devel::IPerl::Message::Helper->kernel_status( $msg, 'idle' );
	$kernel->send_message( $kernel->iopub, $status_idle );
}

1;
