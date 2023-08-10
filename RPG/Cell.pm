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
# info

  our $VERSION = v0.00.5;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  sub Frame_Vars($class) {return {


    -autoload=>[qw(

      tile

      nit_tiles
      nit_rect

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

  my $frame  = $self->{cell};
  my ($x,$y) = @{$self->{co}};

  return $frame->tile($x+$dx,$y+$dy);

};

# ---   *   ---   *   ---
# single tile instance

sub tile($class,$frame,$x,$y) {

  my $self=undef;
  my $grid=$frame->{grid};

  goto SKIP if ! $frame->in_bounds($x,$y);

  $self=$grid->[$y]->[$x];

  if(! defined $self) {

    $self=bless {

      co   => GF::Vec4->nit($x,$y),
      occu => undef,

      cell => $frame,

    },$class;

  };

SKIP:
  return $self;

};

# ---   *   ---   *   ---
# ^batch

sub new($class,$id,%O) {

  # defaults
  $O{name}   //= 'Darklands';

  $O{height} //= 8;
  $O{width}  //= 8;
  $O{co}     //= [0,0,0,0];

  # make new
  my $frame=$class->new_frame(

    id   => $id,
    name => $O{name},

    co   => GF::Vec4->nit(@{$O{co}}),

  );

  $frame->nit_tiles($O{width},$O{height});
  $frame->nit_rect();

  # save for later fetch
  $World->{$id}=$frame;

  return $frame;

};

# ---   *   ---   *   ---
# initializes tiles of a cell

sub nit_tiles(

  # implicit
  $class,
  $frame,

  # actual
  $sz_x,
  $sz_y

) {

  my $grid = $frame->{grid};
  my $free = $frame->{free};

  $frame->{limit}=[$sz_x,$sz_y];

  for my $y(0..$sz_y-1) {

    my $row  = $grid->[$y]=[];
    my $frow = $free->[$y]=[];

    for my $x(0..$sz_x-1) {
      push @$row,$frame->tile($x,$y);
      push @$frow,1;

    };

  };

};

# ---   *   ---   *   ---
# ^rect for drawing

sub nit_rect($class,$frame) {

  my ($x,$y)=@{$frame->{limit}};

  $frame->{rect}=GF::Rect->nit(
    "${x}x${y}",
    border=>1,

  );

};

# ---   *   ---   *   ---
# recover instances

sub fetch($class,$id,%O) {

  my $frame=(! exists $World->{$id})
    ? $World->{$id}
    : $class->new($id,%O)
    ;

  return $frame;

};

# ---   *   ---   *   ---
# just so that RPG::Space->new
# can accept refs and ids

sub ref_or_id($class,$at) {

  my $out=undef;

  # 'at' is instance
  if(0<length ref $at) {
    $out=$at;

  # ^'at' is an id
  } else {
    $out=$class->fetch($at);

  };

  return $out;

};

# ---   *   ---   *   ---
# occupy cell with object

sub set($class,$frame,$cell,$o) {

  my ($x,$y)        = @{$cell->{co}};
  my $free          = $frame->{free};

  $cell->{occu}     = $o;
  $free->[$y]->[$x] = int(! defined $o);

  return $cell;

};

# ---   *   ---   *   ---
# get list of walkable cells

sub get_walk($class,$frame,@comp) {

  my @out    = ();
  my ($x,$y) = (0,0);

  my $free   = $frame->{free};

  for my $row(@$free) {

    for my $avail(@$row) {

      # skip occupied
      if(! $avail) {
        $x++;
        next;

      };

      my $tile=$frame->tile($x++,$y);

      # get distance for each point
      my @dist=map {
        $tile->{co}->dist($ARG)

      } @comp;

      push @out,[$tile,@dist];

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
    push @out,$n if $n && ! $n->{occu};

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
