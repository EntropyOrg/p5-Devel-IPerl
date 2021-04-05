package Devel::IPerl::Plugin::Default;
$Devel::IPerl::Plugin::Default::VERSION = '0.010';
use strict;
use warnings;

sub register {
	my ($self, $iperl) = @_;
	$iperl->load_plugin($_) for qw(Display CoreDisplay WebDisplay DocDisplay);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Plugin::Default

=head1 VERSION

version 0.010

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
