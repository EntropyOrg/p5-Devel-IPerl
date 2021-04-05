package Reply::Plugin::IPerl;
$Reply::Plugin::IPerl::VERSION = '0.010';
use strict;
use warnings;

use base 'Reply::Plugin';

use Moo;
use Capture::Tiny ':all';

sub compile {
    my $self = shift;
    my ($next, @args) = @_;

    # capture compile errors
    local $SIG{__WARN__} = sub { push @{$self->{warning}}, @_ };

    $next->(@args);
}

sub execute {
    my $self = shift;
    my ($next, @args) = @_;

    my @results;
    local $SIG{__WARN__} = sub { push @{$self->{warning}}, @_ };
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
	for my $field ( qw(results stdout stderr error warning last_output) ) {
		$self->{$field} = undef;
	}
}

sub results { my $self = shift; $self->{results}; }
sub stdout { my $self = shift; $self->{stdout}; }
sub stderr { my $self = shift; $self->{stderr}; }
sub error { my $self = shift; $self->{error}; }
sub warning { my $self = shift; $self->{warning}; }
sub last_output { my $self = shift; $self->{last_output}; }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::IPerl

=head1 VERSION

version 0.010

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
