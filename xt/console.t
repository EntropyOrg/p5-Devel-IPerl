use Test::Most;

use strict;
use warnings;

use File::Temp;
use Term::ANSIColor 2.01;
use IPC::Run3;
use List::AllUtils qw(pairvalues);

my $iperl_command = './bin/iperl'; # TODO find using relative path FindBin

sub run_code {
	my ($data) = @_;
	my $temp = File::Temp->newdir();
	local $ENV{IPYTHONDIR} = $temp;

	my ($in, $out, $err);
	my $start = { in => [ q|print STDERR "==== start ====\n"; undef| ] };
	my $stop = { in => [ q|print STDERR "==== stop ====\n"; undef| ] };
	$in = join "\n", map { @{ $_->{in} } } ($start, $data, $stop);
	note "Running code:\n", ($in =~ s/^/    /mgr ) , "";

	# TODO timeout
	run3 [$iperl_command, 'console'], \$in, \$out, \$err;

	my $out_nocolor = Term::ANSIColor::colorstrip $out;
	my $err_nocolor = Term::ANSIColor::colorstrip $err;
	$out_nocolor =~ s/[\1\2]//sg;
	$err_nocolor =~ s/[\1\2]//sg;

	#use Data::Dumper; $Data::Dumper::Useqq = 1; print Dumper( $out_nocolor );
	my @repl_out = grep { /==== start ====/../==== stop ====/ } split "\n", $err_nocolor;
	shift @repl_out; pop @repl_out;
	my $repl_out = join "\n", @repl_out;

	$repl_out;
}

my $tests = [
	{
		name => 'test0',
		data => {
				in => [ q|$x = 2;|,
					q|2 * $x;| ],
				out => qq|2\n4| },
	},
	{
		name => 'test0',
		data => { in => [ q|print STDERR "hey\n"| ],
				out => qq|hey\n1| },,
	},
];


plan tests => ~~ @$tests;

for my $test (@$tests) {
	subtest "Test: $test->{name}", sub {
		my $data = $test->{data};
		my $out = run_code( $test->{data} );
		is( $out, $data->{out} );
	}
}




done_testing;
