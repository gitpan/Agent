#!/usr/bin/perl

##
# test suite for Agent::Message
# -- Steve Purkis <spurkis@engsoc.carleton.ca>, January 19, 1998.
##

BEGIN {
	$| = 1;
	print "1..3\n";
	sub ok  { $i++; print "ok $i\n"; }
	sub nok { $i++; print "not ok $i\n"; }
}
END { print "Fatal: I couldn't load Agent!\n" unless $loaded; }

use Agent;
$loaded = 1;
ok;

($a = new Agent( File => 'test.pa' )) ? ok : nok;
$a->agent_main() ? ok : nok;

1;
