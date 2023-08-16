#!/usr/bin/perl
# ---   *   ---   *   ---
# RPG SOCIAL
# Relations!
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package RPG::Social;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;
  use Arstd::Hash;

  use parent 'St';

  use lib $ENV{'ARPATH'}.'/lib/';
  use lib $ENV{'ARPATH'}.'/THRONE/';

  use RPG::Dice;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.3;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  sub Frame_Vars($class) {return {}};

  Readonly my $TRAITS=>{

    courage=>{
      act=>[qw(rally engage resist fight)],
      ban=>[qw(cowardice)],

    },

    cowardice=>{
      act=>[qw(evade flee demoralize surrender)],
      ban=>[qw(courage)],

    },

    cruelty=>{
      act=>[qw(scare hurt torture no-mercy)],
      ban=>[qw(empathy)],

    },

    empathy=>{
      act=>[qw(help heal mercy)],
      ban=>[qw(cruelty)],

    },

  };

  Readonly my $SITS=>{

    encounter=>[qw(fight flee)],

  };

# ---   *   ---   *   ---
# creates a personality

sub new($class,%O) {

  # defaults
  $O{traits} //= [qw(courage empathy)];


  # likes v dislikes
  my $pref     = [];
  my $npref    = [];


  # build action pool
  for my $t(@{$O{traits}}) {

    $t=$TRAITS->{$t};

    my ($act,$bans)=($t->{act},$t->{ban});

    push @$pref,@$act;

    for my $ban(@$bans) {
      my $nact=$TRAITS->{$ban}->{act};
      push @$npref,@$nact;

    };

  };


  my $tolerance = @$pref;

  # preferred actions
  my $likes     = [map {
    $ARG=>$tolerance--

  } @$pref];

  # ^loathed ones
  $tolerance--;
  my $dislikes  = [map {
    $ARG=>$tolerance--

  } @$npref];


  # make ice
  my $self  = bless {

    prefers => $likes,
    loathes => $dislikes,

    neutral => [],

  },$class;


  return $self;

};

# ---   *   ---   *   ---
# get list of all known acts

sub pool($self) {

  return (

    $self->{prefers},
    $self->{neutral},
    $self->{loathes},

  );

};

# ---   *   ---   *   ---
# ^dereferenced

sub deref_pool($self) {

  return (

    @{$self->{prefers}},
    @{$self->{neutral}},
    @{$self->{loathes}},

  );

};

# ---   *   ---   *   ---
# persona's preference for action

sub feelbout($self,$act) {

  my $feel = 0;
  my %bout = $self->deref_pool();


  # add unknown act to neutral
  if(! exists $bout{$act}) {
    push @{$self->{neutral}},$act=>$feel;

  # ^use existing
  } else {
    $feel=$bout{$act};

  };


  return $feel;

};

# ---   *   ---   *   ---
# ^batch

sub array_feelbout($self,@opts) {

  my @feels = ();
  my %bout  = $self->deref_pool();


  # walk options
  for my $act(@opts) {

    my $feel=0;

    # add unknown act to neutral
    if(! exists $bout{$act}) {
      push @{$self->{neutral}},$act=>$feel;

    # ^use existing
    } else {
      $feel=$bout{$act};

    };

    push @feels,$feel;

  };


  return @feels;

};

# ---   *   ---   *   ---
# act out the persona

sub behave($self,@opts) {

  my $pool  = undef;
  my @feels = $self->array_feelbout(@opts);

  my $good  = grep {$ARG >=  1} @feels;
  my $meh   = grep {$ARG ==  0} @feels;


  # most preferred out of avail
  if($good) {
    $pool=$self->{prefers};

  # random from neutral
  } elsif($meh) {
    $pool=$self->{neutral};

  # least bad
  } else {
    $pool=$self->{loathes};

  };


  # fetch action
  my $ar  = lfind(\@opts,$pool);
  my $act = (! $good && $meh)
    ? RPG::Dice->pick(@$ar)
    : shift @$ar
    ;


  return $act=>$self->feelbout($act);

};

# ---   *   ---   *   ---

sub situation($self,$ctx) {

  my @opts=@{$SITS->{$ctx}};
  my ($act,$feel)=$self->behave(@opts);

  return ($ctx,$act,$feel);

};

# ---   *   ---   *   ---
1; # ret
