#!/usr/bin/perl
# ---   *   ---   *   ---
# RPG STATIC
# A thing that doesn't move
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package RPG::Static;

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

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.2;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  sub Frame_Vars($class) {return {

    -autoload=>[qw(

    )],

    name=>'Barrels & Crates',

  }};

# ---   *   ---   *   ---

sub new($class,%O) {

  # defaults
  $O{name}   //= 'Barrel';
  $O{size}   //= '1x1';

  $O{sprite} //= q[
    :U;

  ];

  $O{atid}   //= undef;

  $O{co}     //= [0,0];

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
1; # ret
