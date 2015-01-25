package Devel::IPerl::Display;

use strict;
use warnings;

use MIME::Base64;
use File::LibMagic;

my $magic = File::LibMagic->new();

sub display_data_format_handler {
	my ($self, $data) = @_;
	$data = '' unless length $data;
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
