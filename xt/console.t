use Test::Most;

use strict;
use warnings;

use File::Temp;
use Term::ANSIColor 2.01;
use IPC::Run3;

my $iperl_command = './bin/iperl'; # TODO find using relative path FindBin

sub run_code {
	my ($data) = @_;
	my $temp = File::Temp->newdir();
	local $ENV{IPYTHONDIR} = $temp;

	my ($in, $out, $err);
	$in = join "\n", map { $_->{in} } @$data;
	note "Running code:\n", ($in =~ s/^/    /mgr ) , "";

	# TODO timeout
	run3 [$iperl_command, 'console'], \$in, \$out, \$err;

	#use DDP; p $out;
	my $out_nocolor = Term::ANSIColor::colorstrip $out;
	$out_nocolor =~ s/[\1\2]//sg;

	#use Data::Dumper; $Data::Dumper::Useqq = 1; print Dumper( $out_nocolor );
	my @out = split /^
		(?:In\s*?\[(\d+)\]):
		(?:\s+?Out\s*?\[\1\]:)?/xms, $out_nocolor;
	shift @out while $out[0] !~ /^1/;
	if( index($out[-1], "Do you really want to exit ([y]/n)?") != -1 ) {
		pop @out for 0..1; # take of the last 2 because they just say "Do you really want to exit?"
	}
	use List::AllUtils qw(pairvalues);
	my @out_values = map { $_ =~ s/^\s+|\s+$//gr  } pairvalues @out;

	@out_values;
}

my $tests = [
	{
		name => 'test0',
		data => [ { in => q|$x = 2;|, out => q|2| },
			  { in => q|2 * $x;|, out => q|4| }, ],
	},
	{
		name => 'test0',
		data => [ { in => q|print "hey"|, out => q|hey| }, ],
	},
];


plan tests => ~~ @$tests;

for my $test (@$tests) {
	subtest "Test: $test->{name}", sub {
		my $data = $test->{data};
		my @out_values = run_code( $test->{data} );
		is_deeply( \@out_values, [ map { $_->{out} } @$data ] );
	}
}




done_testing;
