package Devel::IPerl::Display::SVG;

use strict;
use warnings;

use Moo;
with qw(Devel::IPerl::Display::Role::Displayable Devel::IPerl::Display::Role::MIMESource Devel::IPerl::Display::Role::WebImage);

sub _as_text_plain {
	'[SVG image]', # TODO get dimensions?
}
sub _build_mimetype { 'image/svg+xml' }

1;
