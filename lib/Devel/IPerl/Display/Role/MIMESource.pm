package Devel::IPerl::Display::Role::MIMESource;
$Devel::IPerl::Display::Role::MIMESource::VERSION = '0.009';
use strict;
use warnings;

use autodie;
use Moo::Role;
use MooX::Types::MooseLike::Base qw(Bool);
use LWP::UserAgent;
use MIME::Base64;
use Path::Class;

with qw(Devel::IPerl::Display::Role::Source Devel::IPerl::Display::Role::MIMEType);

has use_data_uri => ( is => 'rw', isa => Bool, default => sub { 1 } );

has _data =>  ( is => 'lazy', clearer => 1, builder => 1 );

sub _build__data {
	my ($self) = @_;
	if( $self->bytestream ) {
		return $self->bytestream;
	} elsif( $self->filename ) {
		my $data = file( $self->filename )->slurp( iomode => '<:raw' );
		return $data;
	} elsif( $self->uri ) {
		my $ua = LWP::UserAgent->new();
		my $response = $ua->get( $self->uri );
		die "Could not retrieve data" unless $response->is_success;
		my $data = $response->decoded_content;
		return $data;
	}
	die "No data to build display"; # TODO create exception class
}

sub _html_uri {
	my ($self) = @_;
	if( $self->bytestream || $self->use_data_uri ) {
		return "data:@{[ $self->mimetype ]};base64,@{[ encode_base64($self->_data) ]}";
	} elsif( $self->uri ) {
		return $self->uri;
	} elsif( $self->filename ) {
		return file($self->filename)->absolute; # TODO should this be a URI? Use Path::Class:URI for that.
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Display::Role::MIMESource

=head1 VERSION

version 0.009

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
