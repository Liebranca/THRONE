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

    canvas=>{

      sel   => GF::Vec4->nit(0,0),
      pos   => GF::Vec4->nit(16,9),

      dim   => [[0,16],[0,16]],

      buf   => [],
      cchar => q[ ],

    },

    ti=>{

      fname  => dirof(__FILE__) . '/ti',
      buf    => $NULLSTR,

      lshift => 0,
      ralt   => 0,

    },

  };

  $Cache->{canvas}->{buf}=[(q[ ]) x (
    $Cache->{canvas}->{dim}->[0]->[1]
  * $Cache->{canvas}->{dim}->[1]->[1]

  )];

# ---   *   ---   *   ---
# keeps this package in control

sub rept(@beq) {

  my $Q=get_module_queue();
  $Q->skip(\&rept,@beq) if ! $Cache->{terminate};

  proc_input();

  on_refresh();
  map {$ARG->()} @beq;

};

# ---   *   ---   *   ---
# ^triggers control transfer

sub ctl_take(@beq) {

  $Cache->{terminate}=0;

  my $Q=get_module_queue();

  my @call = caller;

  my $pkg  = $call[0];
  my $fn   = "$pkg\::ctl_take";

  $Q->add(\&$fn);
  $Q->skip(\&rept,@beq);

  Lycon::Loop::transfer($pkg);

};

# ---   *   ---   *   ---
# keys used by module

Lycon::Ctl::register_events(

  # quit to main
  tab=>[sub {
    $Cache->{terminate}=1;

  },0,0],

  # movement keys
  Lycon::Gen::arrows(

    $Cache->{canvas}->{sel},
    $Cache->{canvas}->{dim},

    tap=>1,
    hel=>1,
    rel=>0,

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

  # enter
  if($c eq "\n") {
    $x  = 0;
    $y += $y < $ly;

  # backspace
  } elsif($c eq "\b") {

    $x -= 1 * ($x > 0);

    $canvas->{sel}->[0]=$x;
    putc(' ',$canvas);

  # ^space or anything else
  } else {
    putc($c,$canvas);
    $x++;

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

  my $i    = Selector::get_curpos($canvas);

  my $beg  = Selector::get_color();
     $beg  = graphics()->color($beg);

  my $end  = graphics()->bnw();

  $canvas->{buf}->[$i]="$beg$c$end";

};

# ---   *   ---   *   ---
# refreshes the canvas

sub draw_canvas() {

  return (
    Selector::draw_canvas($Cache->{canvas}),
    Selector::draw_highlighted($Cache->{canvas}),

  );

};

# ---   *   ---   *   ---
# frame update

sub on_refresh() {

  drawcmd(
    draw_canvas()

  );

};

# ---   *   ---   *   ---
1; # ret
