package Devel::IPerl::ReadLine::Role::DevelREPL;
$Devel::IPerl::ReadLine::Role::DevelREPL::VERSION = '0.001';
use strict;
use warnings;

use Moo::Role;

has last_output => ( is => 'rw' );

has error => ( is => 'rw' );

has results => ( is => 'rw', default => sub { [] } );

before run_once => sub {
	my $self = shift;
	$self->last_output(undef);
	$self->error(undef);
};

before format_result => sub {
	my ($self, @stuff) = @_;
	$self->results( \@stuff );
};

before format_error => sub {
	my ($self, $error) = @_;
	$self->error( $error );
};

after run_once => sub {
	my $self = shift;
	$self->last_output(${$self->term->string});
	$self->term->clear_output;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::ReadLine::Role::DevelREPL

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
