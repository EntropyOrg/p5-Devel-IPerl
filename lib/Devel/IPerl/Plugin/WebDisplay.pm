package Devel::IPerl::Plugin::WebDisplay;
$Devel::IPerl::Plugin::WebDisplay::VERSION = '0.012';
use strict;
use warnings;

use Devel::IPerl::Display::HTML;
use Devel::IPerl::Display::JS;
use Devel::IPerl::Display::CSS;
use Devel::IPerl::Display::IFrame;

sub register {
	my ($self, $iperl) = @_;
	# TODO generalise the plugin registration
	for my $name (qw(html css js iframe)) {
		$iperl->helper( $name => sub { shift; $self->$name(@_) } );
	}
}

sub html { shift; Devel::IPerl::Display::HTML->new(@_) }
sub css  { shift; Devel::IPerl::Display::CSS->new(@_)   }
sub js   { shift; Devel::IPerl::Display::JS->new(@_)  }

sub iframe { shift; Devel::IPerl::Display::IFrame->new(@_)  }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Plugin::WebDisplay

=head1 VERSION

version 0.012

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
