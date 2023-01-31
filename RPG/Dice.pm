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

  sub Frame_Vars($class) {return {
    -wrath_of=>{}

  }};

# ---   *   ---   *   ---
# GBL

  my $Frame=RPG::Dice->get_frame();

# ---   *   ---   *   ---
# IO

  # run as main if die are input
  # used to call roll from bash
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

    # show result
    for my $x(@out) {
      say $x;

    };

    return 0;

  };

# ---   *   ---   *   ---
# new rng source

sub new($class,$wrath) {

  # validate in
  throw_no_dice($wrath)
  if !($wrath=~ $IRE);

  # make new
  my $self=bless {

    id    => $wrath,

    num   => $+{num},
    sides => $+{sides},

  },$class;

  # ^add to table
  $Frame

    ->{ -wrath_of }
    ->{ $wrath }

  = $self;

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

sub roll($class,$self=undef) {

  my $out=1;

  # conditional get
  $class->fetch(\$self)
  if $self && $self=~ $IRE;

  $self//=$class;

  for my $n(1..$self->{num}) {
    $out+=int(rand($self->{sides}-1)+0.49);

  };

  return $out;

};

# ---   *   ---   *   ---
1; # ret
