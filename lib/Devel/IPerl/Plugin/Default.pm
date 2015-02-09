package Devel::IPerl::Plugin::Default;

use strict;
use warnings;

sub register {
	my ($self, $iperl) = @_;
	$iperl->load_plugin($_) for qw(Display CoreDisplay WebDisplay DocDisplay);
}

1;
