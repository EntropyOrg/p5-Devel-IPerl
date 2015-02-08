package Devel::IPerl::Plugin::CoreDisplay;

use strict;
use warnings;

use Devel::IPerl::Display::PNG;
use Devel::IPerl::Display::SVG;
use Devel::IPerl::Display::JPEG;
use Devel::IPerl::Display::AudioMPEG;

sub register {
	my ($self, $iperl) = @_;
	# TODO generalise the plugin registration
	for my $name (qw(png svg jpeg audio_mpeg)) {
		$iperl->helper( $name => sub { shift; $self->$name(@_) } );
	}
}

sub png        { shift; Devel::IPerl::Display::PNG->new(@_)       };
sub svg        { shift; Devel::IPerl::Display::SVG->new(@_)       };
sub jpeg       { shift; Devel::IPerl::Display::JPEG->new(@_)      };
sub audio_mpeg { shift; Devel::IPerl::Display::AudioMPEG->new(@_) };


1;
