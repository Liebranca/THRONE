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
  use RPG::Magic;

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

    -autoload=>[qw()],

  }};

  Readonly our $DEFAULTS=>{

    # id
    name   => 'Transfigurate',
    school => 'Raw Lytheknics',

    # score
    degree => 3,

    area   => 0,
    range  => 0,
    dur    => 1,

    elems  => [],
    eff    => [],
    reqs   => [],

    dice   => '1d4',

    # lore
    desc   => (join q[ ],qw(

      This vociferation
      shall endlessly
      reform

    )),

  };

# ---   *   ---   *   ---
# GBL

  my $Icemap = {};
  my $Frame  = RPG::Spell->get_frame();

# ---   *   ---   *   ---
# IO

  sub import(@slurp) {
    my ($class,@args)=@slurp;
    $Frame=$class->get_frame(@args);

  };

# ---   *   ---   *   ---
# cstruc

sub new($class,%O) {

  # defaults
  $class->defnit(\%O);

  # ^lis
  my $eff=$O{eff};


  # get dice
  RPG::Dice->fetch(\$O{dice});


  # get magic effects from names
  @$eff=map {
    RPG::Magic->fetch($ARG)

  } @$eff;

  # ^handle inheritance
  unshift @$eff,map {
    @{$class->fetch($ARG)->{eff}};

  } @{$O{elems}};


  # ^make ice
  my $self=bless {%O},$class;

  # ^register
  ! exists $Icemap->{$O{name}}
  or RPG::Magic::throw_redecl($O{name});

  $Icemap->{$O{name}}=$self;


  return $self;

};

# ---   *   ---   *   ---
# ^get existing

sub fetch($class,$name) {

  my $out=$Icemap->{$name}
  or RPG::Magic::throw_no_ice($name);

  return $out;

};

# ---   *   ---   *   ---
# ^bat

sub table($class,@ar) {

  return {map {
    $ARG=>$class->fetch($ARG)

  } @ar};

};

# ---   *   ---   *   ---
# unleash arcana

sub cast($self,$dst,$src) {

  # make struc out of cast
  my $M=RPG::Magic->charge(

    $self,

    $dst,
    $src,

    $self->{dice}->roll()

  );

  # ^pass struc through each effect
  map {
    $ARG->{crux}->($ARG,$M);
    push @{$M->{prev}},$ARG;

  } @{$self->{eff}};


  return $M;

};

# ---   *   ---   *   ---
1; # ret
