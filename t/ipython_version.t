use Test::More;

use version;

ok( version->parse(qx|ipython --version|) >= version->parse(1.0), 'IPython frontend version must be >= 1.0' );

done_testing;
