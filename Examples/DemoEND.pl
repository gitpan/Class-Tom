use Data::Dumper;
use Class::Tom qw ( repair );

while(<>) {
	$data .= $_;
}

$tom = repair ( $data );

print $tom->store();

my ($obj, @rest) = $tom->register();
$obj->timelived();
