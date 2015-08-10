package Devel::IPerl::Display::PNG;

use strict;
use warnings;

use Moo;
with qw(Devel::IPerl::Display::Role::MIMESource Devel::IPerl::Display::Role::WebImage);

sub _as_text_plain {
	'[PNG image]', # TODO get dimensions?
}
sub _build_mimetype { 'image/png' }

=head1 DESCRIPTION

A L<Displayable|Devel::IPerl::Display::Role::Displayable> for images of MIME type C<image/png>.

=cut

1;
