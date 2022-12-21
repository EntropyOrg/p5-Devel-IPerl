package Devel::IPerl::NBConvert;

use strict;
use warnings;

use Getopt::Long;
use Path::Class;
use Path::Tiny;
use JSON::MaybeXS;
use Markdown::Pod;
use HTML::FromANSI;
use Moo;

has ansi_css => ( is => 'ro',
	default => sub {
		'font-family: fixedsys, lucida console, terminal, vga, monospace; line-height: 1; letter-spacing: 0; font-size: 12pt'
	});
has notebook_file => ( is => 'rw' );
has output_file => ( is => 'rw' );
has to_format => ( is => 'rw', default => sub { 'pod' }  );
has output_to_stdout => ( is => 'rw' );

sub run {
	my ($self) = @_;
	my $file = shift @ARGV;
	$self->notebook_file( path($file) );

	my $json = JSON::MaybeXS->new;
	my $data = $json->decode( $self->notebook_file->slurp_utf8 );

	my $output = $self->to_pod( $data );

	open(my $STDNEW, '>&', STDOUT);
	binmode($STDNEW, ':encoding(UTF-8)');
	print $STDNEW $output;
}

sub to_pod {
	my ($self, $nb) = @_;
	my $md2pod = Markdown::Pod->new;

	my $pod_string;

	$pod_string .= "=encoding UTF-8\n";

	for my $cell ( @{ $nb->{cells} } ) {
		if( $cell->{cell_type} eq 'markdown' ) {
			my $md = join '', @{ $cell->{source} };
			my $md2pod_encoding = 'utf-8-strict';
			my $pod_converted = $md2pod->markdown_to_pod(
				markdown => $md,
				encoding => $md2pod_encoding,
			);
			$pod_converted =~ s/\A\Q=encoding $md2pod_encoding\E\n\n//ms;
			$pod_string .= $pod_converted;
		} elsif( $cell->{cell_type} eq 'code' ) {
			my $code = join '', @{ $cell->{source} };

			# move it over for code
			$pod_string .= join '', map { s/^/  /r } @{ $cell->{source} };
			$pod_string .= "\n\n";

			my @outputs = @{ $cell->{outputs} };
			for my $output (@outputs) {
				my $data = $output->{data};
				if( exists $data->{"text/html"} ) {
					# HTML preferred
					my $html = join '', @{ $data->{"text/html"} };
					$html =~ s/\n//g;
					$html = "<p>$html</p>";
					$pod_string .= $self->_pod_html( $html );
				} elsif( exists $data->{"text/plain"} ) {
					my $ansi_input = join '', @{ $data->{"text/plain"} };
					my $html = $self->_ansi_html( $ansi_input );
					$pod_string .= $self->_pod_html( $html );
				}
			}
		}

		$pod_string .= "\n\n";
	}

	return $pod_string;
}

sub _pod_html {
	my ($self, $html) = @_;
	my $pod_string;

	$pod_string .= "=begin html\n\n";
	$pod_string .= "$html";
	$pod_string .= "\n\n=end html\n\n";

	return $pod_string;
}

sub _ansi_html {
	my ($self, $ansi_input, $css) = @_;

	my $ansi_css = join '; ', $self->ansi_css, (defined $css ? $css : () );

	local $HTML::FromANSI::Options{fill_cols} = 1; # fill all 80 cols
	local $HTML::FromANSI::Options{font_face} = '';
	local $HTML::FromANSI::Options{style} = '';
	my $html = ansi2html($ansi_input);
	$html =~ s|^<tt>|<tt><span style='$ansi_css'>|;
	$html =~ s|</tt>$|</span></tt>|;

	return $html;
}

1;
