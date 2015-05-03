package Devel::IPerl::Plugin::PDLGraphicsGnuplot;
$Devel::IPerl::Plugin::PDLGraphicsGnuplot::VERSION = '0.004';
use strict;
use warnings;


our $IPerl_compat = 1;
our $IPerl_format = 'SVG';

our $IPerl_format_info = {
	'SVG' => { suffix => '.svg', displayable => 'Devel::IPerl::Display::SVG' },
	'PNG' => { suffix => '.png', displayable => 'Devel::IPerl::Display::PNG' },
};

sub register {
	# needed for the plugin
	require PDL::Graphics::Gnuplot;
	require Role::Tiny;

	Role::Tiny->apply_roles_to_package( 'PDL::Graphics::Gnuplot', q(Devel::IPerl::Plugin::PDLGraphicsGnuplot::IPerlRole) );
}

{
package
	Devel::IPerl::Plugin::PDLGraphicsGnuplot::IPerlRole;

use Moo::Role;
use Capture::Tiny qw(capture_stderr capture_stdout);
use File::Temp;

around new => sub {
	my $orig = shift;

	my $gpwin = $orig->(@_);

	if( $Devel::IPerl::Plugin::PDLGraphicsGnuplot::IPerl_compat ) {
		capture_stderr(sub {
			# capture to avoid printing out the dumping warning
			$gpwin->option( dump => 1 );
		});
	}

	return $gpwin;
};

around _printGnuplotPipe => sub {
	my $orig = shift;

	if( $Devel::IPerl::Plugin::PDLGraphicsGnuplot::IPerl_compat ) {
		my ($dump_stdout, $dump_stderr);
		local *STDOUT;
		#local *STDERR;
		open STDOUT, '>', \$dump_stdout or die "Can't open STDOUT: $!";
		#open STDERR, '>', \$dump_stderr or die "Can't open STDERR $!";
		return $orig->(@_);
	} else {
		return $orig->(@_);
	}
};

sub iperl_data_representations {
	my ($gpwin) = @_;
	return unless $Devel::IPerl::Plugin::PDLGraphicsGnuplot::IPerl_compat;
	capture_stderr(sub {
		# capture to avoid printing out the dumping warning
		$gpwin->option( dump => 0);
	});

	my $format = $Devel::IPerl::Plugin::PDLGraphicsGnuplot::IPerl_format;
	my $format_info = $Devel::IPerl::Plugin::PDLGraphicsGnuplot::IPerl_format_info;

	die "Format $format not supported" unless exists $format_info->{$format};

	my $suffix = $format_info->{$format}{suffix};
	my $displayable = $format_info->{$format}{displayable};

	my $tmp = File::Temp->new( SUFFIX => $suffix );
	my $tmp_filename = $tmp->filename;
	capture_stderr( sub {
	#$w->output( 'pngcairo', solid=>1, color=>1,font=>'Arial,10',size=>[11,8.5,'in'] );
	#$gpwin->output( 'pngcairo', solid=>1, color=>1,font=>'Arial,10',size=>[11,8.5,'in'] );
	$gpwin->option( hardcopy => $tmp_filename );
	$gpwin->replot();
	$gpwin->close;

	});

	capture_stderr( sub  {
		# capture to avoid printing out the dumping warning
		$gpwin->option( dump => 0 );
	} );

	return $displayable->new( filename => $tmp_filename )->iperl_data_representations;
}

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Plugin::PDLGraphicsGnuplot

=head1 VERSION

version 0.004

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
