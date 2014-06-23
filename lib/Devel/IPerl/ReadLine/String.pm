package Devel::IPerl::ReadLine::String;

# This implements a mocked up version of the ReadLine interface.

use strict;
use warnings;

sub ReadLine { __PACKAGE__ };
sub readline { $_[0]->{cmd} }
sub cmd { $_[0]->{cmd} = $_[1] }
sub new {
	my $string;

	my $self = bless {
		cmd => $_[1]->{cmd},
		string => \$string,
	}, __PACKAGE__;

	open($self->{OUT}, '>', \${$self->{string}})
		or die "Could not open string for writing";

	$self;
}

sub string {
	my ($self) = @_;
	$self->{string};
}
sub clear_output {
	my ($self) = @_;
	${$self->{string}} = "";
	seek $self->{OUT}, 0, 0;
}
sub OUT {
	my ($self) = @_;
	$self->{OUT};
}

1;
