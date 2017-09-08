package Devel::IPerl::Display::Role::Source;
$Devel::IPerl::Display::Role::Source::VERSION = '0.008';
use strict;
use warnings;

use Moo::Role;

has [ qw[bytestream filename uri] ] => ( is => 'rw' );

sub BUILDARGS {
	my ( $class, @args ) = @_;

	# if first arg is data that needs to be determined
	if( @args % 2 == 1 ) {
		my $data = shift @args;
		if( $data =~ /^http[s]?:/ ) {
			unshift @args, uri => $data;
		} elsif( eval { no warnings qw(newline); -f $data } ) {
			# using no warnings/eval to avoid warning about newline in filename
			unshift @args, filename => $data;
		} else {
			unshift @args, bytestream => $data;
		}
	}

	return { @args };
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Display::Role::Source

=head1 VERSION

version 0.008

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
