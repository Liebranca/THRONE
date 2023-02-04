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
  $O{sprite} //= '$';

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

  my @out    = ();
  my $co     = $self->{co};

  my ($x,$y) = $co->array_move($dx,$dy);

  push @out,{
    proc => 'mvcur',
    args => [0,20],

    ct   => "$self->{name} moves to [$x,$y]",

  };

  return @out;

};

# ---   *   ---   *   ---

sub social($self,$fn,@args) {

  my ($ctx,$act,$feel)=$self->{persona}->$fn(@args);

  say "On $ctx: $self->{name} chooses $act($feel)";

};

# ---   *   ---   *   ---
# test

use utf8;

my $house=RPG::Actor->new(

  size   => '3x4',

  sprite =>q[

   : ^ ;
   :/_\;
   :|_|;
   :|H|;

  ],

);

$house->move(1,2);
$house->move(0,-1);

$house->{co}->{at}->prich();

# ---   *   ---   *   ---
1; # ret
