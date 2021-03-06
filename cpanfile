# Generated by scan-prereqs-cpanfile. DO NOT EDIT!
requires 'Capture::Tiny';
requires 'Devel::REPL';
requires 'Digest::SHA';
requires 'File::Copy::Recursive';
requires 'File::ShareDir';
requires 'Getopt::Long';
requires 'HTML::FromANSI';
requires 'IO::Async::Handle';
requires 'IO::Async::Loop';
requires 'IO::Async::Routine';
requires 'JSON::MaybeXS';
requires 'LWP::UserAgent';
requires 'List::AllUtils';
requires 'Log::Any';
requires 'MIME::Base64';
requires 'Markdown::Pod';
requires 'Moo';
requires 'Moo::Role';
requires 'MooX::HandlesVia';
requires 'MooX::Singleton';
requires 'MooX::Types::MooseLike::Base';
requires 'MooseX::HandlesConstructor';
requires 'Net::Async::ZMQ';
requires 'Net::Async::ZMQ::Socket';
requires 'PPI::Document';
requires 'Path::Class';
requires 'Reply';
requires 'Reply::Plugin';
requires 'Scalar::Util';
requires 'Try::Tiny';
requires 'UUID::Tiny';
requires 'ZMQ::Constants';
requires 'ZMQ::LibZMQ3';
requires 'autodie';
requires 'namespace::autoclean';

on test => sub {
    requires 'File::Which';
    requires 'Test::More';
    requires 'Test::Most';
    requires 'version';
};

on develop => sub {
    requires 'File::Temp';
    requires 'Inline::Python';
    requires 'Term::ANSIColor', '2.01';
    requires 'Test::Requires';
};

if( $^O eq 'MSWin32' ) {
    requires 'Alien::ZMQ::latest';
}
