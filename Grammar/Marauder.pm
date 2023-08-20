#!/usr/bin/perl
# ---   *   ---   *   ---
# MARAUDER
# Grammatically correct
# spell-casting
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package Grammar::Marauder;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/avtomat/sys/';

  use Style;
  use Chk;
  use Fmat;

  use Arstd::Array;
  use Arstd::String;
  use Arstd::Re;
  use Arstd::IO;
  use Arstd::PM;

  use lib $ENV{'ARPATH'}.'/lib/';
  use lib $ENV{'ARPATH'}.'/THRONE/';

  use Grammar;
  use Grammar::peso::std;
  use Grammar::Marauder::std;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.4;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

BEGIN {

  # beqs
  $PE_STD->use_common();
  $PE_STD->use_value();
  $PE_STD->use_eye();

  $MAR_STD->uses(qw(
    hier var roll set io fcall

  ));

  fvars('Grammar::Marauder::hier');

# ---   *   ---   *   ---
# GBL

  our $REGEX={};

# ---   *   ---   *   ---
# make parser tree

  our @CORE=qw(

    lcom

    hier io
    set var roll

    fcall

  );

# ---   *   ---   *   ---

}; # BEGIN

# ---   *   ---   *   ---
# test

my $prog=q[

rune test_a;

  in   X;

  roll base 1d4;
  var  sum  base;

  cpy  M->mag,X;

rune test_b;
  test_a 1;

];

my $M   = {mag=>0};
my $ice = Grammar::Marauder->parse($prog);

$ice->run_branch('rune::test_b',$M);

fatdump(\$M);

# ---   *   ---   *   ---
1; # ret
