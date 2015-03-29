package Devel::IPerl::DisplayableHandler;
$Devel::IPerl::DisplayableHandler::VERSION = '0.003';
use strict;
use warnings;
use Scalar::Util qw(blessed);

sub display_data_format_handler {
	my ($self, $object) = @_;
	return unless defined $object;
	if( blessed($object) && $object->can('iperl_data_representations') ) {
		return $object->iperl_data_representations;
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::DisplayableHandler

=head1 VERSION

version 0.003

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
