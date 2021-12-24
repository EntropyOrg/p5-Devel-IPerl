package # hide from PAUSE
	IPerl;

use strict;
use warnings;
use Moo;
with qw( MooX::Singleton );

our $REPL;
our $current_msg;

has helpers => ( is => 'rw', default => sub { +{} } );

sub helper {
	my ($class, $name, $cb) = @_;
	my $self = $class->instance;
	warn (qq{Helper "$name" already exists, replacing.})
		if exists $self->helpers->{$name};
	$self->add_helper($name => $cb);
}

sub add_helper {
	my ($self, $name, $cb) = @_;
	$self->helpers->{$name} = $cb;
	{
		no strict 'refs';
		no warnings 'redefine';
		*{"IPerl::$name"} = $cb;
	}
}

sub load_plugin {
	my ($class, $plugin_name) = @_;
	my $plugin_package = "Devel::IPerl::Plugin::$plugin_name";
	{ no strict; eval "require $plugin_package"; }
	$plugin_package->register( $class );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPerl

=head1 VERSION

version 0.011

=head1 METHODS

=head2 helper

    IPerl->helper( $name, $coderef )

Register helper callback.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
