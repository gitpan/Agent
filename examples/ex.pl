#!/usr/bin/perl

##
# DESCRIPTION: a perl script to execute example agents provided with this
#	package.
# AUTHOR: Steve Purkis <spurkis@engsoc.carleton.ca>
# DATE: May 3, 1998
##

use Agent;

$usage = <<USAGE;

Usage:
	perl ex.pl -n <AgentName> [-v] [ip.addr:port [ip.addr:port ...]]

  -v = verbose mode
  ip.addr:port = numeric ip address and optional port of remote agent
	to talk to.  Meaningless for Static agents.

USAGE

# if you want to see lots of meaningless output :-), uncomment these:
#$Agent::Transport::TCP::Debug = 1;
#$Agent::Debug = 1;

# first, set up the arguments:
my %args;
while ($arg = shift @ARGV) {
	if ($arg =~ /(\d+\.\d+\.\d+\.\d+)/i) {
		# safe to say it's an ip address
		push (@{$args{'Hosts'}}, $arg);
		# but HelloWorld agents can only handle 1 Host:
		$args{'Address'} = $args{'Host'} = $arg;
		# and Loop agents like 'Tell' better...
		$args{'Tell'} = $arg;
	} elsif ($arg =~ /-v/i) {
		$args{'verbose'} = 1;
	} elsif ($arg =~ /-n/i) {
		$args{'Name'} = shift @ARGV;
	}
}

unless ($args{'Name'}) { print $usage; exit 1;}

# then setup and execute the agent:
print "Starting $args{Name} agent...\n";
my $agent = new Agent( %args ) or die "couldn't create agent!";
$agent->run;
