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

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# cstruc

sub new($class,%O) {

  $O{max}   //= 100;
  $O{cur}   //= $O{max};

  $O{color} //= 0x000000800000;
  $O{anim}  //= $GF::Icon::PAIN;
  $O{rate}  //= 4;


  # calc num sprites
  my $len=@{$O{anim}};
  my $cnt=int_urdiv($O{max},$len);

  my $self=bless {

    max    => $O{max},
    cur    => $O{cur},

    color  => $O{color},

    cnt    => $cnt,
    prev   => [0,0],
    stop   => 0,

    animar => [map {
      GF::Icon->new($O{anim},rate=>$O{rate}),

    } 0..$cnt-1],


    cframe => '',


  },$class;

  $self->update_instant();

  return $self;

};

# ---   *   ---   *   ---
# run anim step towards current frame

sub update($self) {

  my ($beg_idex,$beg_cent)=@{$self->{prev}};
  my ($end_idex,$end_cent)=$self->get_cent();

  my $limit = $self->{cnt}-1;

  my $ar    = $self->{animar};
  my $ico   = $ar->[$beg_idex];


  # run anim for this frame
  if($beg_cent < $end_cent) {
    $ico->play_stop();

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
     ($beg_cent <= $end_cent + 0.001)
  && ($beg_cent >= $end_cent - 0.001)
  ;

  return $self->get_cframe();

};

# ---   *   ---   *   ---
# ^skip animation

sub update_instant($self) {

  my $ar    = $self->{animar};
  my $limit = $self->{cnt}-1;

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
# ^cats all icons together

sub get_cframe($self) {

  my $ar    = $self->{animar};
  my $total = $self->{cnt};

  my $step  = ($total > 8)
    ? int($total/2)
    : $total
    ;

  my $beg   = 0;
  my $end   = $step;
  my $cnt   = int_urdiv($total,$step);

  return map {

    $end=min($total-1,$end);

    my @line=(@$ar)[$beg..$end];

    $beg+=$step+1;
    $end+=$step+1;

    join $NULLSTR,map {
      $ARG->{cchar}

    } @line;

  } 0..$cnt-1;

};

# ---   *   ---   *   ---
# get %% full of bar

sub get_cent($self) {

  my $cur   = $self->{max} - $self->{cur};
  my $limit = $self->{cnt}-1;

  my $cent  = $self->{cnt};
     $cent *= $cur / $self->{max};

  my $idex  = int($cent);
     $idex  = max(0,min($idex,$limit));

  return ($idex,$cent);

};

# ---   *   ---   *   ---
# reduce current

sub damage($self,$x=1) {
  $self->{cur} -= $x;
  $self->{cur}  = max(min(
    $self->{max},
    $self->{cur}

  ),0);

};

# ---   *   ---   *   ---
1; # ret
