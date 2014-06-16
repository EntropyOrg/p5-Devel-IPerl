package Devel::IPerl::Kernel::Message;
# ABSTRACT: implements the IPython message specification version 5.0

use strict;
use Moo;
# Header fields {{{
# msg_id: UUID {{{
has msg_id => ( is => 'rw' );
#}}}
# username: Str {{{
has username => ( is => 'rw' );
#}}}
# session: UUID {{{
has session => ( is => 'rw' );
#}}}
# msg_type: Str {{{
has msg_type => ( is => 'rw' );
#}}}
# version: Str {{{
has version => ( is => 'ro', default => sub { '5.0' } );
#}}}
# header: HashRef {{{
has header => ( is => 'rw' );
#}}}
#}}}

# parent_header: HashRef {{{
has parent_header => ( is => 'rw' );
#}}}
# metadata: HashRef {{{
has metadata => ( is => 'rw' );
#}}}
# content: HashRef {{{
has content => ( is => 'rw' );
#}}}
# blobs: ArrayRef {{{
# extra raw data buffers
has blobs => ( is => 'rw', default => sub { [] } );
#}}}

1;
# vim: fdm=marker
