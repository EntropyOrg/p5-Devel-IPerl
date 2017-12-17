package Devel::IPerl::Display::JS;
$Devel::IPerl::Display::JS::VERSION = '0.009';
use strict;
use warnings;

use Moo;
with qw(Devel::IPerl::Display::Role::Displayable Devel::IPerl::Display::Role::Source);

sub iperl_data_representations {
	my ($self) = @_;
	my $html;
	if( $self->uri ) {
		$html = <<"HTML";
 <script src="@{[$self->uri]}" type="text/javascript"></script>
HTML
	} elsif( $self->bytestream ) {
		$html = <<"HTML";
<script type="text/javascript">
@{[ $self->bytestream ]}
</script>
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

Devel::IPerl::Display::JS

=head1 VERSION

version 0.009

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
