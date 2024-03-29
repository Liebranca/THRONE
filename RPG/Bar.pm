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
  $O{anim}  //= $GF::Icon::HEART;


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
# get draw command

sub draw($self,%O) {

  # defaults
  $O{pos} //= [0,0];
  $O{imm} //= 0;

  # ^lis
  my $co = $O{pos};
  my $y  = $co->[1];

  $O{height} //= \$y;

  # filter out empty lines
  my $long  = 0;
  my $fn    = ($O{imm})
    ? 'update_instant'
    : 'update'
    ;

  my @lines=grep {

    my $l=length $ARG;
    $long=max($long,$l);

    $l > 0;

  } $self->$fn();


  # ^get draw commands
  my @cmd=$self->{animar}->draw($co);


  # adjust next write and give
  ${$O{height}}  = $co->[1];

  $co->[0]      += $long+1;
  $co->[1]       = $y;


  return @cmd;

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
  my $total=$self->{attr}->{total}-1;
  $self->{animar}=GF::Icon::Array->new(

    [map {{
      anim  => $self->{anim},
      color => $self->{color},

    }} 0..$total]

  );


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

    $beg_cent=$beg_idex+(
      $ico->{i}/$ico->{len}

    );

  # ^backwards when healing
  } elsif($beg_cent > $end_cent) {

    $ico->rewind();

    my $step  = $ico->{i}/$ico->{len};
       $step -= 0.1*$step==0;

    $beg_cent=$beg_idex+$step;

  };


  # ^adjust current
  $beg_idex=max(0,min(int($beg_cent),$limit));
  @{$self->{prev}}=($beg_idex,$beg_cent);

  $self->{stop}=
     ($beg_cent <= $end_cent + 0.1)
  && ($beg_cent >= $end_cent - 0.1)
  ;


SKIP:

  return $self->{animar}->get_cframe();

};

# ---   *   ---   *   ---
# ^adjusts playback rate
# accto beg-end diff

sub update_rate($self) {

  my ($beg_idex,$beg_cent)=@{$self->{prev}};
  my ($end_idex,$end_cent)=$self->get_cent();

  my $rate=abs($beg_cent-$end_cent);
     $rate=max(2,min($rate,8));

  $self->{animar}->set_rate(16-$rate);
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

    $ico->get_cframe();

  } 0..$idex-1 if $idex;

  # ^future ones to full
  map {
    my $ico=$ar->[$ARG];
    $ico->{i}=0;

    $ico->get_cframe();

  } $idex+1..$limit if $idex < $limit;


  # ^current one to %%
  my $i   = $cent - $idex;
  my $ico = $ar->[$idex];

  $ico->{i}=$i*$ico->{len};
  $ico->get_cframe();


  return $self->{animar}->get_cframe();

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
