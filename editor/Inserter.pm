#!/usr/bin/perl
# ---   *   ---   *   ---
# EDITOR INSERTER
# Lets you write
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package Inserter;

  use v5.36.0;
  use strict;
  use warnings;

  use utf8;
  use Readonly;

  use English qw(-no_match_vars);
  use List::Util qw(min);

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
  use Selector;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

# ---   *   ---   *   ---
# GBL

  our $Cache={

    canvas=>Canvas->new(
      pos=>[16,9],

    ),

    ti=>{

      fname  => dirof(__FILE__) . '/ti',
      buf    => $NULLSTR,

      lshift => 0,
      ralt   => 0,

    },

    cmode=>0,

  };

# ---   *   ---   *   ---
# show char selection screen

sub call_selector() {

  drawcmd(
    $Cache->{canvas}->draw(0)

  );

  ctl_switch('Selector',\&draw);

};

# ---   *   ---   *   ---
# generate control transfers

Lycon::Ctl::register_xfers(

  call=>sub {
    $Cache->{terminate}=0;

  },

  loop=>sub {
    proc_input();
    return ! $Cache->{terminate};

  },

  ret => sub {
    $Cache->{cmode}=0;

  },

  switch => sub ($pkg) {

    state $tab={
      'Selector'=>1,

    };

    $Cache->{cmode}=$tab->{$pkg};

  },

);

# ---   *   ---   *   ---
# keys used by module

Lycon::Ctl::register_events(

  # quit to main
  escape=>[sub {
    $Cache->{terminate}=1;

  },0,0],

  # mode switches
  tab => [\&call_selector,0,0],

  # movement keys
  Lycon::Gen::arrows(
    \$Cache->{canvas},'sel','dim'

  ),

  # text input enabled
  Lycon::Gen::TI($Cache->{ti}),

);

# ---   *   ---   *   ---
# pastes input buff into canvas

sub proc_input() {

  my $ibuff=$Cache->{ti}->{buf};
  return if ! $ibuff;

  map {
    putmove($ARG,$Cache->{canvas})

  } split $NULLSTR,$ibuff;

  $Cache->{ti}->{buf}=$NULLSTR;

};

# ---   *   ---   *   ---
# ^moves cursor to next char

sub putmove($c,$canvas) {

  my ($x,$y)   = @{$canvas->{sel}};
  my ($lx,$ly) = @{$canvas->{dim}};
     ($lx,$ly) = ($lx->[1],$ly->[1]);

  # enter
  if($c eq "\n") {
    $x  = 0;
    $y += 1 * ($y < $ly);

  # backspace
  } elsif($c eq "\b") {

    $x -= 1 * ($x > 0);

    $canvas->{sel}->[0]=$x;
    putc(' ',$canvas);

  # ^space or anything else
  } else {
    putc($c,$canvas);
    $x += 1 * ($x < $lx);

  };

  if($x >= $lx && $y < $ly) {
    $x=0;
    $y++;

  };

  $canvas->{sel}->[0]=$x;
  $canvas->{sel}->[1]=$y;

};

# ---   *   ---   *   ---
# ^put char with colors
# at current position

sub putc($c,$canvas) {

  my $i    = $canvas->get_cpos();

  my $beg  = Selector::get_color();
     $beg  = graphics()->$COLOR_F($beg);

  my $end  = graphics()->bnw();

  $canvas->{buf}->[$i]=(length $c)
    ? "$beg$c$end"
    : ' '
    ;

};

# ---   *   ---   *   ---
# puts selected on screen

sub draw_cchar() {

  return {
    proc => 'color',
    args => [0x03],

    ct   =>
      'SEL ['
    . $Selector::Cache->{table}->{cchar}

    . '] | '
    . (sprintf "%03X",ord(
        $Selector::Cache->{table}->{cchar}

    )),

  };

};

# ---   *   ---   *   ---
# ^shows selected color

sub draw_ccolor() {

  my $color=Selector::get_color();

  return {
    ct   => " | COLOR ",

  },{

    proc => $COLOR_F,
    args => [$color],

    ct   => (sprintf "%04X",$color),

  };

};

# ---   *   ---   *   ---
# draws bar at screen bottom

sub draw_ctlbar() {

  my $pos={
    proc=>'mvcur',
    args=>[0x00,0xFF],

  };

  return (

    $pos,

    draw_cchar(),
    draw_ccolor(),

    # ^color off
    {proc => 'bnw'},

  );

};

# ---   *   ---   *   ---
# frame update

sub draw($ext=undef) {

  my $cmode=(! defined $ext)
    ? $Cache->{cmode}
    : $ext
    ;

  my @req=(! $cmode)
    ? ($Cache->{canvas}->draw(1),
       draw_ctlbar()

      )

    : (draw_ctlbar())
    ;

  drawcmd(@req);

};

# ---   *   ---   *   ---
1; # ret
