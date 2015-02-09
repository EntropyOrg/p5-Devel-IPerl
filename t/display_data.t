use Test::Most tests => 5;

use strict;
use warnings;

use Path::Class;
use Devel::IPerl::Display::PNG;
use Devel::IPerl::Plugin::CoreDisplay;
use IPerl;

my $png_fn = file('t/data/ccwn3p08.png');
IPerl->load_plugin($_) for qw(CoreDisplay WebDisplay);

subtest "read in the file and use a data URI" => sub {
	my $d_filename_arg = Devel::IPerl::Display::PNG->new( filename => $png_fn )->iperl_data_representations;
	like( $d_filename_arg->{'text/html'}, qr|data:image/png;base64,iVBORw0K|, 'generates data URI' );
	ok( exists $d_filename_arg->{'image/png'}, 'has the image/png representation' );

	my $d_from_coredisplay_plugin = Devel::IPerl::Plugin::CoreDisplay->png( $png_fn )->iperl_data_representations;
	is_deeply( $d_filename_arg, $d_from_coredisplay_plugin, 'CoreDisplay plugin returns the same data' );

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

subtest "JS" => sub {

	my $d_js_uri = IPerl->js('http://example.com/example.js')->iperl_data_representations;
	like( $d_js_uri->{'text/html'}, qr/<script.*src=/, 'JS contains src attribute');



	my $display_js_data = IPerl->js(<<'JS');
function test() {
};
JS
	my $d_js_data = $display_js_data->iperl_data_representations;
	like( $d_js_data->{'text/html'}, qr/<script[^>]*>.*test/s, 'JS is inside tags');

};

subtest "CSS" => sub {
	my $d_css_uri = IPerl->css('http://example.com/example.css')->iperl_data_representations;
	like( $d_css_uri->{'text/html'}, qr/<link.*href=/, 'CSS URI contains href attribute');



	my $display_css_data = IPerl->css(<<'CSS');
.header { margin: 0; }
CSS
	my $d_css_data = $display_css_data->iperl_data_representations;
	like( $d_css_data->{'text/html'}, qr|\Q<stylesheet type="text/css">\E|, 'CSS HTML has <stylesheet> tag');
};


done_testing;
