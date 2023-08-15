#!/usr/bin/perl
# ---   *   ---   *   ---
# RPG ACTOR
# A player uppon the stage
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package RPG::Actor;

  use v5.36.0;
  use strict;
  use warnings;

  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;
  use Chk;
  use Queue;

  use lib $ENV{'ARPATH'}.'/lib/';
  use GF::Icon;

  use lib $ENV{'ARPATH'}.'/THRONE/';

  use RPG::Attr;
  use RPG::Status;
  use RPG::Space;
  use RPG::Social;

  use parent 'St';

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.5;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  sub Frame_Vars($class) {return {

    -autoload=>[qw(
      member

    )],

    name=>'Circle of Four',

  }};

# ---   *   ---   *   ---
# constructor

sub new($class,%O) {

  # defaults
  $O{name}   //= 'Vagabond';
  $O{social} //= {};
  $O{attrs}  //= {};
  $O{grim}   //= [];
  $O{eff}    //= [];

  # basic attrs are builtin
  # they must be as they are
  # integral to the system
  $class->nit_basic_attrs($O{attrs});


  # obj detailing 'world presence'
  my $space=RPG::Space->array(

    pos    => $O{pos},
    sprite => $O{sprite},

    size   => $O{size},
    cell   => $O{cell},

    behave => $O{behave},

  );

  # ^make ice
  my $self=bless {

    name    => $O{name},
    space   => $space,

    social  => RPG::Social->new(%{$O{social}}),
    attrs   => RPG::Attr->table($O{attrs}),

    grim    => RPG::Spell->table(@{$O{grim}}),
    status  => RPG::Status->new(eff=>$O{eff}),

  },$class;


  return $self;

};

# ---   *   ---   *   ---
# initializes basic attributes
# if they are not present

sub nit_basic_attrs($class,$attrs) {

  state $hp_bar={
    color => 0b10000000,
    anim  => $GF::Icon::HEART,

  };

  state $mp_bar={
    color => 0b00001111,
    anim  => $GF::Icon::MANA,

  };

  state $ap_bar={
    color => 0b00010000,
    anim  => $GF::Icon::TASK,

  };

  $attrs->{hp}         //= {};
  $attrs->{hp}->{base} //= 8;

  $attrs->{mp}         //= {};
  $attrs->{mp}->{base} //= 3;

  $attrs->{ap}         //= {};
  $attrs->{ap}->{base} //= 1;

  $attrs->{hp}->{bar}=$hp_bar;
  $attrs->{mp}->{bar}=$mp_bar;
  $attrs->{ap}->{bar}=$ap_bar;

};

# ---   *   ---   *   ---
# actor has HP left

sub alive($self) {
  my $attr=$self->{attrs}->{hp};
  return $attr->{i} > 0;

};

# ---   *   ---   *   ---
# gives draw commands for
# name and basic stats

sub draw_bars($self,%O) {

  # defaults
  $O{pos}       //= [0,0];
  $O{imm}       //= 0;
  $O{show_name} //= 1;

  # ^lis
  my $co=$O{pos};


  my @out    = ();
  my ($x,$y) = @$co;

  # optionally display actor name
  if($O{show_name}) {

    push @out,{

      proc => 'mvcur',
      args => [$co->[0],$co->[1]++],

      ct   => $self->{name},

    };

    $co->[0]+=2;
    $co->[1]++;

  };


  # get bars
  my $attrs = $self->{attrs};
  my @bars  = map {
    $attrs->{$ARG}->{bar}

  } qw(hp mp ap);


  # ^get draw commands for each
  push @out,map {

    $ARG->draw(
      pos    => $co,
      height => \$y,
      imm    => $O{imm}

    )

  } @bars;

  # ^get updated status for each
  my $updated=grep {
    ! $ARG->{stop};

  } @bars;


  # ^display status effects
  push @out,$self->{status}->draw(pos=>$co);


  $co->[0]=$x;
  $co->[1]=$y+2;


  return $updated,@out;

};

# ---   *   ---   *   ---
# change position, absolute

sub teleport($self,$nx,$ny) {

  my $space  = $self->{space};
  my ($x,$y) = $space->array_teleport($nx,$ny);

  my $new    = $self->{space}->origin();

  return ! $new->{co}->equals([$x,$y,0,0]);

};

# ---   *   ---   *   ---
# ^relative to current

sub walk($self,$dx,$dy) {

  my $space  = $self->{space};
  my ($x,$y) = $space->array_walk($dx,$dy);

  my $new    = $self->{space}->origin();

  return ! $new->{co}->equals([$x,$y,0,0]);

};

# ---   *   ---   *   ---
# create and follow path to destination

sub walk_to($self,$dst) {

  my $out    = 0;
  my ($x,$y) = $self->point_or_object($dst);

  if(! $self->arrived($x,$y)) {

    if(! $self->follow_path()) {
      $out=1;

    } else {
      $out|=2;

    };

  };

  return $out;

};

# ---   *   ---   *   ---
# get nearest neighboring tile

sub near_nof($self,$other) {

  my $cur  = $self->{space}->origin();
  my @walk = $other->{space}->array_nof();

  my ($p,$i)=$cur->{co}->nearest(
    map {$ARG->{co}} @walk

  );

  return @$p;

};

# ---   *   ---   *   ---
# solve movement target

sub point_or_object($self,$other) {

  my @out   = ();
  my $path  = $self->{q[$cpath]};

  my $isref = 0<length ref $other;

  if($isref && ! $path) {
    @out=$self->near_nof($other);

  } elsif($path && @$path) {
    @out=@{$path->[-1]->{co}};

  } elsif(!$isref) {
    @out=@$other;

  };

  return @out;

};

# ---   *   ---   *   ---
# go to next point in

sub follow_path($self) {

  my $path  = $self->{q[$cpath]};
  my $point = shift @$path;

  my $cur   = $self->{space}->origin();
  my $delta = $point->{co}->minus($cur->{co});

  return $self->walk(@{$delta}[0..1]);

};

# ---   *   ---   *   ---
# at end/start of path

sub arrived($self,$x,$y) {

  my $out  = 0;

  my $path = $self->{q[$cpath]};
  my $cur  = $self->{space}->origin();

  # last point popped
  if($path && ! @$path) {
    delete $self->{q[$cpath]};
    $out=1;

  # dst reached
  } else {
    $self->path_to($x,$y) if ! $path;

  };

  return $out;

};

# ---   *   ---   *   ---
# do the dijks

sub path_to($self,$x,$y) {

  my $cell = $self->{space}->{cell};

  # TODO:
  # throw if ! $cell->in_bounds($x,$y);

  my $dst  = $cell->tile($x,$y);
  my $src  = $self->{space}->origin();

  my @path = ($src);

  while($dst ne $path[-1]) {

    my $cur  = $path[-1];
    my @walk = $cur->get_nwalk();

    # get closest to dst out of
    # walkable neighbors
    my ($p,$i)=$dst->{co}->nearest(
      map {$ARG->{co}} @walk

    );

    my $near=$walk[$i];
    push @path,$near;

  };

  $self->{q[$cpath]}=\@path;

  shift  @path;
  return @path;

};

# ---   *   ---   *   ---
# placeholder: behave like
# you're not just an NPC

sub social($self,$fn,@args) {

  my ($ctx,$act,$feel)=$self->{social}->$fn(@args);

  say "On $ctx: $self->{name} chooses $act($feel)";

};

# ---   *   ---   *   ---
# interaction shorthand

sub touch($self,$other,@args) {

  return $other->{space}->iract(
    'on_touch',$self,@args

  );

};

# ---   *   ---   *   ---
# give list of avail spells

sub may_cast($self) {

  my $mp=$self->{attrs}->{mp};

  return grep {
    $ARG->{degree} <= $mp->{i}

  } values %{$self->{grim}};

};

# ---   *   ---   *   ---
# select spell from avail

sub pick_spell($self) {

  my @avail = $self->may_cast();
  my $out   = $avail[0];

  # NOTE:
  #
  #   for now the only criteria is
  #   mp cost, but an actor's persona
  #   should eventually factor into
  #   their strategy

  map {
    $out=$ARG if $ARG->{degree} > $out->{degree}

  } @avail;


  return $out;

};

# ---   *   ---   *   ---
# recover a lick of energy

sub regen($self) {

  my $mp=$self->{attrs}->{mp};
  my $ap=$self->{attrs}->{ap};

  $mp->mod_current(1);
  $ap->mod_current(1);

};

# ---   *   ---   *   ---
# it's [ACTOR]'s turn!

sub take_turn($self) {

  # run status effects
  $self->{status}->tick();

  # ^chk actor hasn't died from
  # an injury this turn
  return undef if ! $self->alive();

  $self->regen();
  return $self->pick_spell();

};

# ---   *   ---   *   ---
# wraps over spell->cast(dst,src)

sub cast($self,$name,$dst) {

  my $spell = $self->{grim}->{$name};
  my $mp    = $self->{attrs}->{mp};

  $mp->mod_current(-$spell->{degree});

  return $spell->cast($dst,$self);

};

# ---   *   ---   *   ---
1; # ret
