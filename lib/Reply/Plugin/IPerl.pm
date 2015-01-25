package Reply::Plugin::IPerl;

use strict;
use warnings;

use base 'Reply::Plugin';

sub mangle_result {
	my $self = shift;
	my @result = @_;

	# to avoid having the problem when result cache plugin is not loaded
	return if not @result;

	return @result;
}

1;
