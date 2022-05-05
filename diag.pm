#!/usr/bin/perl
# ---   *   ---   *   ---
# DIAG
# Yap yap
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package diag;
  use strict;
  use warnings;

  use lib $ENV{'ARPATH'}.'/lib/';

  use vec4;
  use sector;
  use lycon;

# ---   *   ---   *   ---
# getters

sub rect {return (shift)->{-RECT};};
sub inner {return (shift)->rect->children->[0];};

# ---   *   ---   *   ---
# constructor

sub nit {

  my @ttysz=(0,0);
  lycon::ttysz(\@ttysz);

  my $sec=sector::nit(

    vec4::nit(0,0),
    vec4::nit($ttysz[0],16),

    '07',

  );

  my $diag=bless {

    -RECT=>$sec,
    -SEL=>undef,

  },'diag';

  $sec->box();
  my $inner=$sec->inner(3);

  my $text='';for my $x(0..63) {
    $text.="LINE $x\n";

  };

  $inner->text($text);

  $inner->fill();
  $sec->draw();
  $inner->draw();

  return $diag;

};

# ---   *   ---   *   ---

;;sub sel_prev {

  my $self=shift;
  my $inner=$self->inner;

  $inner->wipe();
  $inner->fill(1);
  $inner->draw();

};sub sel_next {

  my $self=shift;
  my $inner=$self->inner;

  $inner->wipe();
  $inner->fill();
  $inner->draw();

};

# ---   *   ---   *   ---
1; # ret
