use Test::Most tests => 1;

use strict;
use warnings;

use Devel::IPerl::Plugin::PDLGraphicsGnuplot;
use PDL;
use PDL::Constants qw(PI);
use PDL::Graphics::Gnuplot;
use IPerl;

IPerl->load_plugin($_) for qw(PDLGraphicsGnuplot CoreDisplay);

sub run_plot {
	my $w = gpwin();
	#use DDP; p $w->options();

	my $theta = zeros(200)->xlinvals(0, 6*PI);

	$w->plot( $theta, sin($theta) );

	my $data = $w->iperl_data_representations;
}

lives_ok { run_plot() } 'plotting does not die';

#use DDP; p $data->{'text/html'};
#use Path::Class;
#file('/tmp/b.png')->spew( iomode => '>:raw', $data->{'image/png'} );

#use DDP; p $w->iperl_data_representations;

done_testing;
