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

  use lib $ENV{'ARPATH'}.'/lib/';

  use Lycon;
  use Lycon::Kbd;
  use Lycon::Ctl;
  use Lycon::Loop;

  use GF::Mode::ANSI;

  use lib $ENV{'ARPATH'}.'/THRONE/';

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.2;#b
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

    table_sz  => 16,
    table_pos => [0,0],
    table_sel => [0,0],

    cchar     => q[ ],

  };

# ---   *   ---   *   ---

sub get_highlighted() {

  my ($x,$y)   = @{$Cache->{table_pos}};
  my ($dx,$dy) = @{$Cache->{table_sel}};

  my $sz       = $Cache->{table_sz};
  my $i        = $dx+($dy*$sz);

  my $limit    = @$CHARS;
  my $c        = $CHARS->[$i];

  if($i>=$limit) {
    $c=q[ ];

  };

  $Cache->{cchar}=$c;

  return $c;

};

# ---   *   ---   *   ---
# draw command for selection panel

sub draw_table() {

  my @out    = ();
  my @ar     = @$CHARS;

  my $sz     = $Cache->{table_sz};
  my $i      = 0;

  my ($x,$y) = @{$Cache->{table_pos}};

  while($i<@ar) {

    my $limit = $i+($sz-1);

    $limit    = ($limit>$#ar)
      ? $#ar
      : $limit
      ;

    my @row   = @ar[$i..$limit];
    my $diff  = $sz-($limit-$i);

    push @row,(q[ ]) x $diff;

    my $cmd={

      proc => 'mvcur',
      args => [$x,$y],

      ct   => (join $NULLSTR,@row),

    };

    push @out,$cmd;

    $i+=$sz;
    $y+=1;

  };

  return @out;

};

# ---   *   ---   *   ---
# ^ivs color on selected char

sub draw_highlighted() {

  my ($x,$y)   = @{$Cache->{table_pos}};
  my ($dx,$dy) = @{$Cache->{table_sel}};

  my $c        = get_highlighted();

  my $pos={
    proc=>'mvcur',
    args=>[$x+$dx,$y+$dy],

  };

  my $color={
    proc => 'color',
    args => [0x30],

    ct   => $c,

  };

  return (

    # move and color on
    $pos,
    $color,

    # ^color off
    {proc => 'bnw'}

  );

};

# ---   *   ---   *   ---
# keeps this package in control

sub rept() {
  my $Q=get_module_queue();
  $Q->add(\&rept) if ! $Cache->{terminate};

  on_refresh();

};

# ---   *   ---   *   ---
# ^triggers control transfer

sub ctl_take() {

  $Cache->{terminate}=0;
  my $Q=get_module_queue();
  $Q->add(\&rept);

  Lycon::Loop::transfer();

};

# ---   *   ---   *   ---
# movement keys

sub mvlft() {
  my $xref  = \$Cache->{table_sel}->[0];
  $$xref   -= 1*($$xref>0);

};

sub mvrgt() {
  my $xref  = \$Cache->{table_sel}->[0];
  $$xref   += 1*($$xref<$Cache->{table_sz}-1);

};

sub mvbak() {
  my $yref  = \$Cache->{table_sel}->[1];
  $$yref   += 1*($$yref<$Cache->{table_sz}-1);

};

sub mvfwd() {
  my $yref  = \$Cache->{table_sel}->[1];
  $$yref   -= 1*($$yref>0);

};

# ---   *   ---   *   ---
# keys used by module

Lycon::Ctl::register_events(

  tab=>[sub {
    $Cache->{terminate}=1;

  },0,0],

  w=>[\&mvfwd,\&mvfwd,0],
  a=>[\&mvlft,\&mvlft,0],
  s=>[\&mvbak,\&mvbak,0],
  d=>[\&mvrgt,\&mvrgt,0],

);

# ---   *   ---   *   ---
# frame update

sub on_refresh() {

  drawcmd(

    draw_table(),
    draw_highlighted(),

  );

};

# ---   *   ---   *   ---
1; # ret
