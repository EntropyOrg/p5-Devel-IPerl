package Devel::IPerl::Message::Helper;
$Devel::IPerl::Message::Helper::VERSION = '0.001';
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Message::Helper

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
