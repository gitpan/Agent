#!/usr/bin/perl

##
# TCP[/IP] transport subclass for Agent.pm.
# By Steve Purkis
# June 18, 1998
##

package Agent::Transport::TCP;

use IO::Socket;

@ISA = qw( Agent::Transport );

##
# Non-OO Stuff
##

sub send {
	my (%args) = @_;
	my $addr;

	unless ($addr = $args{Address}) {
		$! = "No tranpsport address defined!";
		return;
	}
	my @msg = @{$args{Message}};

	# open a new socket & send the data
	my $con = new IO::Socket::INET(
		Proto => 'tcp',
		Timeout => 1,
                PeerAddr => $addr,
                Reuse => 1
	) or return ();	# use IO::Socket's $!

	for( @msg ) { $con->send( $_ ) or return (); }
	$con->close();
	undef $con;	# paranoia
	1;
}

sub valid_address {
	return ($_[0] =~ /(^(\d{1,3}\.){3}\d{1,3})|(^(\w+\.)*\w+)\:\d+$/);
}

##
# OO Stuff
##

sub new {
	my ($class, %args) = @_;
	my $self = {};
	my ($addr, $port);

	$args{Address} = '127.0.0.1:24368' unless exists($args{Address});
	unless (valid_address($args{Address})) {
		$! = "Invalid transport address!";
		return;
	}
	($addr, $port) = split(/:/, $args{Address});

	# open a new server socket:
	while (1) {
		last if $self->{Server} = new IO::Socket::INET(
			Proto => 'tcp',
			Listen => 1,
			LocalAddr => $addr . ':' . $port,
			Reuse => 1
		);
		print "Oops: $!\n" if ($Debug && $!);
		$port++;
	}

	$self->{Server}->autoflush();
	bless $self, $class;
}

sub recv {
	my ($self, %args) =  @_;

	$self->{Server}->timeout($args{Timeout}) if $args{Timeout};
	my $remote = $self->{Server}->accept() or return ();
	print $remote->peerhost . ':' . $remote->peerport, "\n" if $Debug;
	return $remote->getlines;
}

sub address {
	my ($self, %args) =  @_;
	# use socket calls to obtain info about our server socket
	return ($self->{Server}->sockhost . ':' . $self->{Server}->sockport);
}

sub aliases {
	my ($self, %args) =  @_;

	# use socket calls to get all hostnames for our server
	# cheat for now:
	return [ $self->address ];
}

sub transport {
	my ($self, %args) =  @_;
	return 'TCP';
}

1;


__END__

=head1 NAME

Agent::Transport - the Transportable Agent Perl module

=head1 SYNOPSIS

  Don't use this package directly!

=head1 DESCRIPTION

This package provides an interface to the TCP[/IP] transport medium for
agents.

=head1 CONSTRUCTOR

=over 4

=item new( %args )

If C<new> is not passed an I<Address>, it assumes '127.0.0.1:24368'.  It
will try to capture the first free port it finds, regardless of the address.
All other operation should be straightforward.

=back

=head1 ADDRESS FORMAT

=over 3

=item This package groks the following standard tcpip formats:

 aaa.bbb.ccc.ddd:port
 host.domain:port

=back

=head1 HACKS

=over 4

=item $self->alias()

Returns $self->address only. (should really do hostname lookups et. al.)

=back

=head1 SEE ALSO

C<Agent>, C<Agent::Message>, C<Agent::Transport::*>, and the example agents.

=head1 AUTHOR

Steve Purkis E<lt>F<spurkis@engsoc.carleton.ca>E<gt>

=head1 COPYRIGHT

Copyright (c) 1998 Steve Purkis. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=head1 THANKS

The perl5-agents mailing list.

=cut
