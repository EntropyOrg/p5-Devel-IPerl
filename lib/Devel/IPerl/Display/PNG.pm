package Devel::IPerl::Display::PNG;

use strict;
use warnings;

use Moo;
with qw(Devel::IPerl::Display::Role::Displayable Devel::IPerl::Display::Role::MIMESource);

sub _build_mimetype { 'image/png' }
sub iperl_data_representations {
	my ($self) = @_;
	my $data = $self->_data;
	return {
		$self->mimetype => $data,
		"text/plain" => '[PNG image]', # TODO get dimensions?
		"text/html" => qq|<img src="@{[ $self->_html_uri ]}" />|,
	};
}

1;
