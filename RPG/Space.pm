#!/usr/bin/perl
# ---   *   ---   *   ---
# RPG SPACE
# Logics of movement
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package RPG::Space;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;

  use Arstd::Array;
  use Arstd::IO;

  use lib $ENV{'ARPATH'}.'/lib/';

  use GF::Vec4;
  use GF::Rect;
  use GF::Icon;

  use lib $ENV{'ARPATH'}.'/THRONE/';
  use RPG::Cell;

  use parent 'St';

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.2;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly my $CHARDW_RE=>qr{

    \s* :

    (?<line>

      (?<! ;)
      [^\n]+

    )

    ;\n

  }x;

  Readonly our $DEFAULTS=>{

    pos    => [0,0],
    size   => '1x1',

    cell   => 'DARKLANDS-0000',

    sprite => q[
      :$;

    ],

    behave => undef,

  };

# ---   *   ---   *   ---

sub chardraw($s) {

  my $out=$NULLSTR;

  while($s=~ s[$CHARDW_RE][]) {
    $out.=$1;

  };

  return split $NULLSTR,$out;

};

# ---   *   ---   *   ---
# cstruc

sub new($class,%O) {

  $class->defnit(\%O);

  # lis
  my $pos   = $O{pos};
  my $cell  = RPG::Cell->ref_or_id($O{cell});

  # make instance
  my $self  = bless {

    tile   => $cell->tile(@$pos),
    cell   => $cell,

    sprite => $O{sprite},

  },$class;

  # spawn
  $self->teleport(@$pos);

  return $self;

};

# ---   *   ---   *   ---
# ^batch

sub array($class,%O) {

  $class->defnit(\%O);

  my @ar    = ();
  my @chars = chardraw($O{sprite});

  my ($sz_x,$sz_y)=sqdim($O{size});

  # walk sprite
  for my $y(0..$sz_y-1) {
    for my $x(0..$sz_x-1) {

      throw_small_sprite($O{size})
      if ! @chars;

      # skip blanks
      my $c=shift @chars;
      next if $c eq q[ ];

      # get position of char
      my $pos=[
        $O{pos}->[0]+$x,
        $O{pos}->[1]+$y,

      ];

      my $be=(defined $O{behave})
        ? $O{behave}->{$c}
        : undef
        ;

      # make instance
      my $co=$class->new(

        pos    => $pos,
        cell   => $O{cell},

        sprite => $c,
        behave => $be,

      );

      push @ar,$co;

    };

  };

  throw_big_sprite($O{size}) if @chars;

# ---   *   ---   *   ---

  my @tiles  = map {$ARG->{tile}} @ar;
  my $cell   = $ar[0]->{cell};

  my $self   = bless {

    tiles    => \@tiles,
    cell     => $cell,

    ar       => \@ar,

    on_touch => $O{behave}->{on_touch},

  },$class;

  return $self;

};

# ---   *   ---   *   ---
# ^sprite wastes space

sub throw_small_sprite($sz) {

  errout(

    q[Sprite block is too small for a %s rect],

    args => [$sz],
    lvl  => $AR_FATAL,

  );

};

# ---   *   ---   *   ---
# ^sprite doesn't fit

sub throw_big_sprite($sz) {

  errout(

    q[Sprite block is too big for a %s rect],

    args => [$sz],
    lvl  => $AR_FATAL,

  );

};

# ---   *   ---   *   ---
# runs interaction

sub iract($self,$fn,@args) {

  my $out=(defined $self->{$fn})
    ? $self->{$fn}->($self,@args)
    : undef
    ;

  return $out;

};

# ---   *   ---   *   ---
# batch change occupants

sub array_swap($self,$new,$old) {

  my $cell = $self->{cell};
  my $i    = 0;

  for my $co(@{$self->{ar}}) {

    $co->{tile}=$cell->set(
      $new->[$i++],$co

    );

  };

  $self->{tiles}=$new;

};

# ---   *   ---   *   ---
# absolute movement

sub teleport($self,$ax,$ay) {

  my $old  = $self->{tile};
  my $cell = $self->{cell};

  my $dst  = $cell->tile($ax,$ay);

  if($dst && !$dst->{occu}) {

    $cell->set($old,undef);

    $self->{tile}=$cell->set(
      $dst,$self

    );

  };

  return @{$self->{tile}->{co}};

};

# ---   *   ---   *   ---
# ^batch

sub array_teleport($self,$ax,$ay) {

  my $old=$self->array_free();
  my $new=$self->array_tilemap($old,$ax,$ay);

  # move if possible
  $self->array_cswap($new,$old);

  return @{$self->{tiles}->[0]->{co}};

};

# ---   *   ---   *   ---
# move relative to current

sub walk($self,$dx,$dy) {

  my $old  = $self->{tile};
  my $cell = $self->{cell};

  if(my $tile=$old->is_nfree($dx,$dy)) {

    $cell->set($old,undef);

    $self->{tile}=$cell->set(
      $tile,$self

    );

  };

  return @{$self->{tile}->{co}};

};

# ---   *   ---   *   ---
# ^batch

sub array_walk($self,$dx,$dy) {

  my $old=$self->array_free();

  # get tiles
  my $new=[map {
    $ARG->is_nfree($dx,$dy)

  } @$old];

  array_filter($new);

  $self->array_cswap($new,$old);

  return @{$self->{tiles}->[0]->{co}};

};

# ---   *   ---   *   ---
# perform swap if space avail
# else undo free

sub array_cswap($self,$new,$old) {

  my $out=0;

  if(@$new == @$old) {
    $self->array_swap($new,$old);

  } else {
    $self->array_unfree($old);
    $out=1;

  };

  return $out;

};

# ---   *   ---   *   ---
# map self unto absolute position

sub array_tilemap($self,$old,$ax,$ay) {

  my $out  = [];

  my $cell = $self->{cell};
  my $pos  = $self->origin()->{co};

  for my $o(@$old) {

    # relative to origin
    my ($rx,$ry)=(
      $o->{co}->[0] - $pos->[0],
      $o->{co}->[1] - $pos->[1],

    );

    # ^shift by absolute
    my ($x,$y)=($ax+$rx,$ay+$ry);

    # get tile
    my $dst=$cell->tile($x,$y);
    push @$out,$dst if $o && ! $o->{occu};

  };

  return $out;

};

# ---   *   ---   *   ---
# wipe self from map

sub array_free($self) {

  my $out=$self->{tiles};
  map {$ARG->{occu}=undef} @$out;

  return $out;

};

# ---   *   ---   *   ---
# ^reassign values

sub array_unfree($self,$old) {

  my $i=0;

  map {
    $ARG->{occu}=$self->{ar}->[$i++]

  } @$old;

};

# ---   *   ---   *   ---
# change map of block

sub door_to($self,$new_cell,$new_pos) {

  my $old_cell = $self->{cell};
  my $old_tile = $self->{tile};

  $old_cell->set($old_tile,undef);

  $self->{cell}=$new_cell;
  $self->teleport(@$new_pos);

};

# ---   *   ---   *   ---
# ^batch

sub array_door_to($self,$new_cell,$new_pos) {

  my $old_cell = $self->{cell};
  my $old_pos  = $self->{ar};

  for my $co(@$old_pos) {
    $co->{cell}=$new_cell;

  };

  $self->{cell}=$new_cell;
  $self->array_teleport(@$new_pos);

};

# ---   *   ---   *   ---
# get [0,0] of block

sub origin($self) {
  return $self->{tiles}->[0];

};

# ---   *   ---   *   ---
# get tiles around point

sub nof($self) {

  my $out={};

  $self->nof_loop($out);
  return values %$out;

};

# ---   *   ---   *   ---
# ^fills out surrounds

sub nof_loop($self,$dst) {

  my $cell = $self->{cell};
  my $tile = $self->{tile};

  for my $dy(-1,0,1) {
  for my $dx(-1,0,1) {

    next if !$dx && !$dy;

    my $p=$tile->neigh($dx,$dy);
    $dst->{$p}=$p if $p && !$p->{occu};

  }};

};

# ---   *   ---   *   ---
# ^batch

sub array_nof($self) {

  my $out = {};
  my $ar  = $self->{ar};

  for my $co(@$ar) {
    $co->nof_loop($out);

  };

  return values %$out;

};

# ---   *   ---   *   ---
1; # ret
