package Class::Tom::use;

# usage:

# use Tom::use This::is::a::test;

use Class::Tom qw ( repair );

sub import {
	my $name = shift;
	my $pkg = shift;
	my $file;
	foreach $path (@INC) {
		if (-e "$path/$pkg.tm") {
			open(FH, "$path/$pkg.tm") || die "cannot open file: $! at";
			{ local $/ = undef; $file = <FH>; }
			close FH;
			$tom = repair(Package => $file);
			$tom->register();
			eval "$tom->{Class}::import(@_)";
			return 1;
		}
	}
	die "could not find package $pkg at";
}

1;

__END__

=head1 NAME

  Tom::use - use Tom classes like 'use' statement.

=head1 SYNOPSIS

  use Tom::use TomClass

=head1 DESCRIPTION

 I<Tom::use> allows you to use Tom objects transparently.  It searches your
@INC path, and loads the object when it finds it.  It does this at runtime.

=head1 AUTHOR

  James Duncan C<<jduncan@hawk.igs.net>>

=cut
