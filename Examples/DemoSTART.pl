# This is a demonstration of Tom storing a class that is sucked in by
# inserting the object.

use Class::Tom;
use IO::Socket;

my $tom = new Class::Tom Class => 'Demo';


# Create the constructor.
$tom->declare ( Name => 'new', Code => <<'HERE'
{
	my $class = shift;
	my $self  = {};
	$self->{timecreated} = time();
	bless $self, $class;
}
HERE
);

# Create the destructor
$tom->declare ( Name => 'timelived', Code => <<'HERE'
{
	my $self = shift;
	my $time = time();
	my $f = $time - $self->{timecreated};
	print STDERR "I was born at $self->{timecreated}\n";
	print STDERR "I lived for $f seconds\n";
}
HERE
);

# create a new object.
my $obj = new Demo;

# stick it into the Tom container.
$tom->insert($obj);

# print out the Tom container that can be picked up at anytime in the
# future, and executed.
print $tom->store();



