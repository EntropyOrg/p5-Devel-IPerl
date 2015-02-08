use Test::Most tests => 3;

use strict;
use warnings;

use Path::Class;
use Devel::IPerl::Display::PNG;
use Devel::IPerl::Plugin::CoreDisplay;
use IPerl;

my $png_fn = file('t/data/ccwn3p08.png');

subtest "read in the file and use a data URI" => sub {
	my $d_filename_arg = Devel::IPerl::Display::PNG->new( filename => $png_fn )->iperl_data_representations;
	like( $d_filename_arg->{'text/html'}, qr|data:image/png;base64,iVBORw0K|, 'generates data URI' );
	ok( exists $d_filename_arg->{'image/png'}, 'has the image/png representation' );

	my $d_from_coredisplay_plugin = Devel::IPerl::Plugin::CoreDisplay->png( $png_fn )->iperl_data_representations;
	is_deeply( $d_filename_arg, $d_from_coredisplay_plugin, 'CoreDisplay plugin returns the same data' );

	IPerl->load_plugin('CoreDisplay');
	use DDP; IPerl->png( $png_fn );
	my $d_from_helper = IPerl->png( $png_fn )->iperl_data_representations;
	is_deeply( $d_filename_arg, $d_from_helper, 'CoreDisplay plugin [helper] returns the same data' );
};

subtest "guess that the data is a file and use a data URI" => sub {
	my $d_filename_guess = Devel::IPerl::Display::PNG->new( $png_fn )->iperl_data_representations;
	like( $d_filename_guess->{'text/html'}, qr|data:image/png;base64,iVBORw0K|, 'guesses that the data is a file' );
};

subtest "guess that the data is a file and use the full filesystem path" => sub {
	my $d_filename_arg_no_data_uri = Devel::IPerl::Display::PNG->new( $png_fn, use_data_uri => 0 )->iperl_data_representations;
	like( $d_filename_arg_no_data_uri->{'text/html'}, qr|src="\Q@{[$png_fn->absolute]}\E"|, 'guess that the data is a file and use the full path' );
};

done_testing;
