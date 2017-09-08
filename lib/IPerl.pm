package # hide from PAUSE
	IPerl;

use strict;
use warnings;
use Moo;
with qw( MooX::Singleton );

our $REPL;
our $current_msg;

has helpers => ( is => 'rw', default => sub { +{} } );

=method helper

    IPerl->helper( $name, $coderef )

Register helper callback.

=cut
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
