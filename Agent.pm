#!/usr/bin/perl

##
#
# DESCRIPTION: Alpha release of a skeleton Agent.pm to test ideas.
# AUTHOR: Steve Purkis <spurkis@engsoc.carleton.ca>
# DATE: January 23, 1998.
#
##

package Agent;

use strict;
use UNIVERSAL;
use Tom qw( cc );
use Agent::TCPIP;
use Agent::Message;

use vars qw($VERSION $SUBVERSION $Debug $Hostname);

$VERSION    = '3.01';
$SUBVERSION = 2;
$Hostname   = '192.168.0.53';		# should be resolved externally!
#$Debug = 1;

sub new {
	# This lets you define a new agent object in one of two ways:
	#	1. With the Name, File, or Code, you can specify the agent's source code.
	#	   Agent will register this source with Tom, and return a new agent object.
	#	2. With a stored agent, Agent will unpack & register the agent's source,
	#	   and return the contained agent object.
	# You can also pass a Safe Compartment within which the agent will be registered.

	my ($class, %args) = @_;

        my $self = {};
        my $tom;

        if (my $code = delete($args{Stored})) {
                unless ($tom = repair($code)) {
			warn "Agent: discarded a corrupt agent!" if $Debug;
                        return ();
		}
	} else {
                if (my $file = delete( $args{File} )) {
                        unless (open(FILE, "$file")) {
                                warn "Agent: couldn't open '$file'! $!";
				return;
			}
			local $/ = undef;
			$code = <FILE>;
			close FILE;
                } elsif (delete($args{Name}) ) {
			$code = _find_agent($_);
                } elsif ( my @code = delete($args{Code}) ) {
                        $code = join('', @code);
		} else {
			warn "Agent: no valid arguments passed to new()!";
                        return ();
		}

		unless (defined($code)) {
			warn "Agent: source code could not be resolved!";
			return ();
		}

		# now use Tom::cc to stick the agent's code into a Tom container:
		# (note: we are only interested in the first container)
		unless ( ($tom) = cc($code) ) {
			warn "Agent: Tom returned no container!" if $Debug;
			return;
		}
	}

	# now register the agent (%args passed incase 'Compartment' exists):
	unless ( $self = $tom->register(%args) ) {
		# there was no object in the container, so create one:
                my $agentclass = $tom->class();

		# use a safe Compartment?
                if ( my $cpt = delete($args{'Compartment'}) ) {
                        unless ($cpt->reval('$self = new $agentclass (%args)')) {
				warn "Agent: unsafe agent code trapped!" if $Debug;
				return;
			}
                } else {
			$self = new $agentclass (%args);
                }

                # failing that, we'll just bless $self into the agent's class:
		if ( !$self ) {
			warn ("Agent: no constructor found in $agentclass!\n"
			       . ref($self)) if $Debug;
                        $self = {}; bless $self, $agentclass;
		}
	}

	# store the agent's class in the agent itself:
	$self->{Tom} = $tom;

	# give the agent the ability to communicate:
	unless ($self->{Server} = new Agent::TCPIP( Listen => 1 )) {
		warn "Agent: Couldn't establish a server!" if $Debug;
		return ();
	}

	return $self;	# blessed into owning agent's class!
}


##
#
# Inherited methods for use by agent objects.
#
##


# note: need something to resolve the agent's server port for use in Hostname.
sub Tell {
	my ($self, $msg) = @_;

	return () unless $msg;

	# set the 'From' field?
	if (!$msg->from()) {
		$msg->from($self->identity . '@' .
		           $self->hostname . ':' . $self->port);
	}

	# now open a connection to remote host & send the message:
	my ($id, $remote) = $msg->to;
	my $Client;
	unless ( $Client = new Agent::TCPIP(Address => "$remote") ) {
		warn "Agent: couldn't connect to $remote!" if $Debug;
		return ();
	}
	print STDERR "Sending message...\n" if $Debug;
	$Client->Send( $msg->compose() ) || return ();
	$Client->Close();
}

sub Listen {
	my ($self, @args) = @_;

        print "Agent: waiting for incoming message.\n" if $Debug;
	my $sock = $self->{Server};
	$sock->Open();
	$sock->Status( Dump => 1 ) if $Debug;

	# create a new message:
	my $packet =join('', $sock->Recv);
	my $msg = new Agent::Message( Packet => $packet ) or return ();
	$sock->Close();

	return $msg;
}


sub store {
        my $self = shift;

	# temporarily remove the server & the Tom container:
	my $server = delete( $self->{Server} );
	my $tom    = delete( $self->{Tom} );


	# insert the agent & store it:
	$tom->insert( $self);
	my $stored = $tom->store($self);

	# restore the server & Tom container:
	$self->{Server} = $server;
	$self->{Tom}    = $tom;

	return $stored;
}

sub run {
	## I haven't checked this since I changed everything... ##
	# Extracts an agent from the Tom container & executes the 'agent_main'
	# subroutine, if it can be found.  If 'Compartment' is specified, executes in
	# the Safe compartment provided.

	my ($self, %args) = @_;

        print STDERR "Agent::run called from: ", caller(), "\n" if $Debug;

	if ( my $cpt = delete $args{Compartment}) {
		# register the class in a safe compartment:
		unless ($self->register(Compartment => $cpt)) { return (); }

		# and call the agent_main method:
		$cpt->reval( '$self->agent_main()' );
	} else {
		# register the class:
		unless ($self->register()) { return (); }
		# and call the agent_main method:
		eval( '$self->agent_main()' );
	}
}

sub identity {
	my $self = shift;

	# should really insert the current object into the Tom container...
	unless (defined($self->{ID})) {
		$self->{ID} = $self->{Tom}->checksum();
	}
 	return $self->{ID};
}

sub hostname {
	my $self = shift;
	return $Hostname;
}

sub port {
	my $self = shift;

	unless (defined($self->{ServPort})) {
		my %status = $self->{Server}->Status();
		$self->{ServPort} = $status{servport};
	}
	return $self->{ServPort};
}


##
#
# Private subroutines
#
##

sub _find_agent {
	# searches @INC for "$name.pa".
	my ($name, @dirs) = @_;

	if ($name !~ /.*\.pa$/) { $name .= '.pa'; }	# add extension if needed
	push (@dirs, '.', @INC);			# search local dir & @INC too.
	# adapted from Tom::insert:
	foreach $_ (@dirs) {
		print "Agent: Looking in $_ for $name\n" if $Debug;
		if (-e "$_/$name") {
			print "Agent: Found $name!\n" if $Debug;
			unless ( open(PAFILE, "$_/$name") ) {
				warn "Agent: could not open $_/$name!";
				return;
			}
			local $/ = undef;
			my $code = <PAFILE>;
			close PAFILE;
			return $code;
		}
	}
	return;
}


1;

__END__

NOTES
-----

Right now, we'll grant each agent one port on the localhost.  This will
_have_ to change in the future, but for now it will get the job done.
(Maybe have a static message-server agent??)



=head1 NAME

Agent - Perl extension for transportable agents

=head1 SYNOPSIS

use Agent;
my $a = new Agent( File => 'path_to_agent.pa'
                   [, optional args to pass to agent] );
$a->agent_main();

=head1 DESCRIPTION

I'll get around to this sometime.

=head1 AUTHOR

Steve Purkis <spurkis@engsoc.carleton.ca>

=head1 SEE ALSO

Uhh..

=cut
