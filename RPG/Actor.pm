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
  use Vec4;

  use lib $ENV{'ARPATH'}.'/THRONE/';
  use RPG::Cell;

# ---   *   ---   *   ---
# constructor

sub nit($class,$frame,$co,%O) {

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
  $O{co}=Vec4->nit(@$co);
  $O{cell}=undef;

  # graphics
  $O{sprite}//='$';
  $O{frame}=$frame;

  my $actor=bless {%O},$class;

  return $actor;

};

# ---   *   ---   *   ---

sub move($self,$dir) {

  my $cell=$self->{cell};
  $cell->free();

  $cell=$cell->getneigh($dir);
  $cell->occupy($self);

  $self->{cell}=$cell;

};

# ---   *   ---   *   ---
1; # ret
