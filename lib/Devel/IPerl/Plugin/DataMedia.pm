package Devel::IPerl::Plugin::DataMedia;

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
