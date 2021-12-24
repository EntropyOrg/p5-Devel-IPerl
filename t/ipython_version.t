use Test::More;

use version;
use File::Which;

plan tests => 2;

my ($ipython) = grep { -x which($_) } qw(jupyter ipython ipython3 ipython2);

ok( defined $ipython, "Found ipython: $ipython");

# run either the jupyter command which outputs more information, or the ipython commands which just outputs a version
my $version_text = qx/$ipython --version/;
note "Got version output:\n$version_text";
my $version;
if ($ipython =~ /jupyter/) {
	($version) = $version_text =~ /^ipython\s+:\s+(.*)$/mi;
} else {
	chomp( $version = $version_text );
}

$version =~ s/-dev$//; # remove dev suffix
ok( version->parse($version) >= version->parse(1.0), 'IPython frontend version must be >= 1.0' );

done_testing;
