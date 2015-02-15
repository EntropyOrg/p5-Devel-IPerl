use Test::More;

use version;

my $version = qx|ipython --version|;
$version =~ s/-dev$//; # remove dev suffix
ok( version->parse($version) >= version->parse(1.0), 'IPython frontend version must be >= 1.0' );

done_testing;
