package Devel::IPerl::Display::TeX;

use strict;
use warnings;

use Moo;
with qw(Devel::IPerl::Display::Role::Displayable Devel::IPerl::Display::Role::Bytestream);

sub _build_mimetype { 'text/latex' }

1;
