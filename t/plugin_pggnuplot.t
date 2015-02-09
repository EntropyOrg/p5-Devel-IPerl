use Test::Most tests => 1;

use strict;
use warnings;

use Devel::IPerl::Plugin::PDLGraphicsGnuplot;
use PDL::Graphics::Gnuplot;
use IPerl;

IPerl->load_plugin($_) for qw(PDLGraphicsGnuplot CoreDisplay);

my $w = gpwin();
use DDP; p $w->options();

use PDL;
use PDL::Constants qw(PI);
my $theta = zeros(200)->xlinvals(0, 6*PI);

$w->plot( $theta, sin($theta) );

my $data = $w->iperl_data_representations;
#use DDP; p $data->{'text/html'};
use Path::Class;
file('/tmp/b.png')->spew( iomode => '>:raw', $data->{'image/png'} );

#use DDP; p $w->iperl_data_representations;

ok(1);

done_testing;
