#!/usr/bin/perl


##
# A standard message class to ease inter-agent communications.
# --Steve Purkis <spurkis@engsoc.carleton.ca>, January 19, 1998.
##

package Agent::Message;
use strict;
use vars qw( @ISA @EXPORT_OK $VERSION $SUBVERSION $Debug $Default_Delimeter );

@ISA = qw( Exporter );
@EXPORT_OK = qw( unpack_msg );
#$Debug = 1;
$VERSION = 1.01;	# these have nothing to do with Agent
$SUBVERSION = 'a';
$Default_Delimeter = "- Agent.pm $VERSION ($SUBVERSION) -\n";


sub new {
	my ($class, %args)  = @_;
	my $self = {};

	if (exists($args{Packet})) {
		$self = unpack_msg(delete $args{Packet});
		return $self;
	} else {
		$self->{Body} = delete $args{Body};
		$self->{From} = delete $args{From};
		$self->{To} = delete $args{To};
		$self->{Delimeter} = delete($args{Delimeter}) || $Default_Delimeter;
	}
	bless $self, $class;
}

# set/get the message body
sub body {
	my $self = shift;
	$self->{Body} = join('', @_) if (@_);
	wantarray ? return $self->{Body} : return join('', $self->{Body});
}

# set/get the to address [array format: (user, host:port) for return only!]
sub to {
	my $self = shift;
	$self->{To} = shift if @_;
	if (wantarray) {
		$self->{To} =~ /\@/ ? return split('@', $self->{To})
		                    : return ('', $self->{To});
	}
	return $self->{To};
}

# set/get the from address [array format: (user, host:port) for return only!]
sub from {
	my $self = shift;
	$self->{From} = shift if @_;
	if (wantarray) {
		$self->{From} =~ /\@/ ? return split('@', $self->{From})
		                      : return ('', $self->{From});
	}
	return $self->{From};
}

# set/get the message delimeters
sub delimeter {
	my $self = shift;
	$self->{Delimeter} = shift if (@_);
	return $self->{Delimeter};
}

# extracts the version & subversion from the delimeters
sub version {
	my $self = shift;

	if ($self->{Delimeter} =~ /Agent\.pm (\d+\.\d+) \((\w+)\)/g) {
		wantarray ? return ($1, $2) : return join('.', $1, $2);
	}
	return ();	# => unrecognized format
}

# composes the message into a transmitable packet
sub compose {
	my $self = shift;

	my @mesg;
	push (@mesg, $self->{Delimeter},
	             "TO: $self->{To}\n",
	             "FROM: $self->{From}\n",
	             "$self->{Body}\n",
	             $self->{Delimeter});
	print STDERR ("Composed packet:\n", @mesg, "\n") if $Debug;
	wantarray ? return @mesg : return join('', @mesg);
}

# given a chunk of data, unpack a message in (the above) standard format.
sub unpack_msg {
	my (@msg) = @_;
	my $self = {};

	# first make sure it's long enough (>=5 lines long)
	if ($#msg < 4) {
		my @tmp;
		foreach (@msg) {
			foreach (split(/\n/, $_)) { push (@tmp, "$_\n"); }
		}
		if ($#tmp < 4) {
			warn "Message is too short!\n";
			return ();
		}
		@msg = @tmp;
	}

	# unwrap the packet into its components:
	if (($self->{Delimeter} = pop(@msg)) ne shift(@msg)) {
		warn "Packet delimiters don't match!\n" if $Debug;
		return ();
	}

	$self->{To} = shift(@msg);		# get the 'TO' field
	if ($self->{To} =~ /^TO\: (.+)$/g) {
		$self->{To} = $1;		# and extract the sender info
	} else {
		warn "No 'TO:' field in message!\n" if $Debug;
		unshift (@msg, $self->{To});	# keep going..
	}

	$self->{From} = shift(@msg);		# get the 'FROM' field
	if ($self->{From} =~ /^FROM\: (.+)$/i) {
		$self->{From} = $1;		# and extract the reciever's info
	} else {
		warn "No 'FROM:' field in message!\n" if $Debug;
		unshift (@msg, $self->{From});	# keep going..
	}

	unless ($self->{Body}=join('', @msg)) {	# the remainder is the message body
		warn "No message body!\n";
	}

	bless $self, 'Agent::Message';
}


1;

__END__

	      A sample Agent message:
	+--------------------------------+
	|            Header              |
	|      [version info, etc.]      |    Delimeter	(1 line)
	+--------------------------------+
	|    FROM: [id]@[address:port]   |
	|      TO: [id]@[address:port]   |    MesgInfo	(2 lines)
	+--------------------------------+
	|        [Message Body]          |    Mesg	(n lines)
	+--------------------------------+
	|            Footer              |
	|   [exactly same as header]     |    Delimeter	(1 line)
	+--------------------------------+


