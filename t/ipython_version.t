use Test::More;

use version;
use File::Which;

plan tests => 2;

my $version;
my ($ipython) = grep { -x which($_) } qw(jupyter ipython ipython3 ipython2);

ok( defined $ipython, "Found ipython: $ipython");

# run either the jupyter command which outputs more information, or the ipython commands which just outputs a version
if ($ipython =~ /jupyter/) {
  $version = qx/$ipython --version | grep ipython /;
 } else {
  $version = qx/$ipython --version /;
 }
chomp($version);

$version =~ s/-dev$//; # remove dev suffix

# modern ipython has version like x.y.z, so we need to remove the last \. and any cruft ahead of that
$version =~ s/.*?(\d+)\.(\d+)\.(\d+)/\1\.\2\3/g;

ok( $version >= 1.0 , 'IPython frontend version must be >= 1.0' );

done_testing;
