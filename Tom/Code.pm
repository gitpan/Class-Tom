package Class::Tom::Code;

use B::Deparse;

sub new {
	my $class = shift;
	my %args  = @_;

	my $self  = {};

	$self->{Class}   = $class;
	$self->{Deparse} = new B::Deparse;

	bless $self, $self->{Class};
}

sub code {
	my $self = shift;
	my $anon = shift;

	if (ref($anon) ne 'CODE') {
		$self->{_error} = "Code reference required.\n";
		return undef;
	} else {
		return $self->{Deparse}->code($anon);
	}
}

sub error {
	my $self = shift;
	return $self->{_error};
}

1;

