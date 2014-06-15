package Devel::IPerl;
# ABSTRACT: Perl language kernel for IPython

use strict;
use warnings;

use Devel::IPerl::Kernel;

sub main {
	if ( @ARGV >= 1 ) {
		my $kernel = Devel::IPerl::Kernel->new( connection_file => $ARGV[0] );
		$kernel->run;
	}
}

main;

1;
