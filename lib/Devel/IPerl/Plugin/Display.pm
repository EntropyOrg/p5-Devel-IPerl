package Devel::IPerl::Plugin::Display;

use strict;
use warnings;


sub register {
	my ($self, $iperl) = @_;
	# TODO generalise the plugin registration
	for my $name (qw(display)) {
		$iperl->helper( $name => sub { shift; $self->$name(@_) } );
	}
}

sub display {
	my $self = shift;
	$IPerl::REPL->display_data( @_ );
}


1;
