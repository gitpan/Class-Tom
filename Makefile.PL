# Makefile.PL for The Transportable Object Model.

use ExtUtils::MakeMaker;

print <<HERE;

This is the MakeMaker program for the Transportable Object Model (TOM).
I'm now going to try to find out what modules you have, and which you don't
have, and which you might need - I might make a few suggestions, and take a 
few notes, but I should be all done fairly soon.
(press [ENTER] to continue)
HERE
my $realtmp = <STDIN>;

print STDERR "Checking for Required Modules\n";
print "\n";

print STDERR "Crypt::MD5.....";
eval "
	package test; 
	use Crypt::MD5;
";

if ($@) {
	eval " package test; use MD5 ";
	if (@$) {
		print STDERR "not found.\n";
		$md5 = 1;
	} else {
		print STDERR "found the new MD5.\n";
	}
} else {
	print STDERR "found.\n"; 
}

print STDERR "Data::Dumper...";
eval "
	package test; 
	use Data::Dumper;
";

if ($@) {
	print STDERR "not found.\n";
	$dd = 1;
} else {
	print STDERR "found.\n";
}

print STDERR "UNIVERSAL......";
eval "
	package test;
	use UNIVERSAL;
";
if ($@) {
	print STDERR "not found.\n";
	$uni = 1;
} else {
	print STDERR "found.\n";
}

print "\n";



if ($md5 || $dd) {
	print "You will need to download and install the following modules:\n";
	if ($md5) {
		print STDERR "\tMD5\n";
		print STDERR "\t This is a big problem, you'll have to download this before you can use Tom\n";
	}
	if ($dd) {
		print STDERR "\tData::Dumper\n";
		print STDERR "\t Tom absolutly must have this to work.  It'd be best if you got it.\n";
	}
	if ($uni) {
		print STDERR "\tUNIVERSAL\n";
		print STDERR "\t You'll need to download a copy of this\n";
	}
	if ($] > 5.004) {
		print "\n";
		print <<HERE;
You seem to have perl $], which means the CPAN module should be available 
to you.  You could use it to fetch the modules for you.  If there were any
100% must have modules missing, I'll die now, but you can run me again once
you have the requirements in place.  Otherwise I'll go ahead and build the
Makefile, and you'll be able to use Tom.
HERE
		unless ($ios) {
			print "\nDying....";
			exit(1);
		}
	}
} else {
	print "All the requirements seem to be in place...\n";
}
print "\n";

if ($^O =~ /Win32/) {
	print "You appear to be using Win32.\n";
	print "Configuring TOM for $^O.\n";
	$FROM = 'Class\Tom.pm';
} else {
	print "Hmmm, something other than Win32.  Good...\n";
	print "Configuring TOM for $^O.\n";
	$FROM = 'Class/Tom.pm';
}

print "\n";

WriteMakefile(
	NAME => 'Class::Tom',
	VERSION_FROM => $FROM,
	dist => {COMPRESS => 'gzip', SUFFIX => 'gz'}
);

print <<HERE;

I'm all done,  now you'll need to run:
	make
	make test
	make install

Thankyou....

HERE

1;

