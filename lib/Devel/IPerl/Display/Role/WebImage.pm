# ABSTRACT: A role for image objects that is used to generate HTML with parameters such as geometry.
package Devel::IPerl::Display::Role::WebImage;

use strict;
use warnings;

use Moo::Role;

with qw(Devel::IPerl::Display::Role::Displayable);

requires '_as_text_plain';
requires 'mimetype';

has [ qw[width height] ] => ( is => 'rw', predicate => 1 );

sub iperl_data_representations {
	my ($self) = @_;
	my $data = $self->_data; # TODO when data is not retrievable
	return {
		$self->mimetype => $data,
		"text/plain" => $self->_as_text_plain,
		"text/html" => qq|<img
		@{[ $self->has_width ? qq,width="@{[$self->width]}", : "" ]}
		@{[ $self->has_height ? qq,height="@{[$self->height]}", : "" ]}
		src="@{[ $self->_html_uri ]}" />|,
	};
}

1;

=head1 SYNOPSIS

    my $web_image = Displayable::With::WebImage->new(
        data => "...",
        width => '100px',
        height => '200px' );

=head1 DESCRIPTION

This role returns an HTML representation that takes into account the height and
width.

=cut
