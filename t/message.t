#!/usr/bin/perl

##
# test suite for Agent::Message
# -- Steve Purkis <spurkis@engsoc.carleton.ca>, January 19, 1998.
##

BEGIN {
	$| = 1;
	print "1..11\n";
	sub ok  { $i++; print "ok $i\n"; }
	sub nok { $i++; print "not ok $i\n"; }
}
END { print "Fatal: I couldn't load Agent\:\:Message!\n" unless $loaded; }

use Agent::Message qw( unpack_msg );
$loaded = 1;
ok;

my $me = 'me@my.org';
my $you = 'you@your.com';
my $body = "foo bar\nbaz";

my $msg = new Agent::Message(	To   => $me,
				From => $you,
				Body => $body);

($msg->to eq $me) ? &ok : nok;
($msg->from eq $you) ? &ok : nok;

my ($a, $b) = $msg->to;
my ($c, $d) = split('@', $me);
($a eq $c) ? ok : nok;
($b eq $d) ? ok : nok;

($a, $b) = $msg->from;
($c, $d) = split('@', $you);
($a eq $c) ? ok : nok;
($b eq $d) ? ok : nok;

($msg->body eq $body) ? ok : nok;
($msg->delimeter eq $Agent::Message::Default_Delimeter) ? ok : nok;
($msg->version eq "$Agent::Message::VERSION.$Agent::Message::SUBVERSION") ? ok : nok;

@packet = $msg->compose();
my $newmsg = Agent::Message::unpack_msg( @packet );
my $new2msg = new Agent::Message( Packet => join('', @packet) );
@m1 = $newmsg->compose();
@m2 = $new2msg->compose();

(@m2 eq @m1) ? ok : nok;
