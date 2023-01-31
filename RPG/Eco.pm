#!/usr/bin/perl
# ---   *   ---   *   ---
# RPG ECONOMY
# Acquire currency
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package RPG::Eco;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use Storable qw(dclone);

  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;
  use Arstd::IO;

  use parent 'St';

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  sub Frame_Vars($class) {return {

    # frame methods
    -autoload=>[qw(

      log
      make
      unmake
      have

      craft
      smelt
      trade
      grant

      balance
      prich

    )],

    # state
    owner  => 'Hunter',
    types  => {},
    maters => {},
    res    => {},

  }};

  Readonly our $DEFAULTS=>{

    # lore
    name  => 'morlaco',
    type  => 'coin',

    # mech
    grams => 1,
    mater => {
      q[argentum ingot]=>1.0,

    },

  };

  Readonly our $KG => 1000;

# ---   *   ---   *   ---
# get new resource container

sub new($class,$owner) {

  my $gframe = $class->get_gframe();
  my $frame  = $class->new_frame();

  $frame->{owner}  = $owner;
  $frame->{types}  = dclone $gframe->{types};
  $frame->{maters} = dclone $gframe->{maters};

  return $frame;

};

# ---   *   ---   *   ---
# remember resource for instance reuse

sub save($class,$o) {
  my $frame=$class->get_gframe();
  $frame->{res}->{$o->{name}}=$o;

};

# ---   *   ---   *   ---
# add new resource

sub resource($class,%O) {

  # set defaults
  $class->defnit(\%O);

  # get existing
  my $self=$class->fetch($O{name});

  # ^create new
  if(!defined $self) {
    $self=bless {%O},$class;
    $class->register($self);

  };

  return $self;

};

# ---   *   ---   *   ---
# adds resource to tables

sub register($class,$self) {

  my ($type,$mater)=(
    $self->{type},
    $self->{mater}

  );

  my $gframe=$class->get_gframe();

  for my $elem(keys %$mater) {

    my $total=\(
      $gframe->{maters}->{$elem}

    );

    $$total //= 0;

  };

  my $total=\(
    $gframe->{types}->{$type}

  );

  $$total //= {};
  $$total->{$self->{name}} //= 0;

  $self->calc_gpe();
  $class->save($self);

};

# ---   *   ---   *   ---
# calculate grams per-element

sub calc_gpe($self) {

  my $mater = $self->{mater};
  my $total = $self->{grams};

  my $err   = 0.0;

  for my $elem(keys %{$self->{mater}}) {

    my $gramsref = \($mater->{$elem});
    my $percent  = $$gramsref;

    $$gramsref   = $total*$percent;
    $err        += $percent;

  };

  throw_bad_percent($self->{name})
  if $err-1.0 != 0.0;

};

# ---   *   ---   *   ---
# ^errme

sub throw_bad_percent($name) {

  errout(
    q[Bad component percents ] .
    q[on resource <%s>],

    args => [$name],
    lvl  => $AR_FATAL,

  );

};

# ---   *   ---   *   ---
# registers transaction

sub log(

  # implicit
  $class,
  $frame,

  # actual
  $self,
  $change=0

) {

  my ($type,$mater)=(
    $self->{type},
    $self->{mater}

  );

  for my $elem(keys %$mater) {

    my $grams=$mater->{$elem};

    $frame
      ->{maters}
      ->{$elem}

    +=$grams*$change;

  };

  $frame
    ->{types}
    ->{$type}

    ->{$self->{name}}

  +=$change;

};

# ---   *   ---   *   ---
# spawns resource from components

sub make(

  # implicit
  $class,
  $frame,

  # actual
  $self,
  $change=1

) {

  my $mater = $self->{mater};
  my $fail  = 0;

  my @trade = ();

  for my $elem(keys %$mater) {

    my $other  = $class->cfetch($elem);
    my $need   = $mater->{$elem}*$change;

    $need     /= $other->{grams};

    if(!$frame->have($other,$need)) {
      say "$frame->{owner} doesn't have enough $other->{name}";

      $fail=1;
      last;

    };

    push @trade,[$other,-$need];

  };

  if(!$fail) {

    for my $ref(@trade) {
      my ($elem,$need)=@$ref;
      $frame->log($elem,$need);

    };

    $frame->log($self,$change);

  };

};

# ---   *   ---   *   ---
# ^spawn components from resource

sub unmake(

  # implicit
  $class,
  $frame,

  # actual
  $self,
  $change=1

) {

  my $mater = $self->{mater};
  my $fail  = 0;

  my @trade = ();

  for my $elem(keys %$mater) {

    my $other = $class->cfetch($elem);

    my $has   = $mater->{$elem}*$change;
    my $need  = $other->{grams};

    my $gets  = $has/$need;

    if(!$frame->have($self,$change)) {
      say "$frame->{owner} doesn't have enough $self->{name}";

      $fail=1;
      last;

    };

    push @trade,[$other,$gets];

  };

  if(!$fail) {

    for my $ref(@trade) {
      my ($elem,$gets)=@$ref;
      $frame->log($elem,$gets);

    };

    $frame->log($self,-$change);

  };

};

# ---   *   ---   *   ---
# checks resource in container
# equal or greater to N

sub have(

  # implicit
  $class,
  $frame,

  # actual
  $self,
  $change

) {

  return $frame
    ->{types}
    ->{$self->{type}}
    ->{$self->{name}}

  >= $change;

};

# ---   *   ---   *   ---
# get from table

sub fetch($class,$name) {

  my $frame = $class->get_gframe();
  my $self  = $frame->{res}->{$name};

  return $self;

};

# ---   *   ---   *   ---
# shorthand w/errchk

sub cfetch($class,$name) {

  my $self=$class->fetch($name);

  throw_no_res($name)
  if !defined $self;

  return ($self);

};

# ---   *   ---   *   ---
# ^errme

sub throw_no_res($name) {

  errout(

    q[Resource <%s> not found],

    args => [$name],
    lvl  => $AR_FATAL,

  );

};

# ---   *   ---   *   ---
# create from elems

sub craft($class,$dst,%O) {

  for my $name(keys %O) {

    my $self   = $class->cfetch($name);
    my $change = $O{$name};

    say "$dst->{owner} crafts $change $name";

    $dst->make($self,$change);

  };

};

# ---   *   ---   *   ---
# turn resource into mater

sub smelt($class,$dst,%O) {

  for my $name(keys %O) {

    my $self   = $class->cfetch($name);
    my $change = $O{$name};

    say "$dst->{owner} smelts $change $name";

    $dst->unmake($self,$change);

  };

};

# ---   *   ---   *   ---
# arbitrary exchange

sub trade($class,$dst,$src,%O) {

  for my $name(keys %O) {

    my $self   = $class->cfetch($name);
    my $change = $O{$name};

    say "$dst->{owner} trades $change $name with $src->{owner}";

    if(!$src->have($self,$change)) {
      say "$src->{owner} doesn't have enough $name";
      next;

    };

    $dst->log($self, $change);
    $src->log($self,-$change);

  };

};

# ---   *   ---   *   ---
# acquire from world

sub grant($class,$dst,%O) {

  for my $name(keys %O) {

    my $self   = $class->cfetch($name);
    my $change = $O{$name};

    say "$dst->{owner} obtains $change $name";

    $dst->log($self,$change);

  };

};

# ---   *   ---   *   ---
# get sum of multiple frames

sub balance($class,@assets) {

  my $mater_sum = {};
  my $type_sum  = {};

  for my $asset(@assets) {

    my ($types,$maters)=(
      $asset->{types},
      $asset->{maters},

    );

    sum_types($type_sum,$types);
    sum_maters($mater_sum,$maters);

  };

  return ($type_sum,$mater_sum);

};

# ---   *   ---   *   ---
# combines two inventories

sub sum_types($dst,$src) {

  for my $type(keys %$src) {

    my $res=$src->{$type};
    my $sum=\( $dst->{$type} );

    $$sum//={};

    for my $name(keys %$res) {

      my $quant=$res->{$name};

      $$sum->{$name} //= 0;
      $$sum->{$name}  += $quant;

    };

  };

};

# ---   *   ---   *   ---
# ^for maters in inventory

sub sum_maters($dst,$src) {

  for my $mater(keys %$src) {

    my $grams = $src->{$mater};
    my $sum   = \( $dst->{$mater} );

    $$sum //= 0;
    $$sum  += $grams;

  };

};

# ---   *   ---   *   ---
# show balance

sub prich($class,@assets) {

  if(!@assets) {
    @assets=$class->get_frame_list();

  };

  my ($types,$maters)=
    $class->balance(@assets);

  for my $mater(keys %$maters) {

    my $quant=$maters->{$mater};
    next if !$quant;

    say "$mater ${quant}g";

    for my $type(keys %$types) {
      my $res=$types->{$type};

      for my $name(keys %$res) {

        my $quant = $res->{$name};
        my $self  = $class->cfetch($name);

        my $total = $self->{grams};

        if(exists $self->{mater}->{$mater}) {

          my $grams   = $self->{mater}->{$mater};
          my $units   = ($grams/$total)*$quant;

          say "\\-->$type $name $units x ${grams}g"
          if $units;

        };

      };

    };

    say $NULLSTR;

  };

};

# ---   *   ---   *   ---
# test

RPG::Eco->resource(

  name  => 'argentum',
  type  => 'mineral',

  mater => {argentum=>1.0},
  grams => 20,

);

RPG::Eco->resource(

  name  => 'argentum ingot',
  type  => 'metal',

  mater => {argentum=>1.0},
  grams => 5,

);

RPG::Eco->resource();

# ---   *   ---   *   ---

my $caravan = RPG::Eco->new("Caravan");
my $guild   = RPG::Eco->new("Guild");

$caravan->grant(argentum=>1);

$guild->trade($caravan,
  argentum=>1

);

$guild->craft(q[argentum ingot]=>1);
$guild->craft(q[morlaco]=>5);

#$guild->smelt(q[argentum ingot]=>1);
$guild->smelt(q[morlaco]=>1);

say $NULLSTR;
$guild->prich();

# ---   *   ---   *   ---
1; # ret
