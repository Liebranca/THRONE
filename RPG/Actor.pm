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

# ---   *   ---   *   ---
# ROM

  sub Frame_Vars($class) {return {

    -autoload=>[qw(
      member

    )],

    name => 'Circle of Four',

  }};

# ---   *   ---   *   ---
# constructor

sub member($class,$frame,$map,$co,%O) {

  # religion
  $O{faith}//=0;
  $O{hatred}//=0;

  # combat
  $O{grit}//=4;
  $O{flair}//=4;
  $O{temper}//=2;

  # misc
  $O{charm}//=1;
  $O{wit}//=1;

  # coordinates
  $O{co}=GF::Vec4->nit(@$co);
  $O{cell}=undef;

  # graphics
  $O{sprite}//=$GF::Icon::PAIN_S0;
  $O{frame}=$frame;

  $O{at}=$map;

  my $self=bless {%O},$class;
  $self->move(0,0);

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

    $cell->occupy($self->{sprite});

    $self->{cell}=$cell;
    $old->free() if $old ne $cell;

    $self->{co}=$cell->{co};
    ($x,$y)=@{$self->{co}};

    push @out,{
      proc => 'mvcur',
      args => [0,20],

      ct   => "CHAR moves to [$x,$y]",

    };

  };

  return @out;

};

# ---   *   ---   *   ---
1; # ret
