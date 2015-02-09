package Devel::IPerl::Display::CSS;

use strict;
use warnings;

use Moo;
with qw(Devel::IPerl::Display::Role::Displayable Devel::IPerl::Display::Role::Source);

sub _build_mimetype { 'text/css' }
sub iperl_data_representations {
	my ($self) = @_;
	my $html;
	if( $self->uri ) {
		$html = <<"HTML";
<link rel="stylesheet" href="@{[$self->uri]}" type="text/css">
HTML
	} elsif( $self->bytestream ) {
		$html = <<"HTML";
<stylesheet type="text/css">
@{[ $self->bytestream ]}
</stylesheet>
HTML
	}
	return {
		"text/html" => $html,
	};
}

1;
