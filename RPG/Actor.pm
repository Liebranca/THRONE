#!/usr/bin/perl
# ---   *   ---   *   ---
# RPG Actor
# A player uppon the stage
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package RPG::Actor;

  use v5.36.0;
  use strict;
  use warnings;

  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;
  use parent 'St';

  use lib $ENV{'ARPATH'}.'/lib/';

  use GF::Vec4;
  use GF::Icon;

  use lib $ENV{'ARPATH'}.'/THRONE/';

  use RPG::Cell;
  use RPG::Social;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.2;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  sub Frame_Vars($class) {return {

    -autoload=>[qw(
      member

    )],

    name       => 'Circle of Four',

    affiliates => [],
    relations  => [],

    goals      => [],

  }};

# ---   *   ---   *   ---
# constructor

sub member($class,$frame,$at,$co,%O) {

  # defaults
  $O{name}      //= 'Vagabond';
  $O{sprite}    //= $GF::Icon::PAIN_S0;
  $O{goals}     //= [];
  $O{relations} //= [];

  $O{traits}    //= undef;

  # make new
  my $self=bless {

    name    => $O{name},

    at      => $at,
    co      => GF::Vec4->nit(@$co),

    cell    => undef,
    faction => $frame,

    persona => RPG::Social->new(traits=>$O{traits}),

  },$class;

  # spawn
  $self->move(0,0);
  push @{$frame->{affi}},$self;

  return $self;

};

# ---   *   ---   *   ---

sub faction($class,%O) {
  return $class->new_frame(%O);

};

# ---   *   ---   *   ---

sub move($self,$x,$y) {

  my @out=();

  my $old=$self->{at}->cell(
    $self->{co}->[0],
    $self->{co}->[1],

  );

  my $cell=$old->neigh($x,$y);

  if($cell && $cell->is_free()) {

    $cell->occupy($self);

    $self->{cell}=$cell;
    $old->free() if $old ne $cell;

    $self->{co}=$cell->{co};
    ($x,$y)=@{$self->{co}};

    push @out,{
      proc => 'mvcur',
      args => [0,20],

      ct   => "$self->{name} moves to [$x,$y]",

    };

  };

  return @out;

};

# ---   *   ---   *   ---

sub social($self,$fn,@args) {

  my ($ctx,$act,$feel)=$self->{persona}->$fn(@args);

  say "On $ctx: $self->{name} chooses $act($feel)";

};

# ---   *   ---   *   ---
# test

my $map  = RPG::Cell->grid();
my $band = RPG::Actor->faction(name=>'Traveling knights');

my $boro = $band->member($map,[0,0],name=>'Boro');

$boro->social(qw(situation encounter));

# ---   *   ---   *   ---
1; # ret
