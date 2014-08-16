package Devel::IPerl::Display;
$Devel::IPerl::Display::VERSION = '0.001';
use strict;
use warnings;
use MIME::Base64;
use File::LibMagic;

my $magic = File::LibMagic->new();

sub display_data_format_handler {
	my ($self, $data) = @_;
	my $mimetype_charset = $magic->checktype_contents($data);
	my $mimetype = ($mimetype_charset =~ /^([^;]*)/)[0];
	if( $mimetype eq 'image/png'  ) {
		return {
			"image/png" => $data,
			"text/plain" => '[PNG image]', # TODO get dimensions
			"text/html" =>
				qq|<img
					src="data:image/png;base64,@{[encode_base64($data)]}"
				/>|,
		};
	} elsif( $mimetype eq 'audio/mpeg' ) {
		return {
			"audio/mpeg" => $data,
			"text/plain" => '[MP3 audio]', # TODO get length
			"text/html" =>
				qq|<audio controls
					src="data:audio/mpeg;base64,@{[encode_base64($data)]}"
				/>|,
		};
	}
	undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Display

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
