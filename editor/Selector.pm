#!/usr/bin/perl
# ---   *   ---   *   ---
# EDITOR SELECTOR
# Picks a char from table
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package Selector;

  use v5.36.0;
  use strict;
  use warnings;

  use utf8;
  use Readonly;

  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;

  use Arstd::Int;
  use Arstd::String;
  use Arstd::Path;

  use lib $ENV{'ARPATH'}.'/lib/';

  use Lycon;

  use Lycon::Ctl;
  use Lycon::Loop;
  use Lycon::Gen;

  use GF::Mode::ANSI;

  use lib $ENV{'ARPATH'}.'/THRONE/';

# ---   *   ---   *   ---
# app packages

  use lib dirof(__FILE__);
  use Canvas;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.4;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly my $CHARS_N=>[
    (0x0020..0x007E),
    (0x0100..0x0119),
    (0x017F..0x01FF),

  ];

  Readonly my $CHARS  => [map {
    chr($ARG)

  } @$CHARS_N];

  Readonly my $RESET=>{

    proc => 'mvcur',
    args => [0,0],

  };

# ---   *   ---   *   ---
# GBL

  our $Cache={

    terminate => 0,
    refresh   => 0,

    # char pick
    table => Canvas->new(
      buf=>$CHARS,

    ),

    # ^draw color pick
    colors => Canvas->new(
      pos=>[16,0]

    ),

  };

# ---   *   ---   *   ---
# ^nits Lycon-dependent state

sub kick() {

  $Cache->{colors}->{buf}=[map {

    graphics()->color($ARG)
  . q[$]

  . graphics()->bnw()

  } 0..0xFF];

  $Cache->{colors}->{sel}->[0]=0x7;
  $Cache->{colors}->get_cchar();

};

# ---   *   ---   *   ---
# generate control transfers

Lycon::Ctl::register_xfers(

  call=>sub {
    $Cache->{terminate}=0;

  },

  loop=>sub {
    ! $Cache->{terminate};

  },

);

# ---   *   ---   *   ---
# keys used by module

Lycon::Ctl::register_events(

  # quit to main
  tab=>[sub {
    $Cache->{terminate}=1;

  },0,0],

  # select FG color
  left=>[sub {
    $Cache->{fg_color}--;
    $Cache->{fg_color}&=0xF;

  },0,0],

  right=>[sub {
    $Cache->{fg_color}++;
    $Cache->{fg_color}&=0xF;

  },0,0],

  # select BG color
  down=>[sub {
    $Cache->{bg_color}--;
    $Cache->{bg_color}&=0xF;

  },0,0],

  up=>[sub {
    $Cache->{bg_color}++;
    $Cache->{bg_color}&=0xF;

  },0,0],

  # movement keys
  Lycon::Gen::wasd(
    $Cache->{table}->{sel},
    $Cache->{table}->{dim},

  ),

  # movement keys
  Lycon::Gen::arrows(
    $Cache->{colors}->{sel},
    $Cache->{colors}->{dim},

  ),

);

# ---   *   ---   *   ---
# get fg and bg colors as
# single byte

sub get_color() {
  return $Cache->{colors}->{cpos};

};

# ---   *   ---   *   ---
# frame update

sub draw() {

  my @req=(! $Cache->{terminate})

    ? ($Cache->{table}->draw(1),
       $Cache->{colors}->draw(1),

      )

    : ($Cache->{table}->clear(),
       $Cache->{colors}->clear(),

      )

    ;

  drawcmd(@req);

};

# ---   *   ---   *   ---
1; # ret
