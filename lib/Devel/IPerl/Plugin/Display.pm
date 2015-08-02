package Devel::IPerl::Plugin::Display;
$Devel::IPerl::Plugin::Display::VERSION = '0.006';
use strict;
use warnings;


sub register {
	my ($self, $iperl) = @_;
	# TODO generalise the plugin registration
	for my $name (qw(display)) {
		$iperl->helper( $name => sub { shift; $self->$name(@_) } );
	}
}

sub display {
	my $self = shift;
	$IPerl::REPL->display_data( @_ );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Plugin::Display

=head1 VERSION

version 0.006

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
