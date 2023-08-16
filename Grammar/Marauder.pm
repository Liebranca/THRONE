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

    q[io-key]    => re_pekey(qw(in out io)),

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

  $branch->clear();

  $branch->init({
    type=>uc $type,
    name=>$name,

  });

};

# ---   *   ---   *   ---
# ^decl scope path

sub hier_ctx($self,$branch) {

  $branch->{value}=$branch->leaf_value(0);
  $branch->clear();

  $self->hier_sort($branch);

  my $mach  = $self->{mach};
  my $scope = $mach->{scope};

  my @path  = $self->hier_path($branch);

  $scope->decl_branch($branch,@path);

};

# ---   *   ---   *   ---
# ^parent child leaves to
# hier branch

sub hier_sort($self,$branch) {

  state $re=qr{^hier$};

  my @lv=$branch->match_up_to($re);
  $branch->pushlv(@lv);

};

# ---   *   ---   *   ---
# ^reset scope path

sub hier_path($self,$branch) {

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
# crux to blk

sub hier_run($self,$branch) {

  my $mach  = $self->{mach};
  my $scope = $mach->{scope};

  my @path  = $self->hier_path($branch);
  my $lv    = $scope->haslv(@path,'IN');


  # fetch input values
  if(defined $lv) {

    my @args  = $mach->get_args();
       @args  = $self->deref_args(@args);

    my @ptr   = $lv->leafless_values();


    throw_overargs(@path)
    if @ptr < @args;


    map {
      (shift @ptr)->{raw}=$ARG

    } @args;


  };

if(defined $lv) {
  my @ptr=$lv->leafless_values();
  map {say $ARG->{raw}} @ptr;

};

};

# ---   *   ---   *   ---
# ^the fetch part

sub deref_args($self,@ar) {

  return map {
    $self->deref($ARG,ptr=>1)

  } @ar;

};

# ---   *   ---   *   ---
# errme

sub throw_overargs(@path) {

  my $path=join q[::],@path;

  errout(

    q[Too many arguments for fcall ]
  . q[[goodtag]:%s],

    lvl  => $AR_FATAL,
    args => [$path],

  );

};

# ---   *   ---   *   ---
# values within magic proc

  rule('~<var-key>');
  rule('$<var> var-key nterm term');

# ---   *   ---   *   ---
# ^post parse

sub var($self,$branch) {

  # unpack
  my ($type,$names,$values)=
    $self->rd_name_nterm($branch);

  $self->defnull($values,@$names);


  # ^repack
  $branch->{value}={

    type   => uc $type,

    names  => $names,
    values => $values,

    ptrs   => [],

  };


  $branch->clear();

};

# ---   *   ---   *   ---
# ^defaults uninitialized
# values to null

sub defnull($self,$dst,@src) {

  my $mach=$self->{mach};

  map {
    $dst->[$ARG]//=
      $mach->null('void')

  } 0..$#src;

};

# ---   *   ---   *   ---
# get [names,values] from nterm

sub rd_nterm($self,$lv) {

  my @eye=$PE_EYE->recurse(

    $lv,

    mach       => $self->{mach},
    frame_vars => $self->Shared_FVars(),

  );

  return map {[
    map {$ARG} $ARG->branch_values()

  ]} @eye;

};

# ---   *   ---   *   ---
# ^shorthand for common pattern

sub rd_name_nterm($self,$branch) {

  my $lv    = $branch->{leaves};

  my $name  = $lv->[0]->leaf_value(0);
  my $nterm = $lv->[1]->{leaves}->[0];

  my @nterm = (defined $nterm)
    ? $self->rd_nterm($nterm)
    : ()
    ;

  return ($name,@nterm);

};

# ---   *   ---   *   ---
# bind decls

sub var_ctx($self,$branch) {

  my $st=$branch->{value};

  $st->{ptr}=$self->var_bind(

    $st->{names},
    $st->{values},

    $st->{type} eq 'ROM',

  );

};

# ---   *   ---   *   ---
# ^the binding part

sub var_bind(

  $self,

  $names,
  $values,

  $const,

  @path

) {

  # get ctx
  my $mach   = $self->{mach};
  my $scope  = $mach->{scope};

  unshift @path,$scope->path();


  # make copies
  my @names  = @$names;
  my @values = @$values;

  # out refs to scope
  my $out    = [];


  # ^bind decls
  while(@names && @values) {

    my $name  = shift @names;
    my $value = shift @values;

    $value->{id}    = $name->{raw};
    $value->{const} = $const;

    my $ptr=$mach->bind($value,path=>\@path);
    push @$out,$value->{id}=>$ptr;

  };


  return $out;

};

# ---   *   ---   *   ---
# ^rerun ops

sub var_run($self,$branch) {

  my $st   = $branch->{value};
  my @ptr  = array_values($st->{ptr});

  my @ar=map {
    $self->deref($$ARG)

  } @ptr;

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
# function calls

  rule('$<fcall> value opt-nterm term');

# ---   *   ---   *   ---
# ^post-parse

sub fcall($self,$branch) {

  my ($name,$args)=
    $self->rd_name_nterm($branch);

  $name=$name->deref();

  $branch->{value}={
    fn   => $name,
    args => $args,

  };

  $branch->clear();

};

# ---   *   ---   *   ---
# ^binds fptrs

sub fcall_ctx($self,$branch) {

  # get F is builtin
  my $st = $branch->{value};
  my $fn = codefind(ref $self,$st->{fn});


  # ^nope, lookup user-defined F
  if(! $fn) {

    my $f    = $self->{frame};
    my $path = "$f->{-chier_t}\::$st->{fn}";

    $fn=sub (@args) {
      $self->run_branch($path,@args);

    };

  };

  # ^bind
  $st->{fn}=$fn;

};

# ---   *   ---   *   ---
# ^runs bound F

sub fcall_run($self,$branch) {

  my $st  = $branch->{value};
  my $fn  = $st->{fn};

  # fetch arg values
  my @args=$self->deref_args(
    @{$st->{args}},
    $self->{mach}->get_args()

  );

  # ^call
  $fn->(@args);

};

# ---   *   ---   *   ---
# ^test call

sub test($sum) {
  say ">>$sum";

};

# ---   *   ---   *   ---
# IO

  rule('~<io-key>');
  rule('$<io> io-key nterm term');

# ---   *   ---   *   ---
# ^post-parse

sub io($self,$branch) {

  # unpack
  my ($type,$names,$values)=
    $self->rd_name_nterm($branch);

  $self->defnull($values,@$names);
  $type=uc $type;


  # make [name=>value] pairs
  my @fmat=map {
    (shift @$names) => (shift @$values)

  } 0..@$names-1;

  my $st={
    input  => [],
    output => [],

  };


  # defines input format
  if($type eq 'IN') {
    $st->{input}=\@fmat;

  # ^output format
  } elsif($type eq 'OUT') {
    $st->{output}=\@fmat;


  # ^both, beq from F
  } else {
    nyi('BEQ IO FROM F');

  };


  # ^repack
  $branch->clear();
  $branch->init($st);

};

# ---   *   ---   *   ---
# ^merge and bind

sub io_ctx($self,$branch) {

  $self->io_merge($branch);

  # ^get merged struc
  my $st     = $branch->{value};

  my $input  = $st->{input};
  my $output = $st->{output};

  # ^force defaults
  $st->{iptr}=[];
  $st->{optr}=[];


  # ^bind inputs
  $st->{iptr}=$self->var_bind(

    [array_keys($input)],
    [array_values($input)],

    0,

    'IN',

  ) if @$input;


  # ^bind outputs
  $st->{optr}=$self->var_bind(

    [array_keys($output)],
    [array_values($output)],

    0,

    'OUT',

  ) if @$output;

};

# ---   *   ---   *   ---
# ^the merge part

sub io_merge($self,$branch) {

  state $re=qr{^io$};

  # get all IO branches
  my $par = $branch->{parent};
  my @lv  = $par->branches_in($re);


  # ^merge values
  my @st  = map {$ARG->leaf_value(0)} @lv;

  my @in  = map {@{$ARG->{input}}} @st;
  my @out = map {@{$ARG->{output}}} @st;

  $branch->{value}={
    input  => \@in,
    output => \@out,

  };


  # ^pluck all but first
  my @filt=grep {$ARG ne $branch} @lv;
  $par->pluck(@filt);

  $branch->clear();

};

# ---   *   ---   *   ---
# make parser tree

  our @CORE=qw(lcom hier io var roll fcall);

};

# ---   *   ---   *   ---
# test

my $prog=q[

rune hail;

  in   X    0;

  roll base 1d4;
  var  sum  base+2;

  test sum;

rune fire;
  hail;

];

my $ice=Grammar::Marauder->parse($prog);
$ice->run_branch('RUNE::fire');

# ---   *   ---   *   ---
1; # ret
