package Class::Tom::Encode;

$VERSION = '1.00';

sub new {
	my $class = shift;
	my %args  = @_;

	my $self  = {};
	
	$self->{Class} = $class;

	bless $self, $self->{Class};
}

1;

