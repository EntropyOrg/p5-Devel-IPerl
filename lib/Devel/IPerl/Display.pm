package Devel::IPerl::Display;

use strict;
use warnings;
use MIME::Base64;

sub display_data_format_handler {
	my ($self, $data) = @_;
	if( $data =~ /^\x{89}PNG/  ) {
		return {
			"image/png" => $data,
			"text/plain" => '[PNG image]', # TODO get dimensions
			"text/html" =>
				qq|<img
					src="data:image/png;base64,@{[encode_base64($data)]}"
				/>|,
		};
	}
	undef;
}

1;
