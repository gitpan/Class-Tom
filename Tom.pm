package Class::Tom;

require 5.004;  	

use Exporter;
@ISA = qw ( Exporter );
@EXPORT_OK = qw ( repair cc );

use Carp;

use Data::Dumper;
use UNIVERSAL;

$VERSION = '2.04';
$SUBVERSION = 'AlphaFive';
$PATCHLEVEL = '00';		# spurkis@engsoc.carleton.ca

$Class::Tom::debug = 0;

BEGIN {	
	$^W = 0;
	eval "use Crypt::MD5";
	if ($@) {
		eval "use MD5";
		if ($@) {
			print "You have neither MD5 nor Crypt::MD5 installed.";
			print "\nMakeMaker should have trapped this...";
			print "\nThis is what is a problem.  I'm going to die\n";
			$Class::Tom::die = 1;
		}
	}
	eval "use MIME::Base64";
	if ($@) {
		$Class::Tom::base64 = 'False';
		print "Skipping Base64 Encoding support (install MIME::Base64\n";
	} else {
		$Class::Tom::base64 = 'True';
	}
}


if ($Class::Tom::die) {
	exit(1);
}

sub domagic {
	my $self = shift;
	my $fnc  = shift;
	eval "package $self->{Class}; sub $self->{Class}::$fnc $self->{$fnc}";
	if ($@) {
		return 0;
	} else { return 1 }
}

sub new {
	my ($class, %args) = @_;
	my $self = {};

	$self->{Class} = $args{Class};
	$self->{FunctionCnt} = 0;	# keep a count of the functions registered in this package.
	$self->{Functions} = ();	# array of functions
	bless $self, $class;
}

sub declare {
	my $self = shift;
	my %args = @_;
	my $cpt  = $args{Compartment};	# use Safe Compartment?
	print "Declaring $self->{Class}::$args{Name}\n" if $Class::Tom::debug;
	$self->{$args{Name}} = $args{Code};
	$self->{Functions}[$self->{FunctionCnt}] = $args{Name};
	($cpt)
	   ? $cpt->reval("package $self->{Class}; sub $self->{Class}::$args{Name} $args{Code}")
	   : eval "package $self->{Class}; sub $self->{Class}::$args{Name} $args{Code}";
	$self->{FunctionCnt}++;
}

sub class {
	my $self = shift;
	return $self->{Class}
}

sub methods {
	my $self = shift;
	return @{$self->{Functions}};
}

sub get_object {
	my $self = shift;
	my $index= shift;

	unless ($#{$self->{Object}} == -1) {
		return eval ${$self->{Object}}[$index];
	}
	return eval $self->{Object};
}

# puts contained object into a safe compartment
# <spurkis@engsoc.carleton.ca>
sub put_object {
	my $self = shift;
	my $cpt = shift;
	my $index = shift || 0;
	unless (ref($cpt) eq 'Safe') {
		warn "Error: No safe Compartment passed to put_object()!\n";
		return;
	}
	my $obj = ($#{$self->{Object}} == -1)
	   ? $self->{Object}
	   : ${$self->{Object}}[$index];
	$cpt->reval($obj);
	# extract the variable name used:
	my ($varname) = split(/\s*=/, $obj);
	return $varname;	# returns sv_null if no object in container
}

sub main ($$) {
	my $self = shift;
	$self->{'main'} = shift;
}

sub insert {
	my $self = shift;	# Class::Tom object.
	my $obj = shift;	# object to insert.

	# check what exactly the object is before inserting it.
	unless ($obj->isa($self->{Class}) || !$self->{Class}) {
		croak("ERROR: object must be blessed into contained class");
	}

	if (!$self->{Class}) {
		$self->{Class} = ref($obj);
	}
	
	if ($self->{FunctionCnt} == 0) {
		my $module = ref($obj);
		print STDERR "Attempting to compile Class::Tom Class $module\n" if $Class::Tom::debug;
		foreach $_ (@INC) {
			$module =~ s/::/\//g;
			print "Looking in $_ for $module.pm\n" if $Class::Tom::debug;
			if (-e "$_/$module.pm") {
				print "Found $module.pm!\n" if $Class::Tom::debug;
				open(FILE, "$_/$module.pm") || 
					warn "cannot open $_/$module.pm";
				local $/ = undef;
				my $data = <FILE>;
				close FILE;
				my ($object, @data) = cc($data);
				unless (ref($object) eq ref($self)) {
					print "Object is a ", ref($object),"\n";
				}
				$object->insert($obj);
				return $object;
			}
		}
	}
	# the only line of the sub that does anything :-)
	if ($#{$self->{Object}} == -1) {
		$self->{Object}[0] = Dumper($obj);
	} else {
		$self->{Object}[$#{$self->{Object}}] = Dumper($obj);
	}
}

sub register {
	my $self = shift;
	my %args = @_;
	
	if ($args{Compartment}) {	# do it in a safe compartment.

		print "Securely registering $self->{Class} subs.\n" if $Class::Tom::debug;
		my $cpt = $args{Compartment};
		if ($self->{'BEGIN'}) {	# compile any begin blocks
			$cpt->reval("package $self->{Class}; $self->{'BEGIN'}");
			if ($@) {
				warn "ERROR: $@";
				return;
			}
		}

		if ($self->{'main'}) {	# compile any unsubified code
			$cpt->reval("package $self->{Class}; $self->{'main'}");
			if ($@) {
				warn "ERROR: $@";
				return;
			}
		}

		foreach my $fnc (@{$self->{Functions}}) { # register functions.
			$cpt->reval("sub $self->{Class}::$fnc $self->{$fnc}");
			if ($@) {
				warn "ERROR: $@";
				return;
			}
		}

		if ($self->{import}) { # do the import sub
			$cpt->reval("$self->{Class}::import();");
			if ($@) {
				warn "ERROR: $@";
				return;
			}
		}

		if ($self->{Object}) {	# autoreturn the object.
			my $obj = $cpt->reval("\$obj = \$self->{Object}");
			if ($@) {
				warn "ERROR: $@";
				return;
			}
		}

	} else {	# do it without protection, otherwise,
			# in the same way as above.

		if ($self->{'BEGIN'}) {
			eval "package $self->{Class}; $self->{'BEGIN'}";
			if ($@) {
				warn "ERROR: $@";
				return;
			}
		}
		if ($self->{'main'}) {
			eval "package $self->{Class}; $self->{'main'}";
			if ($@) {
				warn "ERROR: $@";
				return;
			}
		}
		foreach my $fnc (@{$self->{Functions}}) {
			print "Registering $self->{Class}::$fnc\n" if $Class::Tom::debug;
			unless (domagic($self, $fnc)) {
				print "WARNING: Could not register $self->{Class}::$fnc\n";
			}
		}
		if ($self->{import}) {
			eval "$self->{Class}::import();";
		}
		if ($self->{Object}[0]) {
			if (wantarray()) {
				return eval $self->{Object}[0];
			} else {
				return $self->{Object};
			}
		}
		
	}
}

# Make the Class::Tom container transportable.
sub store {
	my ($self, %args) = @_;
	my $class;
	$class = $self->{Class};
	my $top = "-- Tom $Class::Tom::VERSION ($Class::Tom::SUBVERSION) Class: $class Base64: $Class::Tom::base64 --\n";
	my $middle;
	if ($Class::Tom::base64 eq 'True') {
		$middle = encode_base64(Dumper($self));
	} else {
		$middle = pack("u",Dumper($self));
	}

	# MD5 Message Digest Authentication...
	my $md = new MD5;
	$md->reset();
	$md->add($middle);
	my $digest = unpack("H*", $md->digest());
	$digest .= "\n";
	my $package = $top . $digest . $middle . $top;

	return $package;
}

sub checksum {
 	my $self = shift;
 
 	my $middle = pack("u",Dumper($self));
 
 	my $md = new MD5;
 	$md->reset();
 	$md->add($middle);
 	return $md->hexdigest();
}

sub repair {
	my $package = shift;
	my $cpt     = shift;	# use a Safe Compartment?
	my @code = split(/^/, $package);
	my $top = shift @code;
	my $declmd = shift @code;
	my $bottom = pop @code;

	chop $declmd;

	my $md = new MD5;
	$md->reset();
	# test for equal delimiters - check MD5 digest if they match
	unless ($top eq $bottom) {
		croak("ERROR: Delimiters do not match");
		return;
	} else {
		my $data = join('',@code);

		$md->add($data);
		my $dig = unpack("H*", $md->digest());

		unless ($dig eq $declmd) {
			croak (
		"ERROR: MD5 Digests do not match\nDiscarding container");
		}
		
		my @delimit = split(/ /,$top);
		my $me;
		if ($delimit[7] eq 'True') {
			if ($Class::Tom::base64 eq 'False') {
				warn "ERROR: No Base64 support on this system";
			} else {
				$me = eval decode_base64($data);
			}
		} else {
			my $me = eval unpack('u', $data);
		}	
		if ($@) { print "ERROR: $@\n"; exit(2) }
		if ($Class::Tom::debug > 1) {
			print("Object:\n" , ref($me));
		}
		unless(ref($me) eq 'Class::Tom') {
			warn "Object contained within container is not of class Tom";
		}
		return $me;
	}
}

# set the debug level
sub debug {
	my $self = shift;
	$Class::Tom::debug = shift;
}

sub cc {
	my $code = shift;
	my $cpt  = shift;	# use a Safe Compartment?
	if (($cpt) && (ref($cpt) ne 'Safe')) {
		warn "CC: Not a Safe Compartment!\n";
		undef $cpt;
	}
	my @first = split(/^/, $code);
	my (@second,@final,@classes,$skip,$cnt,$classcnt,%classhash);
	my $ccline = 1;
	# first pass, remove the pod documents.
	foreach $_ (@first) {
		if(/^=(.*)/) {
			if ($1 ne 'cut') {
				$skip = 1;
			} else {
				$skip = 0;
			}
		}
		unless($skip) {
			$second[$cnt] = $_;
		}		
		$cnt++;
	}
	# reset the skip and counter variable
	$skip = 0; $cnt = 0;
	# second pass, remove anything after a __(.*)__ tag.
	foreach $_ (@second) {
		if(/^__(.*)__/) {
			$skip = 1;
		}
		unless ($skip) {
			$final[$cnt] = $_;
		}
		$cnt++;
	}
	# reset the skip and counter variables
	$skip = 0; $cnt = 0;
	# set up variables specific to the third pass
	my ($subcatch, $maincatch, $output, $argument, $caught);
	my ($classname, $funcname);
	# third pass: catch routines and directives
	foreach $_ (@final) {
		if ( /^(\bpackage\b) (.*);/ ) {
			$classname = $2;
			$classhash{$classname} = $classcnt;
			$classcnt++;
			$classes[$classhash{$classname}] = new Class::Tom 
					Class => $classname;
			print "Generating Class: $classname\n" if $Class::Tom::debug;
		} elsif ( /^sub (.*) {/ ) {
			$subcatch = 1;
			$funcname = $1;
			print "Caching sub: $funcname\n" if $Class::Tom::debug;
		} elsif (($subcatch) && !(/^}/)) {
			$caught .= $_;
		} elsif ( /^}/ ) {
			if ($subcatch) {
				$subcatch = 0;
				$classes[$classhash{$classname}]->declare(
					Name => $funcname,
					Code => '{' . $caught . '}',
					Compartment => $cpt
				);
				print "Adding method $funcname, resetting cache\n" if $Class::Tom::debug;
				$caught = ''; 
			} else {
				print "Adding code to main\n" if $Class::Tom::debug;
				$classes[$classhash{$classname}]->{'main'} .= $_;
			}
		} elsif ( /directive (.*) ('||")(.*)(\2);/ ) {
			print "directive detected ($1,$3)\n" if $Class::Tom::debug;
			if ($1 eq 'output') {
				$output = $3;
			} elsif ($1 eq 'argument') {
				$argument = $3;
			}
		} elsif ( /import (.*);/ ) {
			$classes[$classhash{$classname}]->{"__$1"} = 1;
		} 
		else {
			print "Adding code to main\n" if $Class::Tom::debug;
			$classes[$classhash{$classname}]->{'main'} .= $_;
		}
		$ccline++;
	}
	unless ($output) {
		$output = 'std';
	}
	unless ($argument) {
		$argument = 'std';
	}
	return @classes;
}

# Clean the namespace that Class::Tom has created via the register() method.
sub cleanup {
	my ($self, %args) = @_;
	my $hash = \%{"$self->{Class}::"};
	foreach my $func (keys(%{$hash})) {
		print "Deleting function $func\n" if $Class::Tom::debug;
		delete $hash->{$func};
	}
}

# neat-o function to get the POD docs from the DATA filehandle.
# performs nothing of use to TOM.
sub docs {
	local $/ = undef;
	my $pod = <DATA>;
	return $pod;
}	

1;

__DATA__

=head1 NAME

Class::Tom - Transportable Object model for Perl

=head1 DESCRIPTION

Tom allows for distributed perl objects.  It does not require that an
object's class exists on the machine in order for the object to be used.

=head1 SYNOPSIS

  use Class::Tom qw ( repair );

  my $tom = new Class::Tom Class => 'Demo';

  $tom->declare(Name => 'new', Code => '{ 
	my $class = shift;
	my $self = {};
	bless $self, $class;
  }');

  $tom->declare(Name => 'setname', Code => '{
	my $self = shift;
	$self->{name} = shift;
  }');

  $tom->register();

  my $obj = new Demo;
  $obj->setname('james duncan');

  $tom->insert($obj);

  $data = $tom->store();
  print $data;
  my $newtom = repair($data);

  $tom->cleanup();

=head1 new

C<new> creates a new object of the TOM class.  This is your container for
any module.  It accepts only one argument, and that is the I<class> that the
container will hold.

=head1 class

C<class> returns the class name of the object.

=head1 checksum

C<checksum> returns the MD5 checksum of a TOM container.

=head1 insert

C<insert> takes one argument - the object that you wish to make
transportable. If there are no methods for the the object you insert, Tom
will try to find the .pm file that corresponds to that particular object. 
If it is able to, then it also attempts to compile all the methods in that
class into the Tom object.

C<Tom> now allows you to insert more than one object of the same class.

=head1 declare

C<declare> lets you add functions to the class that will be stored inside
the container.  It accepts two arguments I<Name>, which is the name of the
function, and I<Code> which contains the code that the function uses.

Declaring a function inside the container also declares it outside the
container, allowing you to create the object at the same time, without
having to call C<register> in order to do so. 

=head1 register

C<register> takes a TOM container, and allows its methods to be accessible
from within Perl.  If an object exists within the container,  C<register>
will return the object.

If C<register> is called with the Compartment variable specified then all
of Tom's registering takes place within the safe compartment referenced by the
Compartment variable.

In addition, if there is an 'import' subroutine declared within the class,
Tom will execute the code stored within as soon as it has registered the
functions.

If more than one object exists within the container, and register is called
in array context then C<register> returns an array of un-eval'd
objects.  In order to use any of these objects, they need to be eval'ed.

In scalar context C<register> returns a fully working object, that
corresponds to the first object that was inserted into the array.

=head1 get_object

C<get_object> returns the object stored within the container, but doesn't
register the class on the local machine, which will cause problems unless
you have already used the C<register> method. 

Where multiple objects are concerned, an optional index of the object to
extract can be passed.  -spurkis

=head1 put_object

C<put_object> functions as above, but instead puts the stored object into a
I<Safe> Compartment and returns the variable name it used to do so (e.g.
'$VAR1').  It takes two arguments: a compulsory reference to the I<Safe>
Compartment to be used, and where multiple objects are concerned, an optional
index of the object to extract.  -spurkis

=head1 store

C<store> returns a transportable version of the TOM container.  It no longer
cleans the namespace before continuing.

=head1 repair

C<repair> now takes two arguments.  The first is a TOM container that has
been C<store>'ed, the second is a Safe Compartment in case you're paranoid
of hand-crafted attacks.  You should be - afterall, everyone's out to get
you.  It returns a Perl object that is the TOM container.

=head1 cc

C<cc> takes two options: a scalar containing plaintext Perl code, and an
optional reference to a I<Safe> compartment.  cc() tries to parse code and
create Tom objects.  If it succeeds, it returns a list of Tom containers.
If a Safe compartment is passed all code is registered in that compartment,
otherwise it is eval()d.  -spurkis

=head1 debug

C<debug> sets the debug level for TOM.  Used for development.

=head1 cleanup

C<cleanup> deletes the functions registered from the TOM container into a
namespace, preventing problems in the case of TOM execution servers. 

Please note: as of release 2.04 this function appears broken.  It will try
to delete the namespace of a class matching that in the Tom container I<even
if> it has not been registered.  -spurkis


=head1 methods

C<methods> returns a LIST of the functions inside the TOM container. 

=head1 NIGGLY BITS (or BUGS)

Fix'em as I get 'em.

=head1 MAILING LIST

A mailing list has been set up for Tom and other perl-related Agent
projects,  called Perl5-Agents.  The request address for this mailing list
is perl5-agents-request@daft.com. To send mail to the list email
perl5-agents@daft.com.  

=head1 SEE ALSO

perl(1), perlobj(1)

=head1 AUTHOR

James Duncan <jduncan@hawk.igs.net>

=head1 KUDOS

Thanks to the following people for help with various things:
	(Many Bug Reports)    Mike Blakely <mikeb@netscape.com>
	(Many suggestions)    Steve Purkis <spurkis@engsoc.carleton.ca>
	(P5A Mailing list)    Darran Stalder <torin@daft.com>

=cut
