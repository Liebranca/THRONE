#!/usr/bin/perl
# ---   *   ---   *   ---
# TEST SIM
# Where we try things out

# ---   *   ---   *   ---
# deps

package Tests::Sim;

  use v5.36.0;
  use strict;
  use warnings;

  use Time::HiRes qw(usleep);

  use Readonly;
  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys/';
  use Style;

  use lib $ENV{'ARPATH'}.'/lib/';
  use lib $ENV{'ARPATH'}.'/THRONE/';

  use RPG::Cell;

  use RPG::Static;
  use RPG::Actor;

# ---   *   ---   *   ---
# nits

my $west=RPG::Cell->new(

  'TEST-0000',

  name => 'Western Test',
  co   => [0,0],

);

my $east=RPG::Cell->new(

  'TEST-0001',

  name => 'Eastern Test',
  co   => [1,0],

);

# ---   *   ---   *   ---

my $tree=RPG::Static->new(

  name   => 'Tree',

  size   => '3x4',
  pos    => [1,1],

  cell   => $east,

  sprite => q[

   : ^ ;
   :/|\;
   :/|\;
   : | ;

  ],

);

# ---   *   ---   *   ---
# behaviours

  Readonly our $BE_DOOR=>{

    on_touch => sub ($self,$other) {
      $other->{space}->array_door_to($east,[0,7]);

    },

  };

# ---   *   ---   *   ---

my $char=RPG::Actor->new(

  cell   => $west,
  pos    => [1,0],

);

my $door=RPG::Static->new(

  cell   => $west,
  pos    => [7,0],

  sprite => q[

    :D;

  ],

  behave => $BE_DOOR,

);

# ---   *   ---   *   ---

# TODO:
#
# ~ char goal eq get wood
# ~ \-->looks for wood source
# ~ .  \-->gets nearest map with trees
# ~ .  \-->moves to map
#
# ~ \-->approaches nearest tree
# ~ \-->chops
#
# ~ \-->char goal eq store wood
# ~ .  \-->looks for storage
# ~ .  .  \-->gets nearest map with safe
# ~ .  .  \-->moves to map
#
# ~ \-->rept

print "\e[2J\e[0H";
my $dst=$door;

my $panic=20;
while($panic--) {

  my $cell=$char->{space}->{cell};

  print "\e[0H";

  $cell->prich();

  if($dst && ! $char->walk_to($dst)) {
    $char->touch($dst);
    $dst=undef;

  };


  usleep(100000);

};

# ---   *   ---   *   ---
1; # ret
