package Devel::IPerl::Display::Role::Source;

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
		} elsif( eval { -f $data } ) {
			# to avoid warning about newline in filename
			unshift @args, filename => $data;
		} else {
			unshift @args, bytestream => $data;
		}
	}

	return { @args };
};

1;
