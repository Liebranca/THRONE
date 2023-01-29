#!/usr/bin/perl
# ---   *   ---   *   ---
# RPG Dice
# It rolls!
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package RPG::Dice;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
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

  Readonly our $IRE=>qr{

    (?<num> \d+)
    [dD]

    (?<sides> \d+)

  }x;

  Readonly our $FRNG_W=>0x1000;

  sub Frame_Vars($class) {return {
    -wrath_of=>{}

  }};

# ---   *   ---   *   ---
# GBL

  my $Frame=RPG::Dice->get_frame();

# ---   *   ---   *   ---
# IO

  sub bash {

    my @call=(
      q[perl],"-I$ENV{ARPATH}/THRONE",

      q[-e],
      q[use RPG::Dice @ARGV;],@ARGV

    );

    system {$call[0]} @call;

  };

  sub import(@slurp) {

    my ($class,@dies) = @slurp;
    my @out           = ();

    # for each NdS
    map {

      push
        @out,
        $class->roll($ARG)

      ;

    } @dies;

    for my $x(@out) {
      say $x;

    };

    return $class;

  };

# ---   *   ---   *   ---
# new rng source

sub new($class,$wrath) {

  throw_no_dice($wrath)
  if !($wrath=~ $IRE);

  my $self=bless {

    astr  => $wrath,

    num   => $+{num},
    sides => $+{sides},

  },$class;

  return $self;

};

# ---   *   ---   *   ---
# ^errme

sub throw_no_dice($wrath) {

  errout(

    q[STR '%s' is not a valid dice],

    args => [$wrath],
    lvl  => $AR_FATAL,

  );

};

# ---   *   ---   *   ---
# fakes getting a random number

sub rng($self) {

  my $out  = (rand(0x1000));
  $out    %= $self->{sides};

  return $out;

};

# ---   *   ---   *   ---
# instas in cache

sub get($wrath) {

  return $Frame

    ->{ wrath_of }
    ->{ $wrath }

  ;

};

# ---   *   ---   *   ---
# reads NdS from table

sub fetch($class,$wrathr) {

  my $have=get($$wrathr);

  # create new if not in cache
  $$wrathr=(!defined $have)
    ? $class->new($$wrathr)
    : $have
    ;

};

# ---   *   ---   *   ---
# ^generates NdS

sub roll($class,$self) {

  my $out=0;

  # conditional get
  $class->fetch(\$self)
  if $self=~ $IRE;

  for my $n(1..$self->{num}) {
    $out+=1+$self->rng();

  };

  return $out;

};

# ---   *   ---   *   ---
1; # ret
