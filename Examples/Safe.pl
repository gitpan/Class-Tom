# This is an example of how to use a safe compartment with TOM.
# NOTE: I do not make any guarantees about the security of this
# code.


use Safe;
use Class::Tom qw ( repair );	# load TOM with repair.

# get the stored TOM container from a file.
my $stored;
while(<>) {
	$stored .= $_;
}


# repair the container.
my $tom = repair ( $stored );

# create the safe compartment in which the code will thrive (hopefully)
my $comp = new Safe;
$comp->permit( time );
# register functions inside the safe compartment.
$tom->register ( Compartment => $comp );

# .. do whatever ..