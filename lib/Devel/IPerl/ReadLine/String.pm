package Devel::IPerl::ReadLine::String;
$Devel::IPerl::ReadLine::String::VERSION = '0.001';
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::ReadLine::String

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
