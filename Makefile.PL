use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'Class::Tom',
    'VERSION_FROM' => 'Tom.pm', # finds $VERSION
    'dist' => {
	       COMPRESS=>'gzip -9f',
               SUFFIX=>'gz',
    	       DIST_DEFAULT => 'ci tardist'
              },
);
