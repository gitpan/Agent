#!/usr/bin/perl

use ExtUtils::MakeMaker;

##
# MakeMaker script for Agent.pm
# This script checks module dependancies, and generates a Makefile
# It also installs Agent on a Win32 system. What fun.
# --Steve Purkis <spurkis@engsoc.carleton.ca>, Feb. 8, 1998.
##

select(STDERR);
$| = 1;
my $ans = Y;

if ($^O =~ /Win32/) {
	print <<DONE;

You seem to be running Win32.

	I can install Agent directly [probably what you want], or I can
	build a Makefile, in which case, I can only assume you've read
	the 'INSTALL' file, and really know what you're doing.

DONE

	$ans = question ($ans, "Do you want me to install Agent directly?");
	if ($ans eq "Y") { $install = 1; }
} else { print "\nYou don't seem to be running Win32... good.\n"; }

print "\nChecking module dependancies:\n";

my %missing;
print "\tIO::Socket..... ";
eval " use IO::Socket; ";
if ($@) {
	print "not ";
	$missing{'IO::Socket'} = 1;
}
print "ok.\n";

print "\tClass::Tom..... ";
eval " use Class::Tom; ";
if ($@) {
	print "not ";
	$missing{'Class::Tom'} = 1;
}
print "ok.\n";

if (%missing) {
	print "\nI can't find the following modules on your system:\n";
	foreach (keys(%missing)) {
		print "\t$_\n";
	}
	print <<DONE;

These modules are required by Agent. You should make sure they're installed
and run this script again.

Press <enter>...
DONE
	my $dummy = <STDIN>;
	exit 0;
} else { print "You seem to have all the required modules.\n"; }

# are we installing on a Win32 machine?
if ($install) {
	win_install();
	print "Press <enter>..."; my $dummy = <STDIN>;
	exit;
}

# Finally, we create the Makefile.

WriteMakefile(
	'NAME'	=> 'Agent',
	'VERSION_FROM' => 'Agent.pm'
);

print <<DONE;
Done.

To finish installing Agent you should run:

	make
	make test
	make install

DONE


# this is an installation script for Win32 systems:
sub win_install {
	$perldir = 'c:\\perl';  # where Perl was installed
	$agentdir = '.';	# where Agent was unpacked
	$ans = 'Y';	     # default answer (ie: user presses <enter>)

	@files = ('Agent.pm', 'Agent\\Transport.pm',
	          'Agent\\Transport\\TCP.pm', 'Agent\\Message.pm');

	while (!( -e $files[0] )) {
		print "I couldn't find ", $files[0],
		      ". Where did you unzip Agent? ";
		$agentdir = <STDIN>; chop $agentdir;
	}
	print "Agent found in '$agentdir'\n";

	while (!( -e $perldir )) {
		print "I can't seem to find perl in $perldir.\n";
		print "Where have you installed perl? ";
		$perldir = <STDIN>; chop $perldir;
		if ( -e $perldir ) { last; }
	}
	print "Perl found in '$perldir'\n";

	$perldir .= '\\lib\\site';
	while (!( -e $perldir )) {
		print "Whoa! '$perldir' doesn't seem to exist...\n";
		print "Where should I install Agent? ";
		$perldir = <STDIN>; chop $perldir;
	}
	print "Installing Agent to '$perldir'\n";

	my $newdir = "$perldir\\Agent";
	unless ( -e $newdir ) {
		$! = '';
		print "creating $newdir\n";
		mkdir( $newdir, '' ) or die "Fatal: couldn't create $newdir!";
	} else { print "Detected a previous installation of Agent.\n"; }

	my $newdir = "$perldir\\Agent\\Transport";
	unless ( -e $newdir ) {
		$! = '';
		print "creating $newdir\n";
		mkdir( $newdir, '' ) or die "Fatal: couldn't create $newdir!";
	} else { print "Detected a previous installation of Agent.\n"; }

	foreach (@files) {
		my ($from, $to) = ($agentdir . '\\' . $_, $perldir . '\\' . $_);
		cp ($from, $to);
	}

	print "running test scripts...\n";
	system("perl $agentdir\\test.pl");

	print "\nDone.\n";
}

sub question {  # handles yes/no question; (default, 'message')
	my ($default) = shift;

	print @_, " [$default] ";
	my $in = <STDIN>;
	return ('Y') if ($in =~ /y/i);
	return ('N') if ($in =~ /n/i);
	return $default;    # default
}



sub cp {				# copies from file xxx to file yyy
	my ($from, $to) = @_;

	if (-e $to) {
		$ans = question ($ans, "overwrite '$to'?");
		return if ($ans eq 'N');
	}

	print "copying: $from -> $to\n";
	unless (open (FROM, $from)) {
		warn "Warning: couldn't open $from!\n";
		return ();
	}
	unless (open (TO, "> $to")) {
		warn "Warning: couldn't open $to!\n";
		return ();
	}

	foreach (<FROM>) { print TO $_; }
	close FROM, TO;
}


1;

