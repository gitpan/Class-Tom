#!/usr/bin/perl

##
# Simple test suite for Class::Tom.
# James Duncan <jduncan@hawk.igs.net>
# Updated by Steve Purkis <spurkis@engsoc.carleton.ca>
##

use Data::Dumper;


BEGIN {
#	$DEBUG=1;	# uncomment for verbose output

	$| = 1;
	$max = 14;
	sub ok  { $passd++; $i++; print "ok", @_, "\n"; }
	sub nok { $faild++; $i++; print "failed", @_, "\n"; }
}
END {
	print "Fatal: I couldn't load Class:\:Tom!\n" unless $loaded;
	print "\nRan $i of $max possible tests.\n";
	print "\tpassed: $passd  failed: $faild\t", 100*$passd/$i, "\% OK\n\n";
}

print "load........";
eval { use Class::Tom qw ( repair cc ); };
$loaded = 1;
ok;

Class::Tom::debug(1) if $DEBUG;		# increase Tom's output

print "new.........";
my $obj = new Class::Tom Class => 'TestSuite';
(ref($obj) eq 'Class::Tom') ? ok : nok;

print "declare.....";
$obj->declare(Name => 'Useless', Code => '{ 1; }');
(exists $obj->{Useless}) ? ok : nok;

print "class.......";
($obj->class() eq 'TestSuite') ? ok : nok;

print "methods.....";
my @methods = $obj->methods();
($methods[0] eq 'Useless') ? ok : nok;

print "checksum....";
($obj->checksum() ne '') ? ok : nok;

{
	print "store.......";
	local $tmp = $obj->store();
	($tmp) ? ok : nok;

	print "repair......";
	local $newobj = repair($tmp);
	(ref($newobj) eq 'Class::Tom') ? ok : nok;
	print "Repaired object's class was [" . ref($newobj) . "].\n" if $DEBUG;

	print "insert......";
	local $me = bless {}, "TestSuite";
	($newobj->insert($me)) ? ok : nok;

	print "get_object..";
	local $em = $newobj->get_object();
	(ref($em) eq ref($me)) ? ok : nok;
}

print "register....";
$obj->register();
(TestSuite::Useless()) ? ok : nok;

print "cleanup.....";
$obj->cleanup();
print STDERR " [ Note: cleanup() is broken - don't use it! ] ";
(1) ? ok : nok;
# (! TestSuite::Useless()) ? ok : nok;	# this fails!!

print "cc..........";
my $testcc;
{
	open TST, 'test.tom';
	local $/ = undef;
	$testcc = <TST>;
	close TST;
}
($tom2) = cc($testcc);
(ref($tom2) eq 'Class::Tom') ? ok : nok;


# do everything over in Safe.

print "put_object..";
print STDERR " [ Not implemented yet ] ";
(1) ? ok : nok;



__END__

write tests for:
	new      - done
	class    - done
	methods  - done
	checksum - done
	insert   - done
	declare  - done
	register - done
	store    - done
	repair   - done
	get_object - done
	put_object - .
	cc       - .
	cleanup  - .
