use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'Class::Tom',
    'VERSION_FROM' => 'Tom.pm', # finds $VERSION
    'dist' => {
	       COMPRESS=>'gzip -9f',
               SUFFIX=>'gz',
    	       DIST_DEFAULT => 'tardist'
              },
    $] >= 5.005 ? ('AUTHOR' => 'James A. Duncan <j@mesduncan.co.uk',
                   'ABSTRACT' => 'Transportable Object Model for Perl',
                   'PREREQ_PM' => { 'Data::Dumper'    => 2.08,
                                    'Digest::MD5'     => 2.09,
                                    'MIME::Base64'    => 2.11,
                                    'Devel::Symdump'  => 2.00,
                                  }
                  ) : ()

);
