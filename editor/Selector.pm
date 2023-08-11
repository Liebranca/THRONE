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
# adds to your namespace

  use Exporter 'import';
  our @EXPORT=qw($COLOR_F);

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.5;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly our $COLOR_F=>'bitcolor';

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

    # ^color pick
    colors => Canvas->new(
      pos=>[16,0],

    ),

    colors_b => Canvas->new(
      pos=>[16,0],

    ),

    # ^currently selected
    c_color_tab => undef,

  };

  # ^foreground pick active by default
  $Cache->{c_color_tab}=$Cache->{colors};

# ---   *   ---   *   ---
# ^nits Lycon-dependent state

sub kick() {

  # foreground
  $Cache->{colors}->{buf}=[map {

    graphics()->$COLOR_F($ARG)
  . q[$]

  . graphics()->bnw()

  } 0..0xFF];

  $Cache->{colors}->{sel}->[0]=0xF;
  $Cache->{colors}->{sel}->[1]=0xF;
  $Cache->{colors}->get_cchar();


  # ^background
  $Cache->{colors_b}->{buf}=[map {

    graphics()->$COLOR_F($ARG << 8)
  . q[$]

  . graphics()->bnw()

  } 0..0xFF];

  $Cache->{colors_b}->{sel}->[0]=0x00;
  $Cache->{colors_b}->get_cchar();

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

  # switch between foreground
  # and background color pick
  LShift=>[

    0,

    # bg if held
    sub {
      $Cache->{c_color_tab}=
        $Cache->{colors_b};

    },

    # ^else fg
    sub {
      $Cache->{c_color_tab}=
        $Cache->{colors};

    }

  ],

  # movement keys
  Lycon::Gen::wasd(
    \$Cache->{table},'sel','dim'

  ),

  Lycon::Gen::arrows(
    \$Cache->{c_color_tab},'sel','dim'

  ),

);

# ---   *   ---   *   ---
# get fg and bg colors as
# single byte

sub get_color() {

  return

    ($Cache->{colors}->{cpos} << 0)
  | ($Cache->{colors_b}->{cpos} << 8)
  ;

};

# ---   *   ---   *   ---
# frame update

sub draw() {

  my @req=(! $Cache->{terminate})

    ? ($Cache->{table}->draw(1),
       $Cache->{c_color_tab}->draw(1),

      )

    : ($Cache->{table}->clear(),
       $Cache->{c_color_tab}->clear(),

      )

    ;

  drawcmd(@req);

};

# ---   *   ---   *   ---
1; # ret
