# Makefile.PL for The Transportable Object Model.

use ExtUtils::MakeMaker;

print STDERR "Checking for installed modules...\n";
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
		$m++;
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
	$m++;
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
	$m++;
} else {
	print STDERR "found.\n";
}

print STDERR "MIME::Base64...";
eval "
	package test;
	use MIME::Base64;
";
if ($@) {
	print STDERR "not found. [This may or may not cause trouble]\n";
	$m++;
} else {
	print STDERR "found.\n";
}

print "\n";


if ($m) {
	print "You seem to be missing $m modules.\n";
} else {
	print "All the requirements seem to be in place...\n";
}
print "\n";

WriteMakefile(
	NAME => 'Class::Tom',
	VERSION_FROM => 'Tom.pm',
	($] >= 5.005 ?
		(ABSTRACT => 'Allows for fully Transportable Perl Objects',
		 AUTHOR   => 'James Duncan <jduncan@hawk.igs.net>') : ()),
	'dist' => {COMPRESS=>'gzip',SUFFICE=>'gz'}
);

print <<HERE;

Now you'll need to run:
	make
	make test
	make install

HERE

1;

