package Devel::IPerl::Display::Role::Bytestream;
$Devel::IPerl::Display::Role::Bytestream::VERSION = '0.006';
use strict;
use warnings;

use Moo::Role;

with qw(Devel::IPerl::Display::Role::MIMEType);

has bytestream => ( is => 'rw' );

sub BUILDARGS {
	my ( $class, @args ) = @_;

	# if first arg is data that needs to be determined
	if( @args % 2 == 1 ) {
		my $data = shift @args;
		unshift @args, bytestream => $data;
	}

	return { @args };
};

sub iperl_data_representations {
	my ($self) = @_;
	return {
		$self->mimetype => $self->bytestream,
	};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Display::Role::Bytestream

=head1 VERSION

version 0.006

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
