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

  use lib $ENV{'ARPATH'}.'/lib/';

  use Lycon;

  use Lycon::Ctl;
  use Lycon::Loop;
  use Lycon::Gen;

  use GF::Mode::ANSI;

  use lib $ENV{'ARPATH'}.'/THRONE/';

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.3;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly my $CHARS_N=>[
    (0x0020..0x007E),
    (0x0100..0x0119),
    (0x017F..0x01FF),

  ];

  Readonly my $CHARS=>[map {chr($ARG)} @$CHARS_N];

  Readonly my $RESET=>{

    proc => 'mvcur',
    args => [0,0],

  };

# ---   *   ---   *   ---
# GBL

  our $Cache={

    terminate => 0,
    refresh   => 0,

    table     => {

      sel   => GF::Vec4->nit(0,0),
      pos   => GF::Vec4->nit(0,0),

      dim   => [[0,16],[0,16]],

      buf   => $CHARS,
      cchar => q[ ],

    },

    fg_color  => 0x7,
    bg_color  => 0x0,

  };

# ---   *   ---   *   ---
# get fg and bg colors as
# single byte

sub get_color() {

  return
    ($Cache->{fg_color} << 0)
  | ($Cache->{bg_color} << 4)
  ;

};

# ---   *   ---   *   ---
# draw command for selection panel

sub draw_table() {

  return (
    draw_canvas($Cache->{table}),
    draw_highlighted($Cache->{table}),

  );

};

# ---   *   ---   *   ---
# ^shorthand for drawing
# array of chars

sub draw_canvas($canvas) {

  my $sz     = $canvas->{dim}->[0]->[1];
  my $buf    = $canvas->{buf};

  my ($x,$y) = @{$canvas->{pos}};

  my $i=-$sz;
  $y--;

  my $cnt=int_urdiv(int @$buf,$sz);

  return map {

    $i+=$sz;
    $y++;

    my $limit = $i+($sz-1);

    $limit    = ($limit > @$buf-1)
      ? @$buf-1
      : $limit
      ;

    my @row   = @{$buf}[$i..$limit];
    my $diff  = $sz - ($limit-$i);

    push @row,(q[ ]) x $diff;

    {

      proc => 'mvcur',
      args => [$x,$y],

      ct   => (join $NULLSTR,@row),

    };

  } 0..$cnt-1;

};

# ---   *   ---   *   ---
# ^ivs color on selected char

sub draw_highlighted($canvas) {

  get_highlighted($canvas);

  return (

    # print cchar with color
    draw_cursor($canvas),

    # ^color off
    {proc => 'bnw'},

  );

};

# ---   *   ---   *   ---
# shorthand for getting
# cursor on canvas

sub draw_cursor($canvas) {

  my ($x,$y)   = @{$canvas->{pos}};
  my ($dx,$dy) = @{$canvas->{sel}};

  my $mvcur={
    proc=>'mvcur',
    args=>[$x+$dx,$y+$dy],

  };

  my $c=$canvas->{cchar};

  my $color={
    proc => 'color',
    args => [0x30],

    ct   => descape($c),

  };

  return ($mvcur,$color);

};

# ---   *   ---   *   ---
# ^get char under cursor

sub get_highlighted($canvas) {

  my $i        = get_curpos($canvas);

  my $limit    = int @{$canvas->{buf}};
  my $c        = $canvas->{buf}->[$i];

  if($i>=$limit) {
    $c=q[ ];

  };

  $canvas->{cchar}=$c;

};

# ---   *   ---   *   ---
# ^get cursor position

sub get_curpos($canvas) {

  my ($x,$y)   = @{$canvas->{pos}};
  my ($dx,$dy) = @{$canvas->{sel}};

  my $sz       = $canvas->{dim}->[0]->[1];
  my $i        = $dx+($dy*$sz);

  return $i;

};

# ---   *   ---   *   ---
# clears the table without
# a direct screen clear

sub clear_canvas($canvas) {

  my $sz     = $canvas->{dim}->[0]->[1];
  my $i      = 0;

  my ($x,$y) = @{$canvas->{pos}};

  $y--;

  return map {

    $y++;

    { proc => 'mvcur',
      args => [$x,$y],

      ct   => q[ ] x ($sz+1),

    };

  } 0..$sz-1;

};

# ---   *   ---   *   ---
# keeps this package in control

sub rept(@beq) {

  my $Q=get_module_queue();
  $Q->skip(\&rept,@beq) if ! $Cache->{terminate};

  on_refresh();
  map {$ARG->();} @beq;

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

  Lycon::Loop::transfer();

};

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

    tap=>1,
    hel=>1,
    rel=>0,

  ),

);

# ---   *   ---   *   ---
# frame update

sub on_refresh() {

  my @req=(! $Cache->{terminate})
    ? draw_table()
    : clear_canvas($Cache->{table}),
    ;

  drawcmd(@req);

};

# ---   *   ---   *   ---
1; # ret
