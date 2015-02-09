package Devel::IPerl::Plugin::WebDisplay;

use strict;
use warnings;

use Devel::IPerl::Display::HTML;
use Devel::IPerl::Display::JS;
use Devel::IPerl::Display::CSS;
use Devel::IPerl::Display::IFrame;

sub register {
	my ($self, $iperl) = @_;
	# TODO generalise the plugin registration
	for my $name (qw(html css js iframe)) {
		$iperl->helper( $name => sub { shift; $self->$name(@_) } );
	}
}

sub html { shift; Devel::IPerl::Display::HTML->new(@_) }
sub css  { shift; Devel::IPerl::Display::CSS->new(@_)   }
sub js   { shift; Devel::IPerl::Display::JS->new(@_)  }

sub iframe { shift; Devel::IPerl::Display::IFrame->new(@_)  }

1;
