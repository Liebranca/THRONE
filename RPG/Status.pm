#!/usr/bin/perl
# ---   *   ---   *   ---
# RPG STATUS
# +1 to grit
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package RPG::Status;

  use v5.36.0;
  use strict;
  use warnings;

  use English qw(-no_match_vars);
  use List::Util qw(min max);

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;
  use Arstd::Int;
  use Arstd::Array;

  use lib $ENV{'ARPATH'}.'/lib/';
  use GF::Icon;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# cstruc

sub new($class,%O) {

  # defaults
  $O{eff} //= [];


  # make ice
  my $self=bless {

    eff    => [],
    animar => [],

    upd    => 0,

  },$class;

  # ^nit passed effects
  map {
    my ($id,$M,$o)=@$ARG;
    $self->add($id,$M,%$o);

  } @{$O{eff}};

  $self->update_animar() if @{$O{eff}};


  return $self;

};

# ---   *   ---   *   ---
# push effect to stack

sub add($self,$id,$M,%O) {

  $O{color} //= 0b11100011;
  $O{anim}  //= ['?'];

  push @{$self->{eff}},$id=>{

    magic => $M,

    color => $O{color},
    anim  => $O{anim},

  };

  $self->{upd}=1;

};

# ---   *   ---   *   ---
# ^bat-undo

sub remove($self,@id) {

  map {
    my $idex=array_iof($self->{eff},$ARG);
    splice @{$self->{eff}},$idex,2;

  } @id;

  $self->{upd}=1;

};

# ---   *   ---   *   ---
# make display

sub update_animar($self) {

  my @eff=array_values($self->{eff});

  $self->{animar}=GF::Icon::Array->new(

    [map {{
      anim  => $ARG->{anim},
      color => $ARG->{color},

    }} @eff]

  );

};

# ---   *   ---   *   ---
# get draw command

sub draw($self,%O) {

  # defaults
  $O{pos}//=[0,0];

  return () if ! @{$self->{eff}};

  # get updated display
  $self->update_animar() if $self->{upd};
  $self->{upd}=0;


  # get current frame and advance
  my @out=$self->{animar}->draw($O{pos});
  $self->{animar}->play();


  return @out;

};

# ---   *   ---   *   ---
# apply effects

sub tick($self) {

  return if ! @{$self->{eff}};

  my @keys = array_keys($self->{eff});
  my @eff  = array_values($self->{eff});


  my @over=grep {

    my $stat  = shift @eff;

    my $M     = $stat->{magic};
    my $spell = $M->{spell};

    map {$ARG->tick($M)} @{$spell->{eff}};

    0 >= $M->{dur}--;

  } @keys;


  $self->remove(@over) if @over;

};

# ---   *   ---   *   ---
1; # ret
