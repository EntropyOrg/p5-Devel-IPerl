use Test::More;

use strict;
use warnings;

# clean up processes:
#
#     $ pgrep -lfa IPerl
#     $ pkill -f -9 IPerl

use Encode qw(decode_utf8);
use open qw(:std :encoding(UTF-8));

use File::Temp;
use Term::ANSIColor 2.01;
use FindBin;
use File::Spec;
use Data::Dumper;
use Test::Needs qw(Expect);

local $Data::Dumper::Useqq = 1;
local $Data::Dumper::Terse = 1;

Expect->import;

# find using relative path FindBin
my $iperl_command = File::Spec->catfile($FindBin::Bin, qw(.. bin iperl));

my $temp = File::Temp->newdir();
local $ENV{IPYTHONDIR} = $temp;
# http://jupyter-core.readthedocs.io/en/latest/paths.html
local $ENV{JUPYTER_DATA_DIR}  = $temp;

my @cmd = ( $^X, $iperl_command,
	'console',          # Jupyter console front-end

	## Do not use simple prompt. It causes Expect to hang.
	#'--simple-prompt' , # turns off colors for Jupyter console
);

my $aesc = qr{ \e\[ [\d;]* m }x;
my $prompt_re = qr/$aesc In $aesc \s+ $aesc \[ $aesc \d+ $aesc \] $aesc : $aesc \s*/x;
my $output_re = qr/$aesc Out $aesc \s+ $aesc \[ $aesc \d+ $aesc \] $aesc : $aesc \s*/x;

sub run_code {
	my ($data) = @_;

	my $code = join "\n", map { @{ $_->{in} } } ($data);

	note "Running code:\n", ($code =~ s/^/    /mgr ) , "";

	my $exp = Expect->new;
	$exp->raw_pty(1);

	#$exp->exp_internal(1);
	$exp->log_stdout(0);
	#$exp->log_group(1);
	#$exp->debug(1);

	$exp->spawn( @cmd );

	my $index = 0;
	my @out_data = ();
	my $prompt_reached;
	#$exp->restart_timeout_upon_receive(1);
	$exp->expect( 2,
		[ "Directory for Perl kernel spec does not exist...\n", sub { exp_continue() } ],
		[ qr/Jupyter console .*\n/, sub {exp_continue() } ],
		[ qr/IPerl!.*/, sub { exp_continue() } ],
		[ timeout => sub { exp_continue(); } ],
		[ qr/Do you really want to exit.*/ => sub { shift->send("y\r") } ],
		[ qr/Shutting down kernel/ => sub { exp_continue() } ],
		[ qr/.*]: / => sub {
				my $self = shift;
				if( $self->match() =~ qr/Out/ ) {
					my $output = {};

					my ($things_before_out) = $self->match() =~ /(.*?) Out/x;
					$output->{stream} = decode_utf8( $self->before() . $things_before_out );
					push @out_data, $output;

					return exp_continue();
				}

				if( @out_data && $self->match =~ qr/In/ && $self->before ne '' ) {
					my $escape_str = "\e[0m\e[0m";
					my $next_out =
						decode_utf8( $self->before() )
						=~ s/( ^\Q$escape_str\E ) | ( \n\n$ )//xgr;

					$out_data[-1]->{out} = $next_out;
				}
				if( $index < @{ $data->{in} } ) {
					$self->send(  $data->{in}[$index] );
					$self->send(  "\r" );
					$index++;
				} else {
					$self->send( "\cD" );
				}
				return exp_continue();
			}
		],
		[ qr/\Q\033[8D\033[8C\033[0m\033[?12l\033[?25h\E/ => sub { return exp_continue() } ],
	);

	my $strip = sub {
		my ($text) = @_;
		my $stripped = Term::ANSIColor::colorstrip($text);
		#chomp $stripped;
		$stripped;
	};

	my $aesc_synend = "\r\n\e[J\e[?7h\e[?12l\e[?25h\e[?2004l";
	# my $aesc1 = "\e[26D$aesc_end"; my $aesc1 = "\e[28D$aesc_end"; my $aesc2 = "\e[30D$aesc_end"; my $aesc3 = "\e[32D$aesc_end";
	my $aesc_end = "\e[?7h";
	#my $end = qr/( \Q$aesc0\E | \Q\e[\E \d{2} D \Q$aesc_synend\E )/x;
	for my $index (0..@out_data-1) {
		my $part = $out_data[$index];

		$part->{out} = $strip->($part->{out});
		chomp $part->{out};

		$part->{stream} = $strip->($part->{stream});
		my $commands = $data->{in}[$index];
		#require Carp::REPL; Carp::REPL->import('repl'); repl();#DEBUG
		$part->{stream} =~ s/ \e\[ \d{2} D \Q$aesc_synend\E//x;
		$part->{stream} =~ s/\Q$aesc_end\E//x;
		$part->{stream} =~ s/^ \Q$commands\E (.*) /$1/sx;
	}

	#use Data::Dumper; $Data::Dumper::Useqq = 1; print Dumper( \@out_data );
	kill 9, $exp->pid;

	\@out_data;
}

my $tests = [
	{
		name => 'arithmetic',
		data => {
				in => [
					q|$x = 2;|,
					q|2 * $x;|,
				],
				out => [
					{ out => '2', stream => '' },
					{ out => '4', stream => '' },
				],
			},
	},
	{
		name => 'STDERR and arithmetic',
		data => { in => [
					q|print STDERR "hey"|,
					q|2 ** 8;|,
				],
				out => [
					{ out => '1', stream => 'hey' },
					{ out => '256', stream => '' },
				],
			},
	},
	{
		name => 'STDERR and newlines',
		data => { in => [
					q|print STDERR "hey\n"|,
					q|print STDERR "hey\n\n"|,
				],
				out => [
					{ out => '1', stream => "hey\n" },
					{ out => '1', stream => "hey\n\n" },
				],
			},
	},
	{
		name => 'STDERR and more newlines',
		data => { in => [
					q|print STDERR "hey\n\n\n"|
				],
				out => [
					{ out => '1', stream => "hey\n\n\n" },
				],
			},
	},
	{
		name => 'Test Unicode',
		data => { in => [
					q|print STDERR "\x{2019}\n"|
				],
				out => [
					{ out => '1', stream => "\x{2019}\n" },
				],
			},
	},
];


plan skip_all => 'Testing under Travis is flaky.' if defined $ENV{TRAVIS};

plan tests => ~~ @$tests;

for my $test (@$tests) {
	subtest "Test: $test->{name}", sub {
		my $input = $test->{data};
		my $output = run_code( $input );
		my $lines = @{ $input->{in} };
		for my $i (0..$lines-1) {
			note "Input: $input->{in}[$i]";

			my $got_out = $output->[$i]{out};
			my $exp_out = $input->{out}[$i]{out};
			is $got_out, $exp_out, "Got out output: @{[ Dumper( $exp_out ) ]}";

			my $got_stream = $output->[$i]{stream};
			my $exp_stream = $input->{out}[$i]{stream};

			is $got_stream, $exp_stream, "Got stream output: @{[ Dumper( $exp_stream ) ]}";
		}
		is_deeply( $output, $input->{out} );
	}
}




done_testing;
