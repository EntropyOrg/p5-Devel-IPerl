# Do not edit this file directly. To change prereqs, edit the `dist.ini` file.

requires "B::Keywords" => "0";
requires "Capture::Tiny" => "0";
requires "Digest::SHA" => "0";
requires "Env" => "0";
requires "File::Copy::Recursive" => "0";
requires "File::ShareDir" => "0";
requires "File::Spec" => "0";
requires "FindBin" => "0";
requires "Getopt::Long" => "0";
requires "HTML::FromANSI" => "0";
requires "IO::Async::Handle" => "0";
requires "IO::Async::Loop" => "0";
requires "IO::Async::Routine" => "0";
requires "IO::Handle" => "0";
requires "JSON::MaybeXS" => "0";
requires "LWP::UserAgent" => "0";
requires "List::AllUtils" => "0";
requires "Log::Any" => "0";
requires "MIME::Base64" => "0";
requires "Markdown::Pod" => "0";
requires "Moo" => "0";
requires "Moo::Role" => "0";
requires "MooX::HandlesVia" => "0";
requires "MooX::Singleton" => "0";
requires "MooX::Types::MooseLike::Base" => "0";
requires "MooseX::HandlesConstructor" => "0";
requires "Net::Async::ZMQ" => "0.002";
requires "Net::Async::ZMQ::Socket" => "0";
requires "PPI::Document" => "0";
requires "Path::Class" => "0";
requires "Reply" => "0";
requires "Reply::Plugin" => "0";
requires "Scalar::Util" => "0";
requires "Try::Tiny" => "0";
requires "UUID::Tiny" => "0";
requires "ZMQ::FFI" => "1.18";
requires "autodie" => "0";
requires "base" => "0";
requires "constant" => "0";
requires "if" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "5.013002";
requires "strict" => "0";
requires "warnings" => "0";
suggests "Devel::REPL" => "0";

on 'test' => sub {
  requires "File::Which" => "0";
  requires "Test::More" => "0";
  requires "Test::Most" => "0";
  requires "perl" => "5.013002";
  requires "version" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::ShareDir::Install" => "0.06";
  requires "perl" => "5.013002";
};

on 'develop' => sub {
  requires "Data::Dumper" => "0";
  requires "Encode" => "0";
  requires "File::Temp" => "0";
  requires "Term::ANSIColor" => "2.01";
  requires "Test::More" => "0";
  requires "Test::Needs" => "0";
  requires "open" => "0";
};
