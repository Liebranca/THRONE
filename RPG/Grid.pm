#!/usr/bin/perl
# ---   *   ---   *   ---
# RPG GRID
# Subdivided plane
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package RPG::Grid;

  use v5.36.0;
  use strict;
  use warnings;

  use English qw(-no_match_vars);
  use Readonly;

  use lib $ENV{'ARPATH'}.'/lib/sys/';
  use Style;

  use parent 'St';

  use lib $ENV{'ARPATH'}.'/THRONE/';

  use RPG::Cell;
  use RPG::Actor;

# ---   *   ---   *   ---
# ROM

  sub Frame_Vars($class) {return {

    -sz_x=>8,
    -sz_y=>8,

    -cells=>undef,
    -actors=>undef,

    -autoload=>[qw(

      at draw new_actor

    )],

  }};

# ---   *   ---   *   ---
# constructor

sub nit(

  # implicit
  $class,$frame,

  # actual
  $sz_x,$sz_y

) {

  my $cells=bless [],$class;
  my $actors=RPG::Actor->new_frame();

  $frame->{-sx_x}=$sz_x;
  $frame->{-sx_y}=$sz_y;

  for my $y(0..$sz_y-1) {

    my $row=$cells->[$y]=[];

    for my $x(0..$sz_x-1) {
      push @$row,RPG::Cell->nit($frame,$x,$y);

    };

  };

  $frame->{-cells}=$cells;
  $frame->{-actors}=$actors;

  return $cells;

};

# ---   *   ---   *   ---

sub at($class,$frame,$vec) {

  my $cells=$frame->{-cells};
  return $cells->[$vec->[1]]->[$vec->[0]];

};

# ---   *   ---   *   ---

sub draw($class,$frame) {

  my $cells=$frame->{-cells};
  my $mess="\e[0H";

  for my $line(@$cells) {

    $mess.=(join $NULLSTR,
      map {$ARG->get_sprite()} @$line

    )."\n";

  };

  return say $mess;

};

# ---   *   ---   *   ---

sub new_actor(

  # implicit
  $class,$frame,

  # actual
  $co,
  %STATS

) {

  my $actors=$frame->{-actors};
  my $act=$actors->nit($co,%STATS);

  $act->{cell}=$frame->at($act->{co});
  $act->move('self');

  return $act;

};

# ---   *   ---   *   ---
1; # ret
