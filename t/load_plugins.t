use Test::Most;

use strict;
use warnings;

use IPerl;

my @plugins = qw(
	CoreDisplay DocDisplay WebDisplay
);
	# TODO
	#DataFrame PDL PDLGraphicsGnuplot DataMedia

plan tests => ~~@plugins;

for my $plugin (@plugins) {
	lives_ok { IPerl->load_plugin( $plugin ) } "Loaded $plugin";
}


done_testing;
