package Class::Tom::demand;

require Exporter;
@ISA = qw (Exporter);
@EXPORT = qw ( demand );

sub demand {
	my $name = shift;
	my $pkg = shift;
	my $file;
	my $path;
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

