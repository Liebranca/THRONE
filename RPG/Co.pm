#!/usr/bin/perl
# ---   *   ---   *   ---
# RPG CO
# Spatial logic
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package RPG::Co;

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

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
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

# ---   *   ---   *   ---

sub chardraw($s) {

  my $out=$NULLSTR;

  while($s=~ s[$CHARDW_RE][]) {
    $out.=$1;

  };

  return split $NULLSTR,$out;

};

# ---   *   ---   *   ---
# constructor

sub new($class,%O) {

  # defaults
  $O{pos}    //= [0,0];
  $O{id}     //= 'DARKLANDS-0000';
  $O{sprite} //= q[#];

  # lis
  my $pos   = $O{pos};
  my $at    = RPG::Cell->grid($O{id});

  # make instance
  my $self  = bless {

    cell   => $at->cell(@$pos),
    at     => $at,

    sprite => $O{sprite},

  },$class;

  # spawn
  $self->move(0,0);

  return $self;

};

# ---   *   ---   *   ---
# ^batch

sub array(

  # implicit
  $class,

  #actual
  $base,
  $sprite,
  $sz,

  $atid

) {

  my @ar    = ();
  my @chars = chardraw($sprite);

  my ($sz_x,$sz_y)=sqdim($sz);

  for my $y(0..$sz_y-1) {
    for my $x(0..$sz_x-1) {

      throw_small_sprite($sz)
      if ! @chars;

      my $pos=[
        $base->[0]+$x,
        $base->[1]+$y,

      ];

      my $co=$class->new(

        pos    => $pos,
        id     => $atid,

        sprite => shift @chars,

      );

      push @ar,$co;

    };

  };

  throw_big_sprite($sz)
  if @chars;

# ---   *   ---   *   ---

  my @cell   = map {$ARG->{cell}} @ar;
  my $at     = $ar[0]->{at};

  my $self   = bless {

    cell   => \@cell,
    at     => $at,

    ar     => \@ar,

  },$class;

  return $self;

};

# ---   *   ---   *   ---
# ^errmes

sub throw_small_sprite($sz) {

  errout(

    q[Sprite block is too small for a %s rect],

    args => [$sz],
    lvl  => $AR_FATAL,

  );

};

# ---   *   ---   *   ---

sub throw_big_sprite($sz) {

  errout(

    q[Sprite block is too big for a %s rect],

    args => [$sz],
    lvl  => $AR_FATAL,

  );

};


# ---   *   ---   *   ---
# change occupants

sub swap($self,$new,$old) {

  # set
  $new->{occu}=$self;
  $self->{cell}=$new;

  # free
  $old->{occu}=undef
  if $old ne $new;

};

# ---   *   ---   *   ---
# ^batch

sub array_swap($self,$new,$old) {

  my $i=0;
  for my $co(@{$self->{ar}}) {

    # set
    $new->[$i]->{occu}=$co;
    $co->{cell}=$new->[$i];

    $i++;

  };

  $self->{cell}=$new;

};

# ---   *   ---   *   ---
# grid lookup

sub move($self,$dx,$dy) {

  my $old=$self->{cell};

  if(my $cell=$old->is_nfree($dx,$dy)) {
    $self->swap($cell,$old);

  };

  return @{$self->{cell}->{co}};

};

# ---   *   ---   *   ---
# ^batch

sub array_move($self,$dx,$dy) {

  my $old = $self->{cell};

  # temporary free
  for my $co(@$old) {
    $co->{occu}=undef;

  };

  # confirm the move is possible
  my @new = map {
    $ARG->is_nfree($dx,$dy)

  } @$old;

  array_filter(\@new);

  # enough space, perform move
  if(@new == @$old) {
    $self->array_swap(\@new,$old);

  # nope, undo free
  } else {
    my $i=0;
    for my $co(@$old) {
      $co->{occu}=$self->{ar}->[$i++];

    };

  };

  return @{$self->{cell}->[0]->{co}};

};

# ---   *   ---   *   ---
1; # ret
