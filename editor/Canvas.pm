#!/usr/bin/perl
# ---   *   ---   *   ---
# EDITOR CANVAS
# A rect of choices!
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package Canvas;

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
  use lib $ENV{'ARPATH'}.'/THRONE/';

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# cstruc

sub new($class,%O) {

  # defaults
  $O{pos} //= [0,0];
  $O{dim} //= '16x16';
  $O{buf} //= [];

  # get NxN
  my ($sz_x,$sz_y)=split 'x',$O{dim};


  # make ice
  my $self=bless {

    sel   => GF::Vec4->nit(0,0),
    pos   => GF::Vec4->nit(@{$O{pos}}),

    dim   => [[0,$sz_x],[0,$sz_y]],

    buf   => $O{buf},
    cchar => 0,
    cpos  => 0,

  },$class;


  $self->{buf}=[map {q[ ]} 0..($sz_x*$sz_y)-1]
  if ! @{$self->{buf}};

  return $self;

};

# ---   *   ---   *   ---
# outs lists of draw commands

sub draw($self,$highlight) {

  my @ar=($highlight)
    ? ($self->draw_buf(),$self->draw_cchar())
    : ($self->draw_buf())
    ;

  return @ar;

};

# ---   *   ---   *   ---
# ^puts buf on screen

sub draw_buf($self) {

  my $sz     = $self->{dim}->[0]->[1];
  my $buf    = $self->{buf};

  my ($x,$y) = @{$self->{pos}};

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

sub draw_cchar($self) {

  $self->get_cchar();

  return (

    # print cchar with color
    $self->draw_cursor(),

    # ^color off
    {proc => 'bnw'},

  );

};

# ---   *   ---   *   ---
# shorthand for getting
# cursor on canvas

sub draw_cursor($self) {

  my ($x,$y)   = @{$self->{pos}};
  my ($dx,$dy) = @{$self->{sel}};

  my $mvcur={
    proc=>'mvcur',
    args=>[$x+$dx,$y+$dy],

  };

  my $c=$self->{cchar};

  my $color={
    proc => 'color',
    args => [0x30],

    ct   => descape($c),

  };

  return ($mvcur,$color);

};

# ---   *   ---   *   ---
# ^get char under cursor

sub get_cchar($self) {

  my $i        = $self->get_cpos();

  my $limit    = int @{$self->{buf}};
  my $c        = $self->{buf}->[$i];

  if($i>=$limit) {
    $c=q[ ];

  };

  $self->{cchar}=$c;

};

# ---   *   ---   *   ---
# ^get cursor position

sub get_cpos($self) {

  my ($x,$y)   = @{$self->{pos}};
  my ($dx,$dy) = @{$self->{sel}};

  my $sz       = $self->{dim}->[0]->[1];
  my $i        = $dx+($dy*$sz);

  $self->{cpos}=$i;

  return $i;

};

# ---   *   ---   *   ---
# clears the table without
# a direct screen clear

sub clear($self) {

  my $sz     = $self->{dim}->[0]->[1];
  my $i      = 0;

  my ($x,$y) = @{$self->{pos}};

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
1; # ret
