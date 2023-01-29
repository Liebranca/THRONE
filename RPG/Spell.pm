#!/usr/bin/perl
# ---   *   ---   *   ---
# SPELL
# Describes base format
# for spell instances
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---

package RPG::Spell;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/THRONE/';
  use parent 'RPG::St';

  use lib $ENV{'ARPATH'}.'/lib/sys';
  use Style;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  sub Reg_Vars($class) {return [

    q(VOCIFERATE),

    q(In the),
      [qw(.degree 'third')],

    q(degree, I cast unto thee:),
      [qw(.name 'Transfigurate')],

    q(, of the School of),
      [qw(.school 'Raw Lytheknics')],

    q(! It is composed of),
      [qw(.elements
        'nothing'
        'nothing'
        'nothing'

      )],

    q(, and it shall),
      [qw(.desc 'endlessly reform!')]

  ]};

# ---   *   ---   *   ---

sub nit($class,%O) {

};

# ---   *   ---   *   ---

RPG::Spell->subclan(

  q[.degree]=>[
    q(In the),
    [qw('eleventh')],

  ],

  q[.name]=>[
    q(degree, I cast),
    [qw('Irkalla')],

  ],

  q[.school]=>[
    q(, of the School of),
    [qw('Hatred')],

  ],

  q[.elements]=>[
    q(... it is composed of),
    [qw('evil' 'sight' 'annihilate')]

  ],

  q[.desc]=>[
    q(, and it will),
    [qw('turn your bones to ash!')],

  ],

);

# ---   *   ---   *   ---
1; # ret
