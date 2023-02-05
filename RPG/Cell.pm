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
  use Arstd::Array;

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

      set
      get_walk

      sput
      rows
      prich

    )],

    id       => $NULLSTR,
    name     => $NULLSTR,

    co       => [],

    grid     => [],
    limit    => [],
    free     => [],

    rect     => undef,

  }};

# ---   *   ---   *   ---
# GBL

  my $World={};

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
# ^batch

sub grid($class,$id,%O) {

  # defaults
  $O{name}   //= 'Darklands';

  $O{height} //= 8;
  $O{width}  //= 8;

  $O{co}     //= [0,0,0,0];

  # use existing
  my $frame=$World->{$id};
  goto SKIP if $frame;

  # ^else make new
  $frame=$class->new_frame(

    id   => $id,
    name => $O{name},

    co   => GF::Vec4::nit(@{$O{co}}),

  );

  # save for later fetch
  $World->{$id}=$frame;

# ---   *   ---   *   ---
# nit cells for this map

  my $grid = $frame->{grid};
  my $free = $frame->{free};

  $frame->{limit}=[$O{width},$O{height}];

  for my $y(0..$O{height}-1) {

    my $row  = $grid->[$y]=[];
    my $frow = $free->[$y]=[];

    for my $x(0..$O{width}-1) {
      push @$row,$frame->cell($x,$y);
      push @$frow,1;

    };

  };

# ---   *   ---   *   ---
# nit rect for drawing

  my ($x,$y)=($O{width}+3,$O{height}+2);

  $frame->{rect}=GF::Rect->nit(
    "${x}x${y}",
    border=>1,

  );

# ---   *   ---   *   ---

SKIP:
  return $frame;

};

# ---   *   ---   *   ---
# occupy cell with object

sub set($class,$frame,$cell,$o) {

  my ($x,$y)        = @{$cell->{co}};
  my $free          = $frame->{free};

  $cell->{occu}     = $o;
  $free->[$y]->[$x] = int(!defined $o);

  return $cell;

};

# ---   *   ---   *   ---
# get list of walkable cells

sub get_walk($class,$frame,@comp) {

  my @out    = ();
  my ($x,$y) = (0,0);

  my $grid   = $frame->{grid};
  my $free   = $frame->{free};

  for my $row(@$free) {

    for my $avail(@$row) {

      next if ! $avail;

      my $cell=$grid->[$y]->[$x++];

      my @dist=map {
        $cell->{co}->dist($ARG)

      } @comp;

      push @out,[$cell,@dist];

    };

    $y++;
    $x^=$x;

  };

  return @out;

};

# ---   *   ---   *   ---
# ^walkable out of neighbors

sub get_nwalk($self) {

  my @out=();

  for my $y(-1,0,1) {
  for my $x(-1,0,1) {

    next if (!$y && !$x) || ($x && $y);

    my $n=$self->neigh($x,$y);
    push @out,$n if $n && !defined $n->{occu};

  }};

  return @out;

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
        ? $cell->{occu}->{sprite}
        : q[ ]
        ;

    };

    push @out,$me;

  };

  return @out;

};

# ---   *   ---   *   ---
# get single tile is free

sub is_nfree($self,$dx,$dy) {

  my $dst = $self->neigh($dx,$dy);
  my $out = ($dst && !$dst->{occu})
    ? $dst
    : undef
    ;

  return $out;

};

# ---   *   ---   *   ---
# debug out

sub prich($class,$frame) {
  map {say $ARG} $frame->rows();

};

# ---   *   ---   *   ---
1; # ret
