package Devel::IPerl::Display::Role::Bytestream;

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
