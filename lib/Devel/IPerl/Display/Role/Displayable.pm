package Devel::IPerl::Display::Role::Displayable;

use strict;
use warnings;

use Moo::Role;

=method iperl_data_representations

    iperl_data_representations()

Returns a hash with the MIME types (e.g., C<text/html>) as the keys and a
string representation as the values.

=cut
sub iperl_data_representations {
	...
}

1;
