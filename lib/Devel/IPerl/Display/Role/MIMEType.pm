package Devel::IPerl::Display::Role::MIMEType;

use strict;
use warnings;

use Moo::Role;

has mimetype => ( is => 'ro', builder => 1 );

1;
