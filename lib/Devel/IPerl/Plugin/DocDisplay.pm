package Devel::IPerl::Plugin::DocDisplay;

use strict;
use warnings;

use Devel::IPerl::Display::Markdown;
use Devel::IPerl::Display::TeX;

sub register {
	my ($self, $iperl) = @_;
	# TODO generalise the plugin registration
	for my $name (qw(markdown tex)) {
		$iperl->helper( $name => sub { shift; $self->$name(@_) } );
	}
}

sub markdown { shift; Devel::IPerl::Display::Markdown->new(@_) };
sub tex      { shift; Devel::IPerl::Display::TeX->new(@_)      };

1;
