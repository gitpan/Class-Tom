package Class::Tom;

=head1 NAME

Class::Tom - The Transportable Object Model for Perl

=head1 SYNOPSIS

use Class::Tom qw ( restore );

my $tom = new Class::Tom;

$tom->insert(<OBJECT>);

$tom->insert(<ANONYMOUS SUB>);

$tom->insert(<PACKAGE NAME>);

my $flat = $tom->store();

my $newtom = restore( $flat );

=head1 DESCRIPTION

C<Class::Tom> allows you to transport objects from one system to another
without requiring that the packages the object relies on actually exist on
the other machine.

=head1 METHODS

=cut

require 5.005;

use Exporter;
use base qw ( Exporter );
use Data::Dumper;
use Class::Tom::Code;
use Digest::MD5 qw ( md5_hex );
use Devel::Symdump;

@EXPORT_OK  = qw ( restore );
$VERSION = '3.01';

=item new

C<new> is the objects constructor.  It can optionally take the Encoder
argument if you've created a new encoding scheme.

=cut

# Create the new Tom compartment
sub new {
	my $class = shift;
	my %args  = @_;

	if (!$args{Encoder}) {
		$args{Encoder} = 'Base64';
	}
	
	my $self  = {};

	$self->{Functions} = ();
	$self->{Encoder}   = $args{Encoder};

	bless $self, $class;
}

=item insert 

The C<insert> method accepts one of three things as an argument, a) an
CODE reference (such as an anonymous subroutine or a reference to a
subroutine), b) an Object or c) a string that contains the package name.
If you insert an Object then C<insert> returns the id of that object in
the internal object list.

=cut

#
# Insert a solitary subroutine, and object, or an entire package into the TOM compartment.
#
sub insert {
	my $self = shift;
	my $anon = shift;

	if (ref($anon) eq 'CODE') {		# handles code refs

		my $dep  = new Class::Tom::Code;
		my $code = $dep->code($anon);

		if ($code eq undef) {
			print $dep->error();
		} else {
			push @{$self->{Functions}}, $code;
		}

	} elsif (ref($anon) && ref($anon) ne 'CODE') {	# Handles objects

		push @{$self->{Objects}}, Dumper($anon);
		$self->insert(ref($anon));

		return scalar(@{$self->{Objects}}) - 1;

	} else {				# Handles packagenames

		my $dump = new Devel::Symdump ( $anon );

		foreach my $subroutine ( $dump->functions() ) {

			$self->insert(\&{"$subroutine"});

		} 

	}

	return 1;
}

=item extract

The C<extract> method returns an object that has been C<insert>'ed.  The
argument is the Id of the object you insert.

=cut

#
#  Returns an object from the TOM compartment
#
sub extract {

	my $self = shift;
	my $objId = shift;
	
	return eval $self->{Objects}[$objId];

}

=item store

The C<store> method returns the flattened container ready for shipping.

=cut
#
# returns the frozen object
#
sub store {
	my $self = shift;
	my $package = "Class\:\:Tom\:\:Encode\:\:$self->{Encoder}";
	eval "use $package;";
	my $enc  = new $package;
	my $view = $self->header() . "---\n" . $enc->encode($self->_dump_internals()) . "---\n" . $self->header();
	return "MD5: " .  md5_hex($view) . "\n$view";
}

#
# This simply returns a dumped version of itself.
#
sub _dump_internals {
	my $self = shift;
	return Dumper($self);
}

=item register 

The C<register> method evals each of the methods stored inside the TOM
compartment

=cut
#
# This takes the code stored inside itself, and evals them.
#
sub register {
	my $self = shift;
	my $count;
	foreach my $sub (@{$self->{Functions}}) {
		$count++;
		eval $sub;
		if ($@) {
			print "Could not eval sub $count\n$@\n";
		}
	}
	return $count;
}

=item restore

C<restore> is optionally exported, and is used to turn a flattened TOM
object into a real perl object.

=cut
#
# This restores the data of a stored TOM object, and reregisters it.
#
sub restore {
	my $data = shift;
	my @lines = split(/\n/, $data);

	my ($tmp, $md5)    = split(/:\s+/,shift @lines);
	my $header = shift @lines;
	my $footer = pop   @lines;


	if ($header ne $footer) {
		print "Incomplete TOM compartment.\n";
		return 0;
	} 

	my ($tmp, $version, $encoder, $tmp) = split(/\s+/, $header);
	my ($tmp, $encoder) = split(/:/, $encoder);

	my $package = "Class\:\:Tom\:\:Encode\:\:$encoder";
	eval "use $package;";
	my $enc  = new $package;
	return eval $enc->decode(join('',@lines));
	
}


#
# This generates the delimeters
#
sub header {
	my $self = shift;
	return "Class:\:Tom Version:$VERSION Encoding:$self->{Encoder} Class\:\:Tom\n";
}


1;

__END__

=head1 BUGS

There are probably loads.  I've not had time to test this on any machine
other than my own,  so your milage may vary.  Remember, this is a beta
version.  3.02 will be the full bugfixed release.

=head1 AUTHOR

James A. Duncan <j@mesduncan.co.uk>

=head1 SEE ALSO

perl(1)

=cut

