package Devel::IPerl::Display::AudioMPEG;
$Devel::IPerl::Display::AudioMPEG::VERSION = '0.006';
use strict;
use warnings;

use Moo;
with qw(Devel::IPerl::Display::Role::Displayable Devel::IPerl::Display::Role::MIMESource);
use Try::Tiny;

sub _build_mimetype { 'audio/mpeg' }
sub iperl_data_representations {
	my ($self) = @_;
	my $data = $self->_data; # TODO when data is not retrievable
	return unless defined $data;
	return {
		$self->mimetype => $data,
		"text/plain" => '[MPEG audio]', # TODO get length
		"text/html" => qq|<audio controls src="@{[ $self->_html_uri ]}" />|,
	};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Display::AudioMPEG

=head1 VERSION

version 0.006

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
