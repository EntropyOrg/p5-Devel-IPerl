package Devel::IPerl::Display::IFrame;
$Devel::IPerl::Display::IFrame::VERSION = '0.012';
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Display::IFrame

=head1 VERSION

version 0.012

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
