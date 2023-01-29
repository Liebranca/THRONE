#!/usr/bin/perl
# ---   *   ---   *   ---
# RPG CELL
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
package RPG::Cell;

  use v5.36.0;
  use strict;
  use warnings;

  use English qw(-no_match_vars);
  use Readonly;

  use lib $ENV{'ARPATH'}.'/lib/sys/';
  use Style;

  use parent 'St';

# ---   *   ---   *   ---
# ROM

  # cell states
  Readonly our $F_NONE=>0x00;
  Readonly our $F_FIRE=>0x01;
  Readonly our $F_WATER=>0x02;
  Readonly our $F_ACID=>0x04;
  Readonly our $F_HILL=>0x08;

    # neighbors
  Readonly our $N_UL=>0;
  Readonly our $N_UM=>1;
  Readonly our $N_UR=>2;

  Readonly our $N_SL=>3;
  Readonly our $N_SR=>4;

  Readonly our $N_DL=>5;
  Readonly our $N_DM=>6;
  Readonly our $N_DR=>7;

# ---   *   ---   *   ---
# aliases for neighbor fetches

  Readonly my $GET_N=>{

    up_left=>[-1,-1],
    up_mid=>[ 0,-1],
    up_right=>[ 1,-1],

    left=>[-1, 0],
    self=>[ 0, 0],
    right=>[ 1, 0],

    down_left=>[-1, 1],
    down_mid=>[ 0, 1],
    down_right=>[ 1, 1],

  };

# ---   *   ---   *   ---

sub occuppier($self) {return $self->{occu}};

sub is_occuppied($self) {
  return defined $self->{occu};

};

sub is_free($self) {
  return !defined $self->{occu};

};

# ---   *   ---   *   ---
# setters

sub occupy($self,$ok) {
  return $self->{occu}=$ok

};

sub free($self) {return $self->{occu}=undef};

# ---   *   ---   *   ---
# get neighboring cell

sub _getneigh($self,$x,$y) {

  my $frame=$self->{frame};
  my $grid=$frame->{-cells};

  my ($sz_x,$sz_y)=(

    $frame->{-sz_x},
    $frame->{-sz_y},

  );

  $y=$self->{wy}+$y;
  $x=$self->{wx}+$x;

  if($y==$sz_y) {$y=0;};
  if($x==$sz_x) {$x=0;};

  return $grid->[$y]->[$x];

};

# ---   *   ---   *   ---

sub getneigh($self,$idex) {
  return $self->_getneigh(@{$GET_N->{$idex}});

};

# ---   *   ---   *   ---
# single cell instance

sub nit($class,$frame,$x,$y) {

  my $cell=bless {

    wx=>$x,
    wy=>$y,

    _state=>$F_NONE,
    occu=>undef,

    frame=>$frame,

  },$class;

  return $cell;

};

# ---   *   ---   *   ---

sub get_sprite($self) {

  my $out;

  if($self->is_free()) {
    $out=q{ };

  } else {
    $out=$self->{occu}->{sprite};

  };

};

# ---   *   ---   *   ---
1; # ret
