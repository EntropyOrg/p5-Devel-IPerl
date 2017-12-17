package Devel::IPerl::Plugin::DocDisplay;
$Devel::IPerl::Plugin::DocDisplay::VERSION = '0.009';
use strict;
use warnings;

use Devel::IPerl::Display::Markdown;
use Devel::IPerl::Display::TeX;

sub register {
	my ($self, $iperl) = @_;
	# TODO generalise the plugin registration
	for my $name (qw(markdown tex)) {
		$iperl->helper( $name => sub { shift; $self->$name(@_) } );
	}
}

sub markdown { shift; Devel::IPerl::Display::Markdown->new(@_) };
sub tex      { shift; Devel::IPerl::Display::TeX->new(@_)      };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Plugin::DocDisplay

=head1 VERSION

version 0.009

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
