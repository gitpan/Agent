#!/usr/bin/perl

##
# Transport class stub for Agent.pm messages.
# Steve Purkis
# June 21, 1998
##

package Agent::Transport;
#$Debug = 1;


##
# Autoloaded, non-OO Stuff
##

sub AUTOLOAD {
	my (%args) = @_;
	my $med = delete $args{Medium} or return;
	$AUTOLOAD =~ /^((\w+\:\:)+)(\w+)$/;
	my $pkg = $1 . $med;
	my $sub = "$pkg\:\:$+";

	print "Autoloading $sub...\n" if $Debug;

	unless (defined &$sub) {
		# try Autoloading it...
		unless (eval "require $pkg") {
			warn "Couldn't autoload $pkg!\n";
			return;
		}
		unless (defined &$sub) {
			warn "Call to non-existing sub: $sub!\n";
			return;
		}
	}
	goto &$sub;
}


##
# OO Stuff
##

sub new {
	my ($class, %args) = @_;
	my $med = delete $args{Medium} or return;
	my $pkg = "$class\:\:$med";
	my $sub = "$pkg\:\:new";

	unless (defined &$sub) {
		unless (eval "require $pkg") {
			warn "Couldn't Autoload $pkg!\n";
			return;
		}
	}
	return eval "new $pkg( \%args )";
}

1;


__END__

=head1 NAME

Agent::Transport - the Transportable Agent Perl module

=head1 SYNOPSIS

  use Agent;

  my $t = new Agent::Transport(
	Medium => $name,
	Address => $addr
	...
  );
  ...
  my $data = $t->recv( [%args] );

=head1 DESCRIPTION

This package provides a standard interface to different transport mediums.
C<Agent::Transport> does not contain any transport code itself; it merely
gets subclasses to do all the work.

=head1 CONSTRUCTOR

=over 4

=item new( %args )

C<new> must be passed a I<Medium> argument.  I<Address> is a proposed
standard for passing transport addresses.  Any other arguments, both
optional and requirerd, will be documented in the corresponding subclass
(ie: Agent::Transport::TCP).

=back

=head1 STANDARD METHODS

=over 4

=item $t->recv()

C<recv> attempts to retrieve a message (from said address, over said
transport medium).  Returns a list of data, or nothing if unsuccessful.

=item $t->transport()

Returns the transport medium over which the object communicates.

=item $t->address()

Returns the primary address at which the object can be reached.

=item $t->aliases()

Returns a list of addresses at which the object can be reached.

=back

=head1 STANDARD SUBROUTINES

=over 4

=item send( %args )

C<send> too must be passed I<Medium>.  It also requires an I<Address>
(scalar), and a I<Message> (anonymous list / reference).

=item valid_address( %args )

This checks to see if the I<Address> provided is valid within the I<Medium>
specified.  Returns the address if so, and nothing otherwise.

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
