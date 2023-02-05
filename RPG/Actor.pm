#!/usr/bin/perl
# ---   *   ---   *   ---
# RPG ACTOR
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
  use lib $ENV{'ARPATH'}.'/THRONE/';

  use RPG::Co;
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

    name=>'Circle of Four',

  }};

# ---   *   ---   *   ---
# constructor

sub new($class,%O) {

  # defaults
  $O{name}   //= 'Vagabond';
  $O{size}   //= '1x1';
  $O{sprite} //= q[
    :$;

  ];

  $O{atid}   //= undef;

  $O{co}     //= [0,0];
  $O{social} //= {};

  my $coar=RPG::Co->array(

    $O{co},
    $O{sprite},

    $O{size},
    $O{atid}

  );

  # make new
  my $self=bless {

    name    => $O{name},
    co      => $coar,

  },$class;

  return $self;

};

# ---   *   ---   *   ---
# selfex

sub move($self,$dx,$dy) {

  my $co     = $self->{co};
  my ($x,$y) = $co->array_move($dx,$dy);

  my $new    = $self->{co}->origin();

  return !$new->{co}->equals([$x,$y,0,0]);

};

# ---   *   ---   *   ---
# calculate path to destination

sub move_to($self,$x,$y) {

  my $cur=$self->{co}->origin();
     $cur=$cur->{co};

  return if $cur->equals([$x,$y,0,0]);

  my @path=(!exists $self->{q[$cpath]})
    ? $self->path_to($x,$y)
    : @{$self->{q[$cpath]}}
    ;

  if(@path) {
    my $point = shift @path;
    my $delta = $point->{co}->minus($cur);
    my $moved = $self->move(@{$delta}[0..1]);

    @path     = $self->path_to($x,$y)
    if ! $moved;

    $self->{q[$cpath]}=\@path;

  } else {
    delete $self->{q[$cpath]};

  };

};

# ---   *   ---   *   ---
# do the dijks

sub path_to($self,$x,$y) {

  my $at   = $self->{co}->{at};

  # TODO:
  # throw if !$at->in_bounds($x,$y);

  my $dst  = $at->cell($x,$y);
  my $src  = $self->{co}->origin();

  my @path = ($src);

  while($dst ne $path[-1]) {

    my $cur  = $path[-1];
    my @walk = $cur->get_nwalk();

    # get closest to dst out of
    # walkable neighbors
    my ($p,$i)=$dst->{co}->nearest(
      map {$ARG->{co}} @walk

    );

    my $near=$walk[$i];
    push @path,$near;

  };

  shift  @path;
  return @path;

};

# ---   *   ---   *   ---

sub social($self,$fn,@args) {

  my ($ctx,$act,$feel)=$self->{persona}->$fn(@args);

  say "On $ctx: $self->{name} chooses $act($feel)";

};

# ---   *   ---   *   ---
1; # ret
