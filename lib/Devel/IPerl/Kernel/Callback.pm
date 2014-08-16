package Devel::IPerl::Kernel::Callback;
$Devel::IPerl::Kernel::Callback::VERSION = '0.001';
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Kernel::Callback

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
