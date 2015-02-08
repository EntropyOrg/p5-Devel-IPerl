package Devel::IPerl::Display::CSS;

use strict;
use warnings;

use Moo;
with qw(Devel::IPerl::Display::Role::Displayable);

sub _build_mimetype { 'text/css' }
sub iperl_data_representations {
	my ($self) = @_;
	my $data = $self->_data;
	return {
		$self->mimetype => $data,
	};
}

1;
