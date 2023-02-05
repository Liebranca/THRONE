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

my $church=RPG::Static->new(

  size   => '3x4',
  co     => [1,1],

  sprite => q[

   : ^ ;
   :/_\;
   :|_|;
   :|H|;

  ],

);

my $char=RPG::Actor->new();

# ---   *   ---   *   ---

print "\e[2J\e[0H";

my $panic=10;
while($panic--) {

  print "\e[0H";

  $church->{co}->{at}->prich();

  $char->move_to(2,5);

  usleep(100000);

};

# ---   *   ---   *   ---
1; # ret
