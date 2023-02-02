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

  use lib $ENV{'ARPATH'}.'/lib/';

  use GF::Vec4;
  use GF::Rect;

  use parent 'St';

# ---   *   ---   *   ---
# ROM

  sub Frame_Vars($class) {return {


    -autoload=>[qw(

      grid
      cell

      in_bounds

      sput
      rows
      prich

    )],

    map_name => 'Darklands',
    world_co => GF::Vec4->nit(55,40),

    grid     => [],
    limit    => [],

    rect     => undef,

  }};

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

sub free($self) {$self->{occu}=undef};

# ---   *   ---   *   ---
# get cell neighbor

sub neigh($self,$dx,$dy) {

  my $frame  = $self->{frame};
  my $grid   = $frame->{grid};

  my ($x,$y) = @{$self->{co}};

  return $frame->cell($x+$dx,$y+$dy);

};

# ---   *   ---   *   ---
# single cell instance

sub cell($class,$frame,$x,$y) {

  my $self=undef;
  my $grid=$frame->{grid};

  goto SKIP if !$frame->in_bounds($x,$y);

  $self=$grid->[$y]->[$x];

  if(!defined $self) {

    $self=bless {

      co     => GF::Vec4->nit($x,$y),
      occu   => undef,

      frame  => $frame,

    },$class;

  };

SKIP:
  return $self;

};

# ---   *   ---   *   ---
# chk x,y within grid

sub in_bounds($class,$frame,$x,$y) {

  my $out   = 1;

  my $limit = $frame->{limit};
  my $fetch = [$x,$y];

  for my $i(0..1) {

    my $b  = $limit->[$i];
    my $co = $fetch->[$i];

    if($co>=$b || $co<0) {
      $out=0;
      last;

    };

  };

  return $out;

};

# ---   *   ---   *   ---

sub grid($class,%O) {

  # defaults
  $O{height} //= 8;
  $O{width}  //= 8;

  my $frame = $class->new_frame();
  my $grid  = $frame->{grid};

  $frame->{limit}=[$O{width},$O{height}];

  for my $y(0..$O{height}-1) {

    my $row=$grid->[$y]=[];

    for my $x(0..$O{width}-1) {
      push @$row,$frame->cell($x,$y);

    };

  };

  my ($x,$y)=($O{width}+3,$O{height}+2);

  $frame->{rect}=GF::Rect->nit(
    "${x}x${y}",
    border=>1,

  );

  return $frame;

};

# ---   *   ---   *   ---
# out draw commands for
# Lycon ctlproc

sub sput($class,$frame) {
  $frame->{rect}->textfit(
    [$frame->rows()],

  );

  return $frame->{rect}->sput();

};

# ---   *   ---   *   ---
# get content of each row of
# cells as a string array

sub rows($class,$frame) {

  my @out  = ();
  my $grid = $frame->{grid};

  for my $row(@$grid) {

    my $me=$NULLSTR;
    for my $cell(@$row) {
      $me.=($cell->{occu})
        ? $cell->{occu}
        : q[ ]
        ;

    };

    push @out,$me;

  };

  return @out;

};

# ---   *   ---   *   ---
# debug out

sub prich($class,$frame) {
  map {say $ARG} $frame->rows();

};

# ---   *   ---   *   ---
1; # ret
