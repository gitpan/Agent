#!/bin/perl

## 
# Description: IO::Socket front end for creating tcp/ip servers and clients
# Author: Steve Purkis <spurkis@engsoc.carleton.ca>
# Date: December 3, 1997
##

package Agent::TCPIP;

use strict;
use UNIVERSAL;
use IO::Socket;
use vars qw( $VERSION $Debug );

$VERSION = 1.2;
#$Debug = 1;

sub new {
   # The following arguments apply:
   #	Listen => create a server [undef]
   #	Port => port to open socket on [24368]
   #	Address => address to open socket on/to [undef]
   #	Timeout => time to wait before giving up on _some_ socket operations [65]

	my ($class, %args) = @_;
	my $self = {};

	# number ports to try if we can't secure the default (server only):
	my $try = delete($args{Try}) || 5;

	# setup the common arguments (or their defaults):
	if ($args{Address} =~ /:/) {
		# split up address if port follows hostname ('foo.bar:80').
		# I know IO::Socket can handle this, but I'll do it anyways...
		($args{Address}, $args{Port}) = split( ':', $args{Address} );
	} else {
#		$args{Address} = $args{Address} || '127.0.0.1';
		$args{Port} = $args{Port} || 24368;
	}
	$args{Proto} = 'tcp';
	$args{Timeout} = $args{Timeout} || 65;
# 	$args{Reuse} = $args{Reuse} || 1;

	# note that $self->{Sock} will always point to the remote connection

	my ($type, $sock);
	if ($args{Listen}) {
		# setup a server
		$type = "Server";
		$args{LocalPort} = delete($args{Port});
	} else {
		# setup a client
		$self->{Client} = 1;
		$type = "Sock";
		$args{PeerPort} = delete($args{Port});
		$args{PeerAddr} = delete($args{Address});
	}

 	print STDERR "Agent::TCPIP::new called with:\n" if $Debug;
 	foreach (keys(%args)) { print STDERR "\t$_ => $args{$_}\n" if $Debug; }

	# try a bunch of times to secure a port...
	while ($try-- > 0) {
		print STDERR "Trying to capture $type port $args{LocalPort}\n" if $Debug;
		last if ($sock = new IO::Socket::INET( %args ));

		# if we're a server, raise the port number:
		unless ($self->{Client}) { $args{LocalPort}++; }
	}
	$self->{"$type"} = $sock;
	unless ($self->{"$type"}) {
		warn "Agent::TCPIP: Couldn't establish INET socket!";
		return ();
	}
	$self->{"$type"}->autoflush();

 	print STDERR "$type socket established: ", ref($sock), "\n" if $Debug;
	bless $self, $class;
}


sub Open {
   # listens for an incoming connection until Timeout is reached.
   # closes any previous connection.

	my ($self, %args) = @_;

	return () unless (defined($self->{Server}));
	print STDERR "Waiting for a remote connection...\n" if $Debug;
	my $remote = $self->{Server}->accept();
	$self->Close;					# kill any existing connection
	$self->{Sock} = $remote;
}

sub Close {
   # Disconnects from the remote host. Note: If you want to kill the Server *only*,
   #	and not any remote connections the server might have, call with 'Server => 1'.
   #	This might be usefull if a subprocess were to handle remote connections.
   #	Returns () if it couldn't close it for some reason (already closed?).

	my ($self, %args) = @_;

	my $sock;
	unless ($args{Server}) {
		$sock = delete($self->{Sock});		# close a remote connection
	} else {
		$sock = delete($self->{Server});	# kill the server itself
	}
	return () unless (defined($sock));		# do we have a socket to close?
	$sock->close();
	if (-e '/dev/null') {				# avoid lingering sockets [unix]
		open ($sock, '/dev/null');
	}
	return 1;
}

# sends data to the remote end (client only). If not connected, returns ().
sub Send {
	my ($self, @data) = @_;

	return () unless (defined($self->{Client}));	# are we a client?
	my $sock = $self->{Sock} or return ();		# are we connected?
	foreach (@data) { $sock->send( $_ ); }		# then send the data.
	1;
}

# recieves a line of data from remote (server only). If not connected, returns ().
sub Recv {
	my ($self, %args) = @_;

	return () unless (defined($self->{Server}));	# are we a server?
	my $sock = $self->{Sock} or return ();		# are we connected?

	if (wantarray) {
		my @data = $sock->getlines();		# read _all_ the lines.
		return @data;
	}
	my $data = $sock->getline();			# read only one line.
}

sub Timeout {
   # sets/gets a timeout value. Call with 'Time => nn' to set it, and with
   #	'Server => 1' to set a server's timeout value, otherwise it defaults to the
   #	remote connection, be it client or server.

	my ($self, %args) = @_;

	my $sock;
	if ($args{Server}) { $sock = $self->{Server}; }
	else               { $sock = $self->{Client}; }
	return () unless ($sock);
	defined($args{Time}) ? return $sock->Timeout( $args{Time} )
	                     : return $sock->Timeout;
}

sub Status {
   # returns the socket's status in a hash. Calling with 'Dump => 1' will dump the
   #	status to STDERR.

	my ($self, %args) = @_;

	my %status;
	if ($self->{Sock}) {
		# we're connected
		my $sock = $self->{Sock};		# $sock looks prettier
		$status{sockport} = $sock->sockport || '?';
		$status{sockhost} = $sock->sockhost || '?';
		$status{peerport} = $sock->peerport || '?';
		$status{peerhost} = $sock->peerhost || '?';
		$status{peertimeout} = $self->{Sock}->timeout || '?';
		if ($args{Dump}) { print STDERR "Client connection:\n" };
	} elsif ($self->{Server}) {
		# we're a server
		my $sock = $self->{Server};
		$status{servport} = $sock->sockport || '?';
		$status{servhost} = $sock->sockhost || '?';
		$status{servtimeout} = $sock->timeout || '?';
		if ($args{Dump}) { print STDERR "Server connection:\n" };
	} else {
		if ($args{Dump}) { print STDERR "No socket available!\n" };
	}
	if ($args{Dump}) {
		foreach (keys(%status)) { print STDERR "\t$_ => $status{$_}\n"; }
	}
	return %status;
}

sub DESTROY {
	my ($self) = @_;

	# avoid lingering sockets [unix]:
	$self->Close() if (defined($self->{Sock}));
	$self->Close( Server => 1 ) if (defined($self->{Server}));
}

1;	# for require's sake


__END__

=head1 NAME

Agent::TCPIP - A simplified interface to TCP/IP.

=head1 SYNOPSIS

 use Agent::TCPIP;
 $server = new Agent::TCPIP( Listen => 5 );
 $client = new Agent::TCPIP( Address => 'w.x.y.z' );

=head1 DESCRIPTION

TCPIP breaks TCP/IP communications down into two kinds of connection: A
I<Client> connection, and a I<Server> connection.  This greatly simplifies the
code needed to set up and use such a connection.  This module was designed 
with Agent.pm in mind.  This documentation is slightly out of date.

=head1 CONSTRUCTOR

=over 4


U<New> may be called in a number of ways,  depending on the type of 
connection you'd like to establish.  First you must choose between a server
or a client:  if a I<Listen> argument exists,  a server is created.  If you
are creating a client then you should decide on the I<Address> and I<Port> you
want to connect to. Or, if you're creating a server, you might want to choose
a I<Port> to set it up on.  In both cases you can specify the I<Timeout> value
(ie: time to wait before giving up on some socket ops).  More explicitly:

	A server:
	    Listen => $number_of_remote_connections
	    Port => $port_to_listen_on

	A client:
	    Address => 'remote.inet.address'
	    Port => $remote_port

If no socket could be made, a client will try to connect to the same address a
default of 5 times, whereas a server will try to secure one of 5 different
ports before giving up.  With that said, the arguments default to:

	Listen  => [undefined]
	Address => '127.0.0.1'
	Port    => 24368
	Timeout => 60
	Try     => 5

U<Note:> Any other arguments you pass will be tossed right to IO::Socket, so I
suggest you read that before playing.

=back

=head1 METHODS

Unless noted otherwise, all methods accept arguments in the form of a hash
array, and they all [should] return () when something doesn't work right (ie:
when trying to close a socket that is not open).

=over 4

=item $obj->Open( %args )

Serer only.  Waits for an incoming connection and opens it, unless Timeout is 
reached.  Closes any previous connection.

=item $obj->Close( %args )

Disconnects from the remote host unless I<Server> is defined, in which case it
kills the server socket U<only> (and not any remote connections the server might
have open at the time).  This might be usefull if a subprocess were to handle
remote connections.

=item $obj->Send( @data )

Client only.  Sends I<@data> to the remote host.

=item $obj->Recv( %args )

Server only.  Recieves a line of data from the remote host.

=item $obj->Timeout( %args )

Sets the timeout value if I<Time> is defined,  returns it otherwise.  If you
want to set the Server's timeout value, call this with 'I<Server> => 1', 
otherwise it will default to the remote connection (ie: not the listening
connection),  be it client or server.

=item $obj->Status( %args )

Returns the connection status in a hash. Calling with 'Dump => 1' will dump the
status to STDERR.  The status keys speak for themselves.

=back

=head1 NOTES

Servers commonly serve more than one connection at a time. For this reason,
some sort of forking routine will be needed under win32. The caller can worry
about this. (perhaps Process.pm?)

=head1 TODO

* Allow user to specify a 'remote' when Open is called - server will hangup
  on any incoming connections U<unless> they originate from said host.
* Support for 'port:address' in 'new'. Currently testing this.
* Write a 'client' and 'server' for @EXPORT_OK for lazy people (like me).
* Simulate two-way communications so the user doesn't have to [optional].

=head1 SEE ALSO

U<IO::Socket> and the U<socket(1)> man page for more technical information.

=head1 AUTHOR

Steve Purkis E<lt>F<spurkis@engsoc.carleton.ca>E<gt>

=head1 THANKS

Kudos to Graham Barr for an excellent job on IO::Socket (amongst others), and
James Duncan for Tom, and for getting me started on this binge ;-).

=cut
