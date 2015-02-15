package Devel::IPerl::Display::Role::MIMEType;
$Devel::IPerl::Display::Role::MIMEType::VERSION = '0.002';
use strict;
use warnings;

use Moo::Role;

has mimetype => ( is => 'ro', builder => 1 );
requires '_build_mimetype';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Display::Role::MIMEType

=head1 VERSION

version 0.002

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
