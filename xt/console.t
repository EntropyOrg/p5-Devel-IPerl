use Test::More;

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
	my $start_string = "==== start ====";
	my $stop_string = "==== stop ====" . "abcd" x 512;
	my $start = { in => [ qq|print STDERR "$start_string\\n"; undef| ] };
	my $stop = { in => [ qq|print STDERR "$stop_string\\n"; undef| ] };

	my $code = join "\n", map { @{ $_->{in} } } ($data);

	$in = join "\n", map { @{ $_->{in} } } ($start, $data, $stop);
	note "Running code:\n", ($code =~ s/^/    /mgr ) , "";

	# TODO timeout
	run3 [$iperl_command, 'console'], \$in, \$out, \$err;

	my $out_nocolor = Term::ANSIColor::colorstrip $out;
	my $err_nocolor = Term::ANSIColor::colorstrip $err;
	$out_nocolor =~ s/[\1\2]//sg;
	$err_nocolor =~ s/[\1\2]//sg;

	#use Data::Dumper; $Data::Dumper::Useqq = 1; print Dumper( $out_nocolor );
	my @repl_out = grep { /$start_string/../$stop_string/ } split "\n", $err_nocolor;
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
		data => { in => [ q|print STDERR "hey\n"|,
				  q|2 ** 8;| ],
				out => qq|hey\n1\n256| },,
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
