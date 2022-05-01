#!/usr/bin/perl
# ---   *   ---   *   ---
# ENTITY
# Units and buildings
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package entity;
  use strict;
  use warnings;

  use lib $ENV{'ARPATH'}.'/lib/';
  use cell;

# ---   *   ---   *   ---
# dunno how to make it constant :c

my %DEFAULTS=(

  -STATS=>{

    -HEALTH=>1,
    -TAKES_DAMAGE=>0,

    -HARMOR=>0,
    -PARMOR=>0,

    -STONE=>0,
    -GOLD=>0,
    -FOOD=>0,
    -WOOD=>0,

    -HATTACK=>0,
    -PATTACK=>0,
    -HRANGE=>0,
    -PRANGE=>0,

  },

);

# ---   *   ---   *   ---
# flags

  use constant {

    F_UNIT=>0x01,
    F_RES=>0x02,
    F_STATIC=>0x04,
    F_BUILDING=>0x08,

  };

# ---   *   ---   *   ---
# getters

sub is_alive {return 0>(shift)->{-HEALTH};};

sub wx {return (shift)->{-WX};};
sub wy {return (shift)->{-WY};};

# ---   *   ---   *   ---
# constructor stuff

# entity property template

sub TEMPLATE {

  my $h={};
  while(@_) {
    $h->{(shift)}=shift;

  };

  for my $key(keys %{$DEFAULTS{-STATS}}) {
    if(!exists $h->{$key}) {
      $h->{$key}=$DEFAULTS{-STATS}->{$key};

    };
  };

  return $h;

};

# ---   *   ---   *   ---

sub move {

  my $self=shift;
  my $off=shift;

  # free previously occupied cell
  my $old_x=$self->wx;
  my $old_y=$self->wy;
  my $new_x=$self->wx+$off->[0];
  my $new_y=$self->wy+$off->[1];

  my $dst=cell::GRID->[$new_y]->[$new_x];
  if($dst->is_free) {
    cell::GRID->[$old_y]->[$old_x]->free();
    $dst->occupy($self);

  };

};

# ---   *   ---   *   ---
# entity initializer

sub nit {

  my $h=shift;
  my $pos=shift;

  $h->{-WX}=$pos->[0];
  $h->{-WY}=$pos->[1];

  my $ent=bless $h,'entity';

  cell::GRID
    ->[$ent->wy]
    ->[$ent->wx]
    ->occupy($ent);

  return $ent;

};

# ---   *   ---   *   ---
1; # ret
