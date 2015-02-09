package Devel::IPerl::Display::IFrame;

use strict;
use warnings;

use Moo;
with qw(Devel::IPerl::Display::Role::Displayable Devel::IPerl::Display::Role::Source);

has [ qw[width height] ] => ( is => 'rw', predicate => 1 );

sub iperl_data_representations {
	my ($self) = @_;
	return unless $self->uri;
	my $html = <<"HTML";
	<iframe
	    @{[ $self->has_width  ? (qq|width="@{[$self->width]}"|)  : ""  ]}
	    @{[ $self->has_height ? (qq|height="@{[$self->height]}"|): "" ]}
	    src="@{[$self->uri]}"
	    frameborder="0"
	    allowfullscreen
	></iframe>
HTML
	return {
		"text/html" => $html,
	};
}

1;
