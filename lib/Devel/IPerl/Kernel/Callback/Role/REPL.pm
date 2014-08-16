package Devel::IPerl::Kernel::Callback::Role::REPL;
$Devel::IPerl::Kernel::Callback::Role::REPL::VERSION = '0.001';
use strict;
use Moo::Role;

requires 'execute';

has execution_count => ( is => 'rw', default => sub { 0 } );

before execute => sub {
	my ($self, $execute_request) = @_;

	# increment counter
	$self->execution_count( $self->execution_count +  1 );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Kernel::Callback::Role::REPL

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
