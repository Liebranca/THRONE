#!/usr/bin/perl
# ---   *   ---   *   ---
# MARAUDER
# Grammatically correct
# spell-casting
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package Grammar::Marauder;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/avtomat/sys/';

  use Style;
  use Chk;
  use Fmat;

  use Arstd::Array;
  use Arstd::String;
  use Arstd::Re;
  use Arstd::IO;
  use Arstd::PM;

  use Tree::Grammar;

  use lib $ENV{'ARPATH'}.'/lib/';

  use Grammar;

  use Grammar::peso::common;
  use Grammar::peso::value;
  use Grammar::peso::eye;

  use lib $ENV{'ARPATH'}.'/THRONE/';
  use RPG::Dice;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.2;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

BEGIN {

  # class attrs
  sub Frame_Vars($class) { return {

    %{Grammar->Frame_Vars()},

    -passes  => ['_ctx','_walk','_run'],

    -chier_t => undef,
    -chier_n => undef,

  }};

  sub Shared_FVars($self) { return {
    %{Grammar::peso::eye::Shared_FVars($self)},

  }};


  # inherits from
  submerge(

    [qw(

      Grammar::peso::common
      Grammar::peso::value
      Grammar::peso::ops

    )],

    xdeps=>1,
    subex=>qr{^throw_},

  );

# ---   *   ---   *   ---
# GBL

  our $REGEX={

    %{$PE_VALUE->get_retab()},

    dice=>$RPG::Dice::IRE,

    q[hier-key] => re_pekey(qw(
      rune spell

    )),

    q[var-key]  => re_pekey(qw(
      var rom

    )),

    q[roll-key]  => re_pekey('roll'),

  };

# ---   *   ---   *   ---
# rule imports

  ext_rules(

    $PE_COMMON,qw(

    lcom term nterm opt-nterm

  ));

  ext_rules($PE_VALUE,qw(bare value));

# ---   *   ---   *   ---
# hierarchicals

  rule('~<hier-key>');
  rule('$<hier> hier-key nterm term');

# ---   *   ---   *   ---
# ^post-parse

sub hier($self,$branch) {

  my ($type,$name)=
    $branch->leafless_values();

  $branch->{value}={
    type=>uc $type,
    name=>$name,

  };

  $branch->clear();

};

# ---   *   ---   *   ---
# ^decl scope path

sub hier_ctx($self,$branch) {

  my $mach  = $self->{mach};
  my $scope = $mach->{scope};

  my @path  = $self->hier_run($branch);

  $scope->decl_branch($branch,@path);

};

# ---   *   ---   *   ---
# ^reset scope path

sub hier_run($self,$branch) {

  # get ctx
  my $f     = $self->{frame};
  my $st    = $branch->{value};

  # ^set current scope path
  $f->{-chier_t}=$st->{type};
  $f->{-chier_n}=$st->{name};

  return $self->set_path();

};

# ---   *   ---   *   ---
# ^uses framevars to set path

sub set_path($self) {

  my $f     = $self->{frame};
  my $mach  = $self->{mach};
  my $scope = $mach->{scope};

  my @path=(
    $f->{-chier_t},
    $f->{-chier_n},

  );

  $scope->path(@path);

  return @path;

};

# ---   *   ---   *   ---
# values within magic proc

  rule('~<var-key>');
  rule('$<var> var-key nterm term');

# ---   *   ---   *   ---
# ^post parse

sub var($self,$branch) {

  my $lv    = $branch->{leaves};
  my $type  = $lv->[0]->leaf_value(0);
  my $nterm = $lv->[1]->{leaves}->[0];

  my ($names,$values)=
    $self->rd_nterm_vlist($nterm);

  $branch->{value}={

    type   => uc $type,

    names  => $names,
    values => $values,

    ptrs   => [],

  };

  $branch->clear();

};

# ---   *   ---   *   ---
# get [names,values] from nterm

sub rd_nterm_vlist($self,$lv) {

  my @eye=$PE_EYE->recurse(

    $lv,

    mach       => $self->{mach},
    frame_vars => $self->Shared_FVars(),

  );

  my @names=map {
    $ARG->{raw}

  } $eye[0]->branch_values();

  my @values=(defined $eye[1])
    ? $eye[1]->branch_values()
    : ()
    ;

  return (\@names,\@values);

};

# ---   *   ---   *   ---
# ^bind decls

sub var_ctx($self,$branch) {

  my $mach   = $self->{mach};
  my $scope  = $mach->{scope};

  my $st     = $branch->{value};
  my $ptrs   = $st->{ptrs};

  my @names  = @{$st->{names}};


  # mark uninitialized
  map {
    $st->{values}->[$ARG]//=
      $mach->null('void')

  } 0..$#names;


  # ^bind decls
  my @values=@{$st->{values}};

  while(@names && @values) {

    my $name  = shift @names;
    my $value = shift @values;

    $value->{id}    = $name;
    $value->{const} = $st->{type} eq 'ROM';

    my $ptr=$mach->bind($value);
    push @$ptrs,$ptr;

  };

};

# ---   *   ---   *   ---
# ^rerun ops

sub var_run($self,$branch) {

  my $st   = $branch->{value};
  my $ptrs = $st->{ptrs};

  my @ar=map {
    $self->deref($$ARG)

  } @$ptrs;

};

# ---   *   ---   *   ---
# internal dice rolls

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

    type => uc $type,

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
# make parser tree

  our @CORE=qw(lcom hier var roll);

};

# ---   *   ---   *   ---
# test

my $prog=q[

rune hail;

  roll base 1d4;
  var  sum  base+2;

];

my $ice=Grammar::Marauder->parse($prog);
$ice->{p3}->prich();

# ---   *   ---   *   ---
1; # ret
