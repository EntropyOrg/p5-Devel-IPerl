package Devel::IPerl::Display::Role::WebImage;
$Devel::IPerl::Display::Role::WebImage::VERSION = '0.003';
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Display::Role::WebImage

=head1 VERSION

version 0.003

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
