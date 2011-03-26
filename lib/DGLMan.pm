package DGLMan;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw/say_good say_bad say_emphasized say_coloured
                 coloured_text/;

use Term::ANSIColor;

sub good_text(@) {
  coloured_text('green', @_)
}

sub bad_text(@) {
  coloured_text('red', @_)
}

sub coloured_text($@) {
  my $color = shift;
  color($color) . join('', @_) . color('reset')
}

sub say_coloured($@) {
  my $color = shift;
  print(color($color), @_, color('reset'));
}

sub say_good(@) {
  print(good_text(@_));
}

sub say_bad(@) {
  print(bad_text(@_));
}

sub say_emphasized(@) {
  print(coloured_text('bold', @_));
}

1
