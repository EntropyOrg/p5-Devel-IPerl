package Devel::IPerl;
# ABSTRACT: Perl language kernel for Jupyter
$Devel::IPerl::VERSION = '0.012';
use strict;
use warnings;

use Devel::IPerl::Kernel;
use Devel::IPerl::NBConvert;

sub main {
	if ( @ARGV >= 1 ) {
		if( @ARGV >= 2 and $ARGV[0] eq 'kernel' ) {
			my $kernel = Devel::IPerl::Kernel->new( connection_file => $ARGV[1] );
			$kernel->run;
		} elsif( $ARGV[0] eq 'nbconvert.iperl' ) {
			shift @ARGV;
			Devel::IPerl::NBConvert->new()->run;
		}
	}
	return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl - Perl language kernel for Jupyter

=head1 VERSION

version 0.012

=head1 DESCRIPTION

See C<README.md> for installation instructions.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
