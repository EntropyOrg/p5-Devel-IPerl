package Devel::IPerl::Display::Role::Displayable;
$Devel::IPerl::Display::Role::Displayable::VERSION = '0.009';
use strict;
use warnings;

use Moo::Role;

requires 'iperl_data_representations';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Display::Role::Displayable

=head1 VERSION

version 0.009

=head1 METHODS

=head2 iperl_data_representations

    iperl_data_representations()

Returns a hash with the MIME types (e.g., C<text/html>) as the keys and a
string representation as the values.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
