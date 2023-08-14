#!/usr/bin/perl
# ---   *   ---   *   ---
# RPG ATTR
# Number salad
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package RPG::Attr;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_vars);
  use List::Util qw(min max);

  use lib $ENV{'ARPATH'}.'/sys/';
  use Style;

  use lib $ENV{'ARPATH'}.'/THRONE/';
  use RPG::Bar;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# cstruc

sub new($class,%O) {

  # defaults
  $O{min}  //= 0;
  $O{base} //= 4;

  $O{i}    //= $O{base};
  $O{bar}  //= undef;

  $O{eff}  //= {};


  # make ice
  my $self=bless {

    i      => $O{i},
    min    => $O{min},

    base   => $O{base},
    total  => $O{base},

    bar    => undef,

    eff    => {},

  },$class;


  # create display if req
  my $bar=undef;

  if($O{bar}) {

    $self->{bar}=RPG::Bar->new(
      $self,%{$O{bar}}

    );

  };

  $self->add_modifiers(%{$O{eff}});

  return $self;

};

# ---   *   ---   *   ---
# ^bat

sub table($class,$elems) {

  return {map {
    my $cstruc=$elems->{$ARG};
    $ARG=>$class->new(%$cstruc);

  } keys %$elems};

};

# ---   *   ---   *   ---
# register effect

sub add_modifiers($self,%src) {

  my $x=0;

  map {
    $self->{eff}->{$ARG}=$src{$ARG};

  } keys %src;


  $self->apply_modifiers();

};

# ---   *   ---   *   ---
# ^undo

sub clear_modifiers($self,@src_id) {

  @src_id=keys %{$self->{eff}}
  if ! @src_id;

  map {
    delete $self->{eff}->{$ARG};

  } @src_id;


  $self->apply_modifiers();

};

# ---   *   ---   *   ---
# ^get modifier present

sub is_modified($self,@src_id) {

  @src_id=keys %{$self->{eff}}
  if ! @src_id;

  return grep {
    exists $self->{eff}->{$ARG}

  } @src_id;

};

# ---   *   ---   *   ---
# ^get flat X for all mods

sub get_modifiers($self) {

  my $out=0;

  map {
    $out+=$self->{eff}->{$ARG}

  } keys %{$self->{eff}};


  return $out;

};

# ---   *   ---   *   ---
# ^add to total

sub apply_modifiers($self) {

  my $x=$self->get_modifiers();

  $self->{total}=$self->{base}+$x;
  $self->mod_current($x);

  $self->{bar}->update_animar()
  if $self->{bar};

};

# ---   *   ---   *   ---
# add to base value

sub mod_base($self,$x=1) {
  $self->{base}+=$x;
  $self->on_update_base();

};

# ---   *   ---   *   ---
# ^set base value

sub set_base($self,$x) {
  $self->{base}=$x;
  $self->on_update_base();

};

# ---   *   ---   *   ---
# ^epilogue, recalcs total

sub on_update_base($self) {
  $self->apply_modifiers();

};

# ---   *   ---   *   ---
# add to current value

sub mod_current($self,$x=1) {
  $self->{i}+=$x;
  $self->on_update_current();

};

# ---   *   ---   *   ---
# ^set current value

sub set_current($self,$x) {
  $self->{i}=$x;
  $self->on_update_current();

};

# ---   *   ---   *   ---
# ^epilogue, applies caps
# and procs

sub on_update_current($self) {

  $self->{i}=max(

    $self->{min},

    min(
      $self->{i},
      $self->{total}

    ),

  );

  $self->{bar}->update_rate()
  if $self->{bar};

};

# ---   *   ---   *   ---
# runs animated display

sub draw($self) {
  return $self->{bar}->update();

};

# ---   *   ---   *   ---
1; # ret
