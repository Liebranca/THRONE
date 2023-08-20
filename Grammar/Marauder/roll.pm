#!/usr/bin/perl
# ---   *   ---   *   ---
# MARAUDER ROLL
# Internal dice rolls
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package Grammar::Marauder::roll;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/avtomat/sys/';

  use Style;
  use Chk;
  use Fmat;

  use Arstd::Re;
  use Arstd::IO;
  use Arstd::PM;

  use lib $ENV{'ARPATH'}.'/lib/';
  use lib $ENV{'ARPATH'}.'/THRONE/';

  use Grammar;
  use Grammar::peso::std;
  use Grammar::Marauder::std;

  use RPG::Dice;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

BEGIN {

  # beqs
  $PE_STD->use_common();
  $PE_STD->use_value();

# ---   *   ---   *   ---
# GBL

  our $REGEX={

    dice=>$RPG::Dice::IRE,

    q[roll-key]  => re_pekey(qw(
      roll

    )),

  };

# ---   *   ---   *   ---
# parser rules

  rule('~<roll-key>');
  rule('~<dice>');
  rule('$<roll> roll-key bare dice term');

# ---   *   ---   *   ---
# ^post-parse

sub roll($self,$branch) {

  my ($type,$name,$dice)=
    $branch->leafless_values();

  RPG::Dice->fetch(\$dice);

  $branch->{value}={

    type => lc $type,

    name => $name,
    dice => $dice,

    ptr  => undef,

  };

  $branch->clear();

};

# ---   *   ---   *   ---
# ^creates value holding
# result of dice roll

sub roll_ctx($self,$branch) {

  my $st   = $branch->{value};
  my $dice = $st->{dice};

  my $mach = $self->{mach};

  $st->{ptr}=$mach->decl(
    num => $st->{name},
    raw => $dice->roll(),

  );

};

# ---   *   ---   *   ---
# ^re-rolls

sub roll_run($self,$branch) {

  my $st   = $branch->{value};

  my $dice = $st->{dice};
  my $ptr  = $st->{ptr};

  $$ptr->{raw}=$dice->roll();

};

# ---   *   ---   *   ---
# do not generate a parser tree!

  our @CORE=qw();

# ---   *   ---   *   ---

}; # BEGIN

# ---   *   ---   *   ---
1; # ret
