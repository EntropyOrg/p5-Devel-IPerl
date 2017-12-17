package Devel::IPerl::Plugin::CoreDisplay;
$Devel::IPerl::Plugin::CoreDisplay::VERSION = '0.009';
use strict;
use warnings;

use Devel::IPerl::Display::PNG;
use Devel::IPerl::Display::SVG;
use Devel::IPerl::Display::JPEG;
use Devel::IPerl::Display::AudioMPEG;

sub register {
	my ($self, $iperl) = @_;
	# TODO generalise the plugin registration
	for my $name (qw(png svg jpeg audio_mpeg)) {
		$iperl->helper( $name => sub { shift; $self->$name(@_) } );
	}
}

sub png        { shift; Devel::IPerl::Display::PNG->new(@_)       };
sub svg        { shift; Devel::IPerl::Display::SVG->new(@_)       };
sub jpeg       { shift; Devel::IPerl::Display::JPEG->new(@_)      };
sub audio_mpeg { shift; Devel::IPerl::Display::AudioMPEG->new(@_) };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Plugin::CoreDisplay

=head1 VERSION

version 0.009

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
