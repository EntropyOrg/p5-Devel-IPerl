package Devel::IPerl::Plugin::DataMedia;
$Devel::IPerl::Plugin::DataMedia::VERSION = '0.003';
use strict;
use warnings;

...

#use Data::Media::Type::Image;
#use Data::Media::Type::Audio;

sub image {
	Data::Media::Type::Image->new_from_data( @_ );
}

sub audio {
	Data::Media::Type::Audio->new_from_data( @_ );
}

sub tex {
	Data::Media::Type::Text::TeX->new_from_data( @_ );
}

sub html {
	Data::Media::Type::Text::HTML->new_from_data( @_ );
}

sub svg {
	Data::Media::Type::Image::SVG->new_from_data( @_ );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Plugin::DataMedia

=head1 VERSION

version 0.003

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
