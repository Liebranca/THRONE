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

sub sel {

  my $self=shift;
  my $step=shift;

  my $cap=@{$self->inner->text_lines()}-1;

  my $prev=$self->{-SEL};
  my $next=$prev+$step;

  if($next<0) {
    $next=0;

  } elsif($next>$cap) {
    $next=$cap;

  };

  $self->{-SEL}=$next;
  return "$prev:$next";

};

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
    -SEL=>0,

  },'diag';

  $sec->box();
  my $inner=$sec->inner(3);

  my $text='';for my $x(0..63) {
    $text.="LINE $x\n";

  };

  $inner->text($text);

  $inner->fill(0,'0:0');
  $sec->draw();
  $inner->draw();

  return $diag;

};

# ---   *   ---   *   ---

;;sub sel_prev {

  my $self=shift;
  my $inner=$self->inner;

  $inner->wipe();
  $inner->fill(1,$self->sel(-1));
  $inner->draw();

};sub sel_next {

  my $self=shift;
  my $inner=$self->inner;

  $inner->wipe();
  $inner->fill(0,$self->sel(+1));
  $inner->draw();

};

# ---   *   ---   *   ---
1; # ret
