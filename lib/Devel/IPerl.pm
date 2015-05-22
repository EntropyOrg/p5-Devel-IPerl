package Devel::IPerl;
# ABSTRACT: Perl language kernel for IPython

use strict;
use warnings;

use Devel::IPerl::Kernel;

sub main {
	if ( @ARGV >= 1 ) {
		if( @ARGV >= 2 and $ARGV[0] eq 'kernel' ) {
			my $kernel = Devel::IPerl::Kernel->new( connection_file => $ARGV[1] );
			$kernel->run;
		}
	}
}

1;
