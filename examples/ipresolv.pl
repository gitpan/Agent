#!/usr/bin/perl

##
#
# Quick-and-dirty script to resolve the IP Address of a Win95 machine.
# Run with '-v' to get some verbosity, or '-q' to get the ip only.
# -- Steve Purkis <spurkis@engsoc.carleton.ca>, January 16, 1998
#
##

if ($^O !~ /Win32/) { print STDERR "not a win95 machine!\n"; exit 0; }

foreach (@ARGV) {
        if ($_ =~ /\-v/ig) { $v = 1; }  # set verbose mode
        if ($_ =~ /\-q/ig) { $q = 1; }  # set quiet mode
}
if ($q && $v) { undef $v; }             # assume quiet over verbose.

$file = 'c:\windows\system.dat';        # file IP Address is stored in

print "opening $file..." if $v;
open (SYS, $file) or die "\nFatal: couldn't open $file! $!";
binmode SYS;            # loathe win95

print "\nsearching for a valid ip address...\n" if $v;
foreach $_ (<SYS>) {
        next if ( $_ !~ /IPAddress(\d+\.\d+\.\d+\.\d+)/ );
        # => ip address of localhost is in $1...
        $inet = $1;
        print "found an ip entry: $inet\n" if $v;
        last unless ($inet =~ /0.0.0.0/);
        undef $inet;
        print "invalid. continuing search...\n" if $v;
}
close SYS;

if ($q) { print $inet; }
else {
        print $inet ? "your ip address is: $inet\n"
                    : "i was unable to resolve your ip address!";
}
