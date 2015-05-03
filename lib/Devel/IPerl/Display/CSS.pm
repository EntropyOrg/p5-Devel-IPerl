package Devel::IPerl::Display::CSS;
$Devel::IPerl::Display::CSS::VERSION = '0.005';
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Display::CSS

=head1 VERSION

version 0.005

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
