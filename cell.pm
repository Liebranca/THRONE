#!/usr/bin/perl
# ---   *   ---   *   ---
# CELL
# Spot on a plane
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package cell;
  use strict;
  use warnings;

# ---   *   ---   *   ---
# flags

  use constant {

    # cell states
    F_NONE=>0x00,
    F_FIRE=>0x01,
    F_WATER=>0x02,
    F_ACID=>0x04,
    F_HILL=>0x08,

    # neighbors
    N_UL=>0,
    N_UM=>1,
    N_UR=>2,

    N_SL=>3,
    N_SR=>4,

    N_DL=>5,
    N_DM=>6,
    N_DR=>7,

  };

# ---   *   ---   *   ---
# global state

my %CACHE=(

  -GRID=>[],
  -MAP=>'',

  -SZ_X=>undef,
  -SZ_Y=>undef,

);

# ---   *   ---   *   ---
# getters

sub GRID {return $CACHE{-GRID};};
sub SZ_X {return $CACHE{-SZ_X};};
sub SZ_Y {return $CACHE{-SZ_Y};};

sub wx {return (shift)->{-WX};};
sub wy {return (shift)->{-WY};};

sub okupa {return (shift)->{-OCCU};};

sub is_occu {return defined ((shift)->{-OCCU});};
sub is_free {return !((shift)->is_occu);};

sub state {return (shift)->{-STATE};};
sub is_aflame {return (shift)->state & F_FIRE;};
sub is_wet {return (shift)->state & F_WATER;};
sub is_poisnd {return (shift)->state & F_ACID;};
sub is_onhill {return (shift)->state & F_HILL;};

# ---   *   ---   *   ---
# setters

sub occupy {
  my $self=shift;
  my $ok=shift;

  $self->{-OCCU}=$ok;

};

sub free {return (shift)->{-OCCU}=undef;};

# ---   *   ---   *   ---
# get neighboring cell

sub getneigh {

  my $self=shift;

  my $y=shift;
  my $x=shift;

  $y=$self->wy+$y;
  $x=$self->wx+$x;

  if($y==SZ_Y) {$y=0;};
  if($x==SZ_X) {$x=0;};

  return GRID->[$y]->[$x];

};

# ---   *   ---   *   ---
# aliases for neighbor fetches

sub n_ul {return (shift)->getneigh(-1,-1);};
sub n_um {return (shift)->getneigh(-1, 0);};
sub n_ur {return (shift)->getneigh(-1, 1);};

sub n_sl {return (shift)->getneigh( 0,-1);};
sub n_sr {return (shift)->getneigh( 0, 1);};

sub n_dl {return (shift)->getneigh( 1,-1);};
sub n_dm {return (shift)->getneigh( 1, 0);};
sub n_dr {return (shift)->getneigh( 1, 1);};

# ---   *   ---   *   ---

$CACHE{-GET_N_ARR}=[
  \&n_ul,\&n_um,\&n_ur,
  \&n_sl,\&n_sr,
  \&n_dl,\&n_dm,\&n_dr,

];sub GET_N {return $CACHE{-GET_N_ARR};};

# ---   *   ---   *   ---

sub neighfree {

  my $self=shift;
  my $idex=shift;

  my $neigh=GET_N->[$idex]->($self);
  return $neigh->is_free($neigh);

};

# ---   *   ---   *   ---
# aliases for is neighfree

sub is_ul_free {return (shift)->neighfree(N_UL);};
sub is_um_free {return (shift)->neighfree(N_UM);};
sub is_ur_free {return (shift)->neighfree(N_UR);};

sub is_sl_free {return (shift)->neighfree(N_SL);};
sub is_sr_free {return (shift)->neighfree(N_SR);};

sub is_dl_free {return (shift)->neighfree(N_DL);};
sub is_dm_free {return (shift)->neighfree(N_DM);};
sub is_dr_free {return (shift)->neighfree(N_DR);};

# ---   *   ---   *   ---
# constructors

# nit static grid

sub mkgrid {

  my $sz_x=shift;
  my $sz_y=shift;

  $CACHE{-SZ_X}=$sz_x;
  $CACHE{-SZ_Y}=$sz_y;

  for(my $y=0;$y<SZ_Y;$y++) {

    my $row=GRID->[$y]=[];
    for(my $x=0;$x<SZ_X;$x++) {
      push @$row,nit($x,$y);
      $CACHE{-MAP}.='#';

    };$CACHE{-MAP}.="\n";
  };

};sub MAP {return $CACHE{-MAP};};

# ---   *   ---   *   ---
# single cell instance

sub nit {

  my $x=shift;
  my $y=shift;

  my $cell=bless({

    -WX=>$x,
    -WY=>$y,

    -STATE=>F_NONE,
    -OCCU=>undef,

  },'cell');

  return $cell;

};

# ---   *   ---   *   ---
1; # ret
