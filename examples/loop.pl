#!/usr/bin/perl

use Agent;

$Agent::TCPIP::Debug = 1;
$Agent::Debug = 1;

# first, set up the arguments:
my %args;
$args{File} = 'loop.pa';
foreach $arg (@ARGV) {
	if ($arg =~ /(\d+\.\d+\.\d+\.\d+)/i) {
		$args{'tell'} = $arg;	# safe to say it's an ip address
	} elsif ($arg =~ /-v/i) {
		$args{'verbose'} = 1;
	}
}

# then setup and execute the agent:
my $agent = new Agent( %args ) or die "couldn't create agent!";
$agent->agent_main();
