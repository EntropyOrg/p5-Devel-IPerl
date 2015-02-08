package Devel::IPerl::Display::AudioMPEG;

use strict;
use warnings;

use Moo;
with qw(Devel::IPerl::Display::Role::Displayable Devel::IPerl::Display::Role::MIMESource);

sub _build_mimetype { 'audio/mpeg' }
sub iperl_data_representations {
	my ($self) = @_;
	my $data = $self->_data;
	return {
		$self->mimetype => $data,
		"text/plain" => '[MPEG audio]', # TODO get length
		"text/html" => qq|<audio controls src="@{[ $self->_html_uri ]}" />|,
	};
}

1;
