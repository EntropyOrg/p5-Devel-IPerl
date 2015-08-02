package Devel::IPerl::Plugin::ChartClicker;

use strict;
use warnings;

our $IPerl_compat = 1;

our $IPerl_format_info = {
	'SVG' => { suffix => '.svg', displayable => 'Devel::IPerl::Display::SVG' },
	'PNG' => { suffix => '.png', displayable => 'Devel::IPerl::Display::PNG' },
};

sub register {
	# needed for the plugin
	require Chart::Clicker;
	require Role::Tiny;

	Role::Tiny->apply_roles_to_package( 'Chart::Clicker', q(Devel::IPerl::Plugin::ChartClicker::IPerlRole) );
}

{
package
	Devel::IPerl::Plugin::ChartClicker::IPerlRole;

use Moo::Role;
use Capture::Tiny qw(capture_stderr capture_stdout);
use File::Temp;


sub iperl_data_representations {
	my ($cc) = @_;
	return unless $Devel::IPerl::Plugin::ChartClicker::IPerl_compat;

	my $format = uc($cc->format);
	my $format_info = $Devel::IPerl::Plugin::ChartClicker::IPerl_format_info;

	return unless exists($format_info->{$format});

	my $suffix = $format_info->{$format}{suffix};
	my $displayable = $format_info->{$format}{displayable};

	my $tmp = File::Temp->new( SUFFIX => $suffix );
	my $tmp_filename = $tmp->filename;
	capture_stderr( sub {
        $cc->write_output( $tmp_filename );
	});

	return $displayable->new( filename => $tmp_filename )->iperl_data_representations;
}

}

1;
