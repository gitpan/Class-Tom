package Class::Tom::Code;


use B qw(class main_root main_start main_cv svref_2object);
use B::Deparse;

use strict;
use vars qw ( $VERSION );

$VERSION = '2.00';

sub new {
  my $class = shift;

  my $self = {};
  $self->{Deparser} = bless {
                         'curcv'      => main_cv,
                         'subs_todo'  => [],
                         'curstash'   => "main",
                         'cuddle'     => "\n",
                      }, 'B::Deparse';

  bless $self, $class;
}

sub code ($$) {
  my $self = shift;
  my $coderef = shift;
  return $self->{Deparser}->code($coderef);
}

package B::Deparse;

sub code {
  my $self = shift;
  my $method = shift;             # reference to a subroutine
  if (ref($method) ne 'CODE') {
    return undef;
  }
  my $stash;
  { no strict 'refs'; $stash  = svref_2object($method); }
  local ($self->{'curcv'}) = $stash;
  local ($self->{'curstash'}) = $stash->STASH->NAME;

  my $code = "{\n\t" . $self->deparse($stash->ROOT->first, 0) . "\n\b}";

  my $package = $stash->STASH->NAME;
  my $subname = $self->gv_name($stash->GV);

  my $name;
  if ($subname ne '__ANON__') {
    if ($package) {
      $name = $package . '::' . $subname;
    } else {
      $name = $subname;
    }
  }
  if ($name eq '__ANON__') {
    return indent("sub $code;");
  } else {
    return indent("sub $name $code;");
  }
}

1;

