#!/usr/bin/perl
# ---   *   ---   *   ---
# MARAUDER
# Attempts to parse a
# magic *.rom file
#
# TEST FILE
# jmp EOF for bits
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package main;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys/';
  use Style;

  use lib $ENV{'ARPATH'}.'/THRONE/';
  use RPG::Magic;

# ---   *   ---   *   ---
# ROM

  Readonly my $ROMD=>
    $ENV{'ARPATH'} . '/THRONE/ROM/Runes/';

# ---   *   ---   *   ---
# the bit

RPG::Magic->fread("${ROMD}Basic");

# ---   *   ---   *   ---
