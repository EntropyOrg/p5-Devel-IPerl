package Mojo::Reactor::Poll::LibZMQ3;
use Mojo::Base 'Mojo::Reactor::Poll';

$ENV{MOJO_REACTOR} ||= 'Mojo::Reactor::Poll::LibZMQ3';

use Carp 'croak';
use IO::Poll qw(POLLERR POLLHUP POLLIN POLLNVAL POLLOUT POLLPRI);
use List::Util 'min';
use Mojo::Util qw(md5_sum steady_time);
use Time::HiRes 'usleep';

use ZMQ::LibZMQ3;
use ZMQ::Constants ':all';

my $zmq = zmq_init();

sub io {
    my ( $self, $handle, $cb ) = @_;

    my $fd;
    eval { $fd = fileno $handle; };
    if ($@) {
        $self->{io}{$handle} = { socket => $handle, cb => $cb };
    }
    else {
        $self->{io}{$fd} = { cb => $cb };
    }
    return $self->watch( $handle, 1, 1 );
}

sub _zmqsocks {
    my ($self) = @_;
    return grep { $self->{io}{$_}{socket} } keys %{ $self->{io} };
}

sub _fds {
    my ($self) = @_;
    return grep { not $self->{io}{$_}{socket} } keys %{ $self->{io} };
}

sub one_tick {
    my $self = shift;

    # Just one tick
    local $self->{running} = 1 unless $self->{running};

    # Wait for one event
    my $i;
    until ( $i || !$self->{running} ) {

        # Stop automatically if there is nothing to watch
        return $self->stop
          unless keys %{ $self->{timers} } || keys %{ $self->{io} };

      # Calculate ideal timeout based on timers and round up to next millisecond
        my $min = min map { $_->{time} } values %{ $self->{timers} };
        my $timeout = defined $min ? $min - steady_time : 0.5;
        $timeout = $timeout <= 0 ? 0 : int( $timeout * 1000 ) + 1;

        my $timeout1 = $timeout / 2;
        my $timeout2 = $timeout - $timeout1;

        # I/O
        my @fds = $self->_fds;
        if (@fds) {
            my @poll =
              map { $_ => $self->{io}{$_}{mode} } @fds;

            # This may break in the future, but is worth it for performance
            if ( IO::Poll::_poll( $timeout1, @poll ) > 0 ) {
                while ( my ( $fd, $mode ) = splice @poll, 0, 2 ) {

                    if ( $mode &
                        ( POLLIN | POLLPRI | POLLNVAL | POLLHUP | POLLERR ) )
                    {
                        next unless my $io = $self->{io}{$fd};
                        ++$i and $self->_try( 'I/O watcher', $io->{cb}, 0 );
                    }
                    next
                      unless $mode & POLLOUT
                      && ( my $io = $self->{io}{$fd} );
                    ++$i and $self->_try( 'I/O watcher', $io->{cb}, 1 );
                }
            }
        }

        # Wait for timeout if poll can't be used
        elsif ($timeout1) { usleep( $timeout1 * 1000 ) }

        my @zmq_socks = $self->_zmqsocks();
        if (@zmq_socks) {
            my @poll = map {
                my $io         = $self->{io}{$_};
                my $socket     = $io->{socket};
                my $mode       = $io->{mode};
                my $wrapped_cb = sub {
                    my $try_flag =
                      ( $mode & ( ZMQ_POLLIN | ZMQ_POLLERR ) ) ? 0 : 1;
                    $self->_try( 'I/O watcher', $io->{cb}, $try_flag );
                };

                {
                    socket   => $socket,
                    events   => $mode,
                    callback => $wrapped_cb,
                };
            } @zmq_socks;

            zmq_poll( \@poll, $timeout2 );
        }

        # Wait for timeout if poll can't be used
        elsif ($timeout2) { usleep( $timeout2 * 1000 ) }

        # Timers (time should not change in between timers)
        my $now = steady_time;
        for my $id ( keys %{ $self->{timers} } ) {
            next unless my $t = $self->{timers}{$id};
            next unless $t->{time} <= $now;

            # Recurring timer
            if ( exists $t->{recurring} ) {
                $t->{time} = $now + $t->{recurring};
            }

            # Normal timer
            else { $self->remove($id) }

            ++$i and $self->_try( 'Timer', $t->{cb} ) if $t->{cb};
        }
    }
}

sub remove {
    my ( $self, $remove ) = @_;
    return !!delete $self->{timers}{$remove} unless ref $remove;

    my $fd_or_zmqsock;
    eval { $fd_or_zmqsock = fileno $remove; };
    if ($@) {
        $fd_or_zmqsock = $remove;
    }
    return !!delete $self->{io}{$remove};
}

sub watch {
    my ( $self, $handle, $read, $write ) = @_;

    my $fd_or_zmqsock;
    eval { $fd_or_zmqsock = fileno $handle; };
    if ($@) {
        $fd_or_zmqsock = $handle;
    }
    croak 'I/O watcher not active'
      unless my $io = $self->{io}{$fd_or_zmqsock};

    $io->{mode} = 0;

    if ( $io->{socket} ) {
        $io->{mode} |= POLLIN | POLLPRI if $read;
        $io->{mode} |= POLLOUT if $write;
    }
    else {
        $io->{mode} |= ZMQ_POLLIN  if $read;
        $io->{mode} |= ZMQ_POLLOUT if $write;
    }

    return $self;
}

1;

=pod

=head1 NAME
 
Mojo::Reactor::Poll::LibZMQ3 - Combined poll/zmq_poll backend for Mojo::Reactor
 
=head1 SYNOPSIS
 
  use Mojo::Reactor::Poll::LibZMQ3;
 
  # Watch if handle becomes readable or writable
  my $reactor = Mojo::Reactor::Poll::LibZMQ3->new;
  $reactor->io($first => sub {
    my ($reactor, $writable) = @_;
    say $writable ? 'First handle is writable' : 'First handle is readable';
  });

  # Change to watching only if handle becomes writable
  $reactor->watch($first, 0, 1);

  # Make a zmq socket and watch if it becomes readable
  my $second = zmq_socket($zmq, $type);
  $reactor->io($second => sub {
    my ($reactor, $writable) = @_;
    say $writable ? 'Second handle is writable' : 'Second handle is readable';
  })->watch($second, 1, 0);
 
  # Start reactor if necessary
  $reactor->start unless $reactor->is_running;
 
  # Or in an application using Mojo::IOLoop
  use Mojo::IOLoop;
 
  # Or in a Mojolicious application
  $ MOJO_REACTOR=Mojo::Reactor::Poll::LibZMQ3 hypnotoad script/myapp
 
=head1 DESCRIPTION
 
L<Mojo::Reactor::Poll::LibZMQ3> is an event reactor for L<Mojo::IOLoop> that
uses both IO::Poll and zmq_poll of L<ZMQ::LibZMQ3>. The usage is exactly the
same as other L<Mojo::Reactor> implementations such as L<Mojo::Reactor::Poll>.
L<Mojo::Reactor::Poll::LibZMQ3> will be used as the default backend for
L<Mojo::IOLoop> if it is loaded before L<Mojo::IOLoop> or any module using
the loop. However, when invoking a L<Mojolicious> application through
L<morbo> or L<hypnotoad>, the reactor must be set as the default by setting
the C<MOJO_REACTOR> environment variable to C<Mojo::Reactor::UV>.

The goal of this module is to provide a portable solution to integrate
L<ZMQ::LibZMQ3> into an event loop. On Windows a ZMQ socket object obtained
from L<ZMQ::LibZMQ3> does not support C<fileno>.
 
=head1 EVENTS
 
L<Mojo::Reactor::Poll::LibZMQ3> inherits all events from
L<Mojo::Reactor::Poll>.
 
=head1 METHODS
 
L<Mojo::Reactor::Poll::LibZMQ3> inherits all methods from
L<Mojo::Reactor::Poll> and overrides the following ones.
 
=head2 io
 
  $reactor = $reactor->io($handle => sub {...});
  $reactor = $reactor->io($zmqsock => sub {...});
 
Watch handle for I/O events, invoking the callback whenever handle becomes
readable or writable.

Besides what's supported by L<Mojo::Reactor::POll>, it also supports
L<ZMQ::LibZMQ3> socket objects.
 
=head2 new
 
  my $reactor = Mojo::Reactor::Poll::LibZMQ3->new;
 
Construct a new L<Mojo::Reactor::Poll::LibZMQ3> object.
 
=head2 one_tick
 
  $reactor->one_tick;
 
Run reactor until an event occurs or no events are being watched anymore.

This method does two polls sequentially. Firstly a poll as supported by
L<Mojo::Reactor::Poll> for the normal handles, and then a call to the
C<zmq_poll> method of L<ZMQ::LibZMQ3> for the zmq sockets.
 
=head2 remove
 
  my $bool = $reactor->remove($handle);
  my $bool = $reactor->remove($id);
  my $bool = $reactor->remove($zmqsock);
 
Remove handle or timer.

Besides what's supported by L<Mojo::Reactor::POll>, it also supports
L<ZMQ::LibZMQ3> socket objects.

=head2 watch
 
  $reactor = $reactor->watch($handle, $readable, $writable);
  $reactor = $reactor->watch($zmqsock, $readable, $writable);

Change I/O events to watch handle for with true and false values. Note that
this method requires an active I/O watcher.

Besides what's supported by L<Mojo::Reactor::POll>, it also supports
L<ZMQ::LibZMQ3> socket objects.
 
=head1 AUTHOR
 
Stephan Loyd, C<stephanloyd9@gmail.org>
 
=head1 COPYRIGHT AND LICENSE
 
Copyright 2017, Stephan Loyd.
 
This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
 
=head1 SEE ALSO
 
L<Mojo::IOLoop>, L<Mojo::Reactor::Poll>, L<ZMQ::LibZMQ3>
