package Reply::Plugin::IPerl;

use strict;
use warnings;

use base 'Reply::Plugin';

use Moo;
use Capture::Tiny ':all';

sub compile {
    my $self = shift;
    my ($next, @args) = @_;

    # capture compile errors
    local $SIG{__WARN__} = sub { $self->{error} = \@_ };

    $next->(@args);
}

sub execute {
    my $self = shift;
    my ($next, @args) = @_;

    my @results;
    my ($stdout, $stderr) = capture {
	    @results = $next->(@args);
    };
    $self->{stdout} = $stdout;
    $self->{stderr} = $stderr;

    @results;
}

sub print_result {
    my $self = shift;
    my ($next, @args) = @_;

    $self->{last_output} = capture {
	    $next->(@args);
    };

    $self->{last_output};
}

sub mangle_result {
	my $self = shift;
	my @result = @_;

	$self->{results} = \@result;

	# to avoid having the problem when result cache plugin is not loaded
	return if not @result;

	return @result;
}

sub mangle_error {
    my $self = shift;
    my $error = shift;

    $self->{error} = $error;
}

sub clear_data {
	my ($self) = @_;
	for my $field ( qw(results stdout stderr error last_output) ) {
		$self->{$field} = undef;
	}
}

sub results { my $self = shift; $self->{results}; }
sub stdout { my $self = shift; $self->{stdout}; }
sub stderr { my $self = shift; $self->{stderr}; }
sub error { my $self = shift; $self->{error}; }
sub last_output {
	my $self = shift;
	my $out = $self->{last_output};
	$out;
}

1;
