#!/usr/bin/perl

##
# Another Agent.pm alpha.
# Steve Purkis <spurkis@engsoc.carleton.ca>
# June 21, 1998.
##

package Agent;

use strict;
use UNIVERSAL;
use Class::Tom qw( cc repair );
use Agent::Message;
use Agent::Transport;

use vars qw($VERSION $SUBVERSION $Debug $hostname $ipaddr);

$VERSION    = '3.01';
$SUBVERSION = 7;
#$Debug = 1;

sub new {
	my ($class, %args) = @_;

	my $self = {};
	my ($tom, $code);

	if (exists($args{Stored})) {
		if (ref($args{Stored}) == "ARRAY") {
			my @code = delete($args{Stored});
			$code = join('', @code);
		} else {
			$code = delete($args{Stored});
		}
		print $code if ($Debug > 1);
		unless ( eval '$tom = repair($code)' ) {
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
		} elsif (my $name = delete($args{Name}) ) {
			$code = _find_agent($name);
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

		# now use Class::Tom::cc to stick the agent's code into a Tom container:
		# (note: we are only interested in the first container)
		unless ( ($tom) = cc($code) ) {
			warn "Agent: Class::Tom returned no container!" if $Debug;
			return;
		}
	}

	# now register the agent (%args passed incase 'Compartment' exists):
	$tom->register( %args );
	unless ( $self = $tom->get_object ) {
		# there was no object in the container, so create one:
		my $agentclass = $tom->class();

		# use a safe Compartment?
		if ( my $cpt = delete($args{'Safe'}) ) {
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
	print "self is: $self\n" if $Debug;

	# store the agent's class in the agent itself:
	$self->{Tom} = $tom;

	return $self;	# blessed into owning agent's class!
}

sub run {
	my ($self, %args) = @_;

	if (my $cpt = delete $args{Safe}) {
		$cpt->reval( '$self->agent_main( %args )' );
	} else {
		eval { $self->agent_main( %args ) };
	}
}


##
# Inherited methods for use by agent objects.
##

sub store {
	my $self = shift;

	# temporarily remove the server & the Tom container:
	my $server = delete( $self->{Server} );
	my $tom    = delete( $self->{Tom} );

	# insert the agent & store it:
	$tom->insert( $self );
	my $stored = $tom->store();

	# restore the server & Tom container:
	$self->{Server} = $server;
	$self->{Tom}    = $tom;

	return $stored;
}

sub identity {
	my $self = shift;

	# should really insert the current object into the Tom container...
	unless (defined($self->{ID})) {
		$self->{ID} = $self->{Tom}->checksum();
	}
 	return $self->{ID};
}


##
# Private subroutines
##

sub _find_agent {
	# searches @INC for "$name.pa".
	my ($name, @dirs) = @_;

	if ($name !~ /.*\.pa$/) { $name .= '.pa'; }	# add extension if needed
	push (@dirs, '.', @INC);			# search local dir & @INC too.
	# adapted from Class::Tom::insert:
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

=head1 NAME

Agent - the Transportable Agent Perl module

=head1 SYNOPSIS

  use Agent;

  my $a = new Agent( File => 'path_to_agent.pa', @args );

  $a->run();

=head1 DESCRIPTION

Agent is meant to be a multi-platform interface for writing and using
transportable agents.

=over 4

=item A Perl Agent

Is any chunk of Perl code that can accomplish some objective by
communicating with other agents, and examining any data it obtains.

A Perl Agent consists of a knowledge base (variables), a reasoning
procedure (code), and access to one or more languages coupled with
methods of communication.  The languages remain largely undefined, or
rather, user-defined; support for KQML/KIF is under development.

=item Developing An Agent

An agent is written as an inheriting sub-class of Agent.  Each agent
class is stored in a '.pa' file (I<perl agent>), and must contain an
C<agent_main()> method.  All agents are objects.  See the examples for
details.

=back

=head1 CONSTRUCTOR

=over 4

=item new( [%args] )

C<new> creates a new C<agent> object.  You can specify what type of agent to
create by passing one of these parameters:

    Stored - an Agent stored in a Tom object.
    File - references the file containing the Agent's class code.
    Name - given an agent's name, tells Agent to search for the corresponding '.pa' file and use that.
    Code - the agent's class code.

These are listed in order of precedence.  You can also pass a I<Safe> compartment
within which the agent will be registered.  Any additional arguments will be
passed to the agent itself.

=back

=head1 METHODS

=over 4

=item store ()

C<store> returns the agent object in stringified form, suitable
for network transfer.

=item run ()

C<run> executes the agent.  If the I<Safe> argument is passed,
C<run> tries to execute the agent in a C<Safe> compartment.

=item identity ()

C<identity> returns a unique agent identifier in stringified form.

=back

=head1 SEE ALSO

C<Agent::Message> and C<Agent::Transport> for developers.

=head1 AUTHOR

Steve Purkis <spurkis@engsoc.carleton.ca>

=head1 COPYRIGHT

Copyright (c) 1997 Steve Purkis. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=head1 THANKS

James Duncan for the C<Tom> module and many ideas; the Perl5-agents mailing
list.

=cut
