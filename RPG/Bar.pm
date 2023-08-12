#!/usr/bin/perl
# ---   *   ---   *   ---
# RPG BAR
# Out of mana!
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package RPG::Bar;

  use v5.36.0;
  use strict;
  use warnings;

  use English qw(-no_match_vars);
  use List::Util qw(min max);

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;
  use Arstd::Int;

  use lib $ENV{'ARPATH'}.'/lib/';
  use GF::Icon;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.2;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# cstruc

sub new($class,$attr,%O) {

  $O{color} //= 0b10000000;
  $O{anim}  //= $GF::Icon::PAIN;


  my $self=bless {

    attr   => $attr,
    color  => $O{color},

    scale  => int @{$O{anim}},

    prev   => [0,0],
    stop   => 0,

    anim   => $O{anim},
    animar => [],

    cframe => '',


  },$class;


  $self->update_animar();

  return $self;

};

# ---   *   ---   *   ---
# syncs anim array to attr

sub update_animar($self,$set=undef) {

  # new icon set passed
  if($set) {
    $self->{anim}  = $set;
    $self->{scale} = int @$set;

  };


  # ^create array of icons
  $self->{animar}=[map {
    GF::Icon->new($self->{anim}),

  } 0..$self->{attr}->{total}-1];


  # seek to current frame
  $self->update_instant();

};

# ---   *   ---   *   ---
# run anim step towards current frame

sub update($self) {

  goto SKIP if $self->{stop};

  my ($beg_idex,$beg_cent)=@{$self->{prev}};
  my ($end_idex,$end_cent)=$self->get_cent();

  my $limit = $self->{attr}->{total}-1;

  my $ar    = $self->{animar};
  my $ico   = $ar->[$beg_idex];


  # run anim for this frame
  if($beg_cent < $end_cent) {
    $ico->play_stop();

  # ^backwards when healing
  } elsif($beg_cent > $end_cent) {
    $ico->rewind();

  };


  # ^adjust current
  $beg_cent=$beg_idex+(
    $ico->{i}/$ico->{len}

  );

  $beg_idex=max(0,min(int($beg_cent),$limit));
  @{$self->{prev}}=($beg_idex,$beg_cent);

  $self->{stop}=
     ($beg_cent <= $end_cent + 0.1)
  && ($beg_cent >= $end_cent - 0.1)
  ;


SKIP:

  return $self->get_cframe();

};

# ---   *   ---   *   ---
# ^adjusts playback rate
# accto beg-end diff

sub update_rate($self) {

  my ($beg_idex,$beg_cent)=@{$self->{prev}};
  my ($end_idex,$end_cent)=$self->get_cent();

  my $rate=abs($beg_cent-$end_cent);
     $rate=max(2,min($rate,8));

  map {
    $ARG->set_rate(16-$rate);

  } @{$self->{animar}};

  $self->{stop}=0;

};

# ---   *   ---   *   ---
# ^skip animation

sub update_instant($self) {

  my $ar    = $self->{animar};
  my $limit = $self->{attr}->{total}-1;

  my ($idex,$cent)=$self->get_cent();
  @{$self->{prev}}=($idex,$cent);


  # set past ones to empty
  map {
    my $ico=$ar->[$ARG];
    $ico->{i}=$ico->{len}-1;

    $ico->get_cchar();

  } 0..$idex-1 if $idex;

  # ^future ones to full
  map {
    my $ico=$ar->[$ARG];
    $ico->{i}=0;

    $ico->get_cchar();

  } $idex+1..$limit if $idex < $limit;


  # ^current one to %%
  my $i   = $cent - $idex;
  my $ico = $ar->[$idex];

  $ico->{i}=$i*$ico->{len};
  $ico->get_cchar();


  return $self->get_cframe();

};

# ---   *   ---   *   ---
# ^cats all icons ogether

sub get_cframe($self) {

  my $ar    = $self->{animar};
  my $total = $self->{attr}->{total};

  my $half  = ($total >= 8)
    ? int_urdiv($total,2)-1
    : 3
    ;

  my $step  = ($total > 4)
    ? $half
    : $total
    ;

  my $beg   = 0;
  my $end   = $step;

  return map {

    $end=min($end,$total-1);

    my @line=(@$ar)[$beg..$end];

    $beg+=$ARG+1;
    $end+=$ARG+1;

    join $NULLSTR,map {
      $ARG->{cchar}

    } @line;

  } ($step,$step);

};

# ---   *   ---   *   ---
# get %% full of bar

sub get_cent($self) {

  my $attr  = $self->{attr};

  my $cur   = $attr->{i} * $self->{scale};
  my $max   = $attr->{total} * $self->{scale};

  my $limit = $self->{attr}->{total}-1;

  my $cent  = $self->{attr}->{total};
     $cent *= ($max - $cur) / $max;

  my $idex  = int($cent);
     $idex  = max(0,min($idex,$limit));

  return ($idex,$cent);

};

# ---   *   ---   *   ---
1; # ret
