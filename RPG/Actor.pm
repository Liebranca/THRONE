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
  use Chk;

  use lib $ENV{'ARPATH'}.'/lib/';
  use lib $ENV{'ARPATH'}.'/THRONE/';

  use RPG::Space;
  use RPG::Social;

  use parent 'St';

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.3;#b
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
  $O{social} //= {};

  my $space=RPG::Space->array(

    pos    => $O{pos},
    sprite => $O{sprite},

    size   => $O{size},
    cell   => $O{cell},

    behave => $O{behave},

  );

  # make new
  my $self=bless {

    name    => $O{name},
    space   => $space,

  },$class;

  return $self;

};

# ---   *   ---   *   ---
# change position, absolute

sub teleport($self,$nx,$ny) {

  my $space  = $self->{space};
  my ($x,$y) = $space->array_teleport($nx,$ny);

  my $new    = $self->{space}->origin();

  return ! $new->{co}->equals([$x,$y,0,0]);

};

# ---   *   ---   *   ---
# ^relative to current

sub walk($self,$dx,$dy) {

  my $space  = $self->{space};
  my ($x,$y) = $space->array_walk($dx,$dy);

  my $new    = $self->{space}->origin();

  return ! $new->{co}->equals([$x,$y,0,0]);

};

# ---   *   ---   *   ---
# create and follow path to destination

sub walk_to($self,$dst) {

  my $out    = 0;
  my ($x,$y) = $self->point_or_object($dst);

  if(! $self->arrived($x,$y)) {

    if(! $self->follow_path()) {
      $out=1;

    } else {
      $out|=2;

    };

  };

  return $out;

};

# ---   *   ---   *   ---
# get nearest neighboring tile

sub near_nof($self,$other) {

  my $cur  = $self->{space}->origin();
  my @walk = $other->{space}->array_nof();

  my ($p,$i)=$cur->{co}->nearest(
    map {$ARG->{co}} @walk

  );

  return @$p;

};

# ---   *   ---   *   ---
# solve movement target

sub point_or_object($self,$other) {

  my @out   = ();
  my $path  = $self->{q[$cpath]};

  my $isref = 0<length ref $other;

  if($isref && ! $path) {
    @out=$self->near_nof($other);

  } elsif($path && @$path) {
    @out=@{$path->[-1]->{co}};

  } elsif(!$isref) {
    @out=@$other;

  };

  return @out;

};

# ---   *   ---   *   ---
# go to next point in

sub follow_path($self) {

  my $path  = $self->{q[$cpath]};
  my $point = shift @$path;

  my $cur   = $self->{space}->origin();
  my $delta = $point->{co}->minus($cur->{co});

  return $self->walk(@{$delta}[0..1]);

};

# ---   *   ---   *   ---
# at end/start of path

sub arrived($self,$x,$y) {

  my $out  = 0;

  my $path = $self->{q[$cpath]};
  my $cur  = $self->{space}->origin();

  # last point popped
  if($path && ! @$path) {
    delete $self->{q[$cpath]};
    $out=1;

  # dst reached
  } else {
    $self->path_to($x,$y) if ! $path;

  };

  return $out;

};

# ---   *   ---   *   ---
# do the dijks

sub path_to($self,$x,$y) {

  my $cell = $self->{space}->{cell};

  # TODO:
  # throw if ! $cell->in_bounds($x,$y);

  my $dst  = $cell->tile($x,$y);
  my $src  = $self->{space}->origin();

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

  $self->{q[$cpath]}=\@path;

  shift  @path;
  return @path;

};

# ---   *   ---   *   ---

sub social($self,$fn,@args) {

  my ($ctx,$act,$feel)=$self->{persona}->$fn(@args);

  say "On $ctx: $self->{name} chooses $act($feel)";

};

# ---   *   ---   *   ---
# interaction shorthand

sub touch($self,$other,@args) {

  return $other->{space}->iract(
    'on_touch',$self,@args

  );

};

# ---   *   ---   *   ---
1; # ret
