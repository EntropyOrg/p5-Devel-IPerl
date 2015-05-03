package Devel::IPerl::Display::Markdown;
$Devel::IPerl::Display::Markdown::VERSION = '0.004';
use strict;
use warnings;

use Moo;
with qw(Devel::IPerl::Display::Role::Displayable Devel::IPerl::Display::Role::Bytestream);

sub _build_mimetype { 'text/markdown' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Display::Markdown

=head1 VERSION

version 0.004

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
