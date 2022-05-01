#!/usr/bin/perl
# ---   *   ---   *   ---
# SCENE
# Map data && view frustum
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package scene;
  use strict;
  use warnings;

  use lib $ENV{'ARPATH'}.'/lib/';
  use cell;
  use entity;

# ---   *   ---   *   ---
# global state

my %CACHE=(

  -FRUSTUM_SZ=>[16,16],
  -WORLD_SZ=>[17,17],

  -LOCAL_POS=>[0,0],

);

# ---   *   ---   *   ---
# getters

sub FRUSTUM_SZ {return $CACHE{-FRUSTUM_SZ};};
sub WORLD_SZ {return $CACHE{-WORLD_SZ};};
sub LOCAL_POS {return $CACHE{-LOCAL_POS};};

sub getview {

  my ($frus_x,$frus_y)=@{FRUSTUM_SZ()};
  my ($lpos_x,$lpos_y)=@{LOCAL_POS()};

  return [

    [$lpos_x,$lpos_x+$frus_x],
    [$lpos_y,$lpos_y+$frus_y],

  ];

};

# ---   *   ---   *   ---

sub ents_in_view {

  my ($frustum_x,$frustum_y)=@{getview()};
  my $ents=[];
  my $ent=undef;

  my $append=sub {
    push @$ents,$ent;

  };my $proc=[sub {;},$append];

  for my $y(
    ($frustum_y->[0]..($frustum_y->[1]-1))

  ) {

    for my $x(
      ($frustum_x->[0]..($frustum_x->[1]-1))

    ) {

      my $cell=cell::GRID->[$y]->[$x];

if(!defined $cell) {
  printf "$x:$y\n";exit;

};

      $ent=$cell->okupa;
      $proc->[$cell->is_occu]->();

    };

  };return $ents;

};

# ---   *   ---   *   ---

sub nit {

  cell::mkgrid(@{WORLD_SZ()});
  my $stats=entity::TEMPLATE(

    -HEALTH=>2,

  );

  entity::nit($stats,[0,0]);

};

# ---   *   ---   *   ---
1; # ret
