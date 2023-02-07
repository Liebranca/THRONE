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

  use RPG::Space;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.3;#b
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
  $O{name}//='Barrel';

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
1; # ret
