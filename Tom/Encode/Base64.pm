package Class::Tom::Encode::Base64;

use MIME::Base64;
use Class::Tom::Encode;

use base qw ( Class::Tom::Encode );

sub encode {
	my $self = shift;
	my $text = shift;

	return encode_base64($text);
}

sub decode {
	my $self = shift;
	my $text = shift;

	return decode_base64($text);
}

1;

