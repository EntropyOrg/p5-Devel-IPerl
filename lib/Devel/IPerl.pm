package Devel::IPerl;
# ABSTRACT: Perl language kernel for IPython

use strict;
use warnings;

use Devel::IPerl::Kernel;

sub main {
	if ( @ARGV >= 1 ) {
		Devel::IPerl::Kernel->new( connection_file => $ARGV[1] );
	}
}

main;

1;
