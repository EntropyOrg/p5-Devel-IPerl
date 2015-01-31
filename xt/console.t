use Test::Most;

use strict;
use warnings;

use File::Temp;
use Term::ANSIColor 2.01;

my $iperl_command = './bin/iperl'; # TODO find using relative path FindBin

my $temp = File::Temp->newdir();
$ENV{IPYTHONDIR} = $temp;
use IPC::Run3;

my ($in, $out, $err);

my $data = [
	{ in => q|$x = 2;|, out => q|2| },
	{ in => q|2 * $x;|, out => q|4| },
];
$in = join "\n", map { $_->{in} } @$data;
note "Running code\n", ($in =~ s/^/    /mgr ) , "";

# TODO timeout
run3 [$iperl_command, 'console'], \$in, \$out, \$err;

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

plan tests => 1;

is_deeply( \@out_values, [ map { $_->{out} } @$data ] );


#use DDP; p $in;
#use DDP; p $out;
#use DDP; p $err;


done_testing;
