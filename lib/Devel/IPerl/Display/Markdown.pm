package Devel::IPerl::Display::Markdown;

use strict;
use warnings;

use Moo;
with qw(Devel::IPerl::Display::Role::Displayable);

sub _build_mimetype { 'text/markdown' }


1;
