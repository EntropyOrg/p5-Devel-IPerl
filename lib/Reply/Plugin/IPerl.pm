package Reply::Plugin::IPerl;

use strict;
use warnings;

use base 'Reply::Plugin';

use Moo;
use Capture::Tiny ':all';

sub compile {
    my $self = shift;
    my ($next, @args) = @_;

    # TODO capture compile errors
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

sub results { my $self = shift; $self->{results}; }
sub stdout { my $self = shift; $self->{stdout}; }
sub stderr { my $self = shift; $self->{stderr}; }
sub last_output {
	my $self = shift;
	my $out = $self->{last_output};
	$self->{last_output} = undef;
	$out;
}

1;