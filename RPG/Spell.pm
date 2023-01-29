#!/usr/bin/perl
# ---   *   ---   *   ---
# SPELL
# Describes base format
# for spell instances
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---

package RPG::Spell;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/THRONE/';
  use RPG::Dice;

  use lib $ENV{'ARPATH'}.'/lib/sys';
  use Style;

  use parent 'St';

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.2;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  sub Frame_Vars($class) {return {

    -autoload=>[qw(
      neww

    )],

  }};

  Readonly our $DEFAULTS=>{

    # id
    name    => 'Transfigurate',
    school  => 'Raw Lytheknics',

    # score
    degree  => 3,
    elems   => [],
    reqs    => [],
    rolls   => [qw(1d8)],

    # lore
    desc    => (join q[ ],qw(

      This vociferation
      shall endlessly
      reform

    )),

    # modes
    on_any=>sub ($self,$actor) {

      my ($x)=$self->roll();

      say

        "$actor->{name} ".
        "chants $self->{name} ".

        "with a score of $x"

      ;

    },

    on_self   => $NOOP,
    on_touch  => $NOOP,
    on_target => $NOOP,
    on_area   => $NOOP,

    on_ally   => $NOOP,
    on_foe    => $NOOP,

  };

# ---   *   ---   *   ---
# GBL

  my $Frame=RPG::Spell->get_frame();

# ---   *   ---   *   ---
# IO

  sub import(@slurp) {
    my ($class,@args)=@slurp;
    $Frame=$class->get_frame(@args);

  };

# ---   *   ---   *   ---
# go through chks

sub roll($self) {

  my @out=();

  for my $d(@{$self->{rolls}}) {
    push @out,$d->roll();

  };

  return @out;

};

# ---   *   ---   *   ---

sub cast($self,$actor) {

  for my $key(qw(

    on_any

    on_self
    on_touch
    on_target
    on_area

    on_ally
    on_foe

  )) {

    my $proc=$self->{$key};

    $proc->($self,$actor)
    if $proc ne $NOOP;

  };

};

# ---   *   ---   *   ---

sub new($class,%O) {

  $class->defnit(\%O);

  my $rolls=$O{rolls};
  for my $d(@$rolls) {
    RPG::Dice->fetch(\$d);

  };

  my $self=bless {%O},$class;

  return $self;

};

# ---   *   ---   *   ---
# test

my $lw=RPG::Spell->new(

  name    => 'Last whisper',
  school  => 'Hatred',

  elems   => [qw(evil annihilate sight)],
  reqs    => [qw(blackened disciple)],

  desc    => (join q[ ],qw(

    This vociferation reveals the
    positions of enemies and grants
    1d8 of bonus damage for the next
    three attacks

  )),

);

my $A={name=>'Hunter'};
$lw->cast($A);

# ---   *   ---   *   ---
1; # ret
