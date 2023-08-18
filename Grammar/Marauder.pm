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

    q[roll-key]  => re_pekey(qw(
      roll

    )),

    q[io-key]    => re_pekey(qw(
      in out io

    )),

    q[set-key]   => re_pekey(qw(
      cpy mov wap clr

    )),

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

    type => lc $type,
    name => $name,

    in   => [],
    out  => [],

    from => [],

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

  pop @path;

  my $st  = $branch->{value};
  my $flg = "\*$st->{name}";

  my $ptr = $mach->decl(

    stk   => $flg,
    path  => \@path,

    raw   => [],

  );

  $st->{ptr}=$ptr;

};

# ---   *   ---   *   ---
# ^parent child leaves to
# hier branch
#
# add 'ret' node at bottom

sub hier_sort($self,$branch) {

  state $re=qr{^hier$};

  my @lv=$branch->match_up_to($re);

  $self->hier_input($branch);
  $branch->pushlv(@lv);

  my $ret=$branch->init('ret');

  $ret->fork_chain(

    dom  => ref $self,
    name => 'ret',

    skip => 2,

  );

};

# ---   *   ---   *   ---
# ^adds implicit IO accto
# hierarchical type

sub hier_input($self,$branch) {

  my $mach = $self->{mach};

  my $st   = $branch->{value};
  my $type = $st->{type};

  my $in   = [];
  my $out  = [];


  # ^add magic charge for runes
  if($type eq 'rune') {

    my $key=$mach->vice('bare',raw=>'M');
    my $obj=$mach->vice('obj',raw=>{});

    $in=[$key=>$obj];

  };


  # add io nodes
  my @ar=($in,$out);
  map {

    # make leaf node
    my $io=$branch->init('io');

    # ^grandchild to hold values
    $io->init({
      $ARG => (shift @ar),
      type => $ARG,

    });

    # ^assign proc to leaf
    $io->fork_chain(
      dom  => ref $self,
      name => 'io_ctx',
      skip => 0,

    );

  } qw(in out);

};

# ---   *   ---   *   ---
# reset scope path

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

  # store path to caller
  my $st=$branch->{value};
  push @{$st->{from}},[$scope->path()];


  # ^set path to current branch
  $self->hier_path($branch);


  # get inputs
  my @stk   = $mach->get_args();
     @stk   = $self->deref_args(@stk);


  # ^store
  $self->io_set($branch,'in',@stk);
  $self->io_set($branch,'out');

};

# ---   *   ---   *   ---
# ^overwrites io vars

sub io_set($self,$branch,$key,@values) {

  my $mach  = $self->{mach};
  my $scope = $mach->{scope};

  my @path  = $scope->path();
  my $lv    = $scope->haslv(@path,$key);

  my $st    = $branch->{value};
  my $slot  = $st->{$key};


  # set default values
  $self->io_defaults($slot,$lv)
  if ! @$slot;


  # open new frame
  push @$slot,[];

  my $prev = $slot->[-1];
  my @def  = @{$slot->[0]};


  # ^set
  if($lv) {

    my @ptr=$lv->leafless_values();

    throw_overargs(@path)
    if @ptr < @values;

    # set defaults
    map {
      push @values,$def[$ARG]

    } @values..$#def

    if @values < @def;


    # save old and overwrite
    @$prev=$self->deref_args(@ptr);

    map {
      $ARG->{raw}=(shift @values)

    } @ptr;

  # ^no IO slots, errcheck input
  } elsif(@values) {
    throw_overargs(@path);

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
# copies default values for
# IO var slots

sub io_defaults($self,$slot,$lv) {

  return if ! $lv;

  my @ptr=$lv->leafless_values();
  push @$slot,[$self->deref_args(@ptr)];

};

# ---   *   ---   *   ---
# errme

sub throw_overargs(@path) {

  my $path=join q[::],@path;

  errout(

    q[Too many IO values for fcall ]
  . q[[errtag]:%s],

    lvl  => $AR_FATAL,
    args => [$path],

  );

};

# ---   *   ---   *   ---
# return

sub ret_run($self,$branch) {

  # get output
  my $par=$branch->{parent};
  my @out=$self->io_restore($par,'out');

  # ^push to proc stack
  my $dst=$par->{value}->{ptr};

  my $out=(@out > 1)
    ? [@out]
    : $out[0]
    ;

  push @{$$dst->{raw}},$out;


  # restore previous inputs
  $self->io_restore($par,'in');

  # restore previous path
  my $mach  = $self->{mach};
  my $scope = $mach->{scope};

  my $st    = $par->{value};
  my $from  = pop @{$st->{from}};

  $scope->path(@$from) if $from;


  return $out;

};

# ---   *   ---   *   ---
# ^restores previous values

sub io_restore($self,$branch,$key) {

  my @out   = ();

  my $mach  = $self->{mach};
  my $scope = $mach->{scope};

  my @path  = $scope->path();
  my $lv    = $scope->haslv(@path,$key);


  # get previous values
  my $st    = $branch->{value};
  my $slot  = $st->{$key};

  my $prev  = pop @$slot;


  # ^set
  if($lv && $prev) {

    # get current
    my @ptr=$lv->leafless_values();
    @out=map {$ARG->{raw}} @ptr;

    # ^overwrite
    map {
      $ARG->{raw}=(shift @$prev)

    } @ptr;

  };


  return @out;

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

  # ^set undef to null
  $values //= [];
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
# modifying vars

  rule('~<set-key>');
  rule('$<set> set-key nterm term');

# ---   *   ---   *   ---
# ^post parse

sub set($self,$branch) {

  state $arg_cnt={

    cpy => 2,
    mov => 2,
    wap => 2,

    clr => 1,

  };

  # unpack
  my ($type,$vars)=
    $self->rd_name_nterm($branch);


  $type=lc $type;

  # errchk args
  throw_set($type)
  if @$vars > $arg_cnt->{$type};


  # ^repack
  $branch->{value}={
    type => $type,
    vars => $vars,

  };


  $branch->clear();

};

# ---   *   ---   *   ---
# ^errme

sub throw_set($type) {

  errout(

    q[Too many args for ]
  . q[instruction [ctl]:%s],

    lvl  => $AR_FATAL,
    args => [$type],

  );

};

# ---   *   ---   *   ---
# ^execute

sub set_run($self,$branch) {

  my $st   = $branch->{value};

  my $type = $st->{type};
  my $vars = $st->{vars};


  my ($a,$b)=map {
    $self->deref($ARG,key=>1);

  } @$vars;


  # copy B into A
  if($type eq 'cpy') {
    $a->set($b);

  # ^clear B after copy
  } elsif($type eq 'mov') {
    $a->set($b);
    $b->set($NULL);

  # ^swap B with A
  } elsif($type eq 'wap') {

    my $tmp=$a->get();

    $a->set($b);
    $b->set($tmp);

  # ^clear A
  } else {
    $a->set(0);

  };

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
  my $st=$branch->{value};
  $st->{fn}=$self->fcall_find($st->{fn});

};

# ---   *   ---   *   ---
# ^lookup

sub fcall_find($self,$name) {

  # is builtin
  my $fn=codefind(ref $self,$name);

  # ^nope, lookup user-defined F
  if(! $fn) {

    my $f    = $self->{frame};
    my $path = "$f->{-chier_t}\::$name";

    $fn=sub (@args) {
      return $self->run_branch($path,@args);

    };

  };


  return $fn;

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
  return $fn->(@args);

};

# ---   *   ---   *   ---
# ^as a value expansion

sub fcall_vex($self,$o) {

  my $fn   = $self->fcall_find($o->{proc});
  my $args = $o->{args};

  $o->{raw}=$fn->(@$args);

  return $o->{raw};

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

  $values //= [];
  $self->defnull($values,@$names);

  $type=lc $type;


  # make [name=>value] pairs
  my @fmat=map {
    (shift @$names) => (shift @$values)

  } 0..@$names-1;

  my $st={
    in  => [],
    out => [],

  };


  # defines input format
  if($type eq 'in') {
    $st->{in}=\@fmat;

  # ^output format
  } elsif($type eq 'out') {
    $st->{out}=\@fmat;


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

  my $input  = $st->{in};
  my $output = $st->{out};

  # ^force defaults
  $st->{iptr}=[];
  $st->{optr}=[];


  # ^bind inputs
  $st->{iptr}=$self->var_bind(

    [array_keys($input)],
    [array_values($input)],

    0,

    'in',

  ) if @$input;


  # ^bind outputs
  $st->{optr}=$self->var_bind(

    [array_keys($output)],
    [array_values($output)],

    0,

    'out',

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

  map {
    $ARG->{in}  //= [];
    $ARG->{out} //= [];

  } @st;

  my @in  = map {@{$ARG->{in}}} @st;
  my @out = map {@{$ARG->{out}}} @st;

  # ^set
  $branch->{value}={
    in  => \@in,
    out => \@out,

  };


  # ^pluck all but first
  my @filt=grep {$ARG ne $branch} @lv;
  $par->pluck(@filt);

  $branch->clear();

};

# ---   *   ---   *   ---
# make parser tree

  our @CORE=qw(lcom hier io set var roll fcall);

};

# ---   *   ---   *   ---
# test

my $prog=q[

rune hail;

  in   X    0;
  out  Y    0;

  roll base 1d4;
  var  sum  base+in::X;

  cpy  out::Y,sum;


rune fire;

  out ty;

  cpy M->mag,12;
  cpy ty,M;

];

my $ice = Grammar::Marauder->parse($prog);
my $M   = $ice->run_branch('rune::fire');

fatdump(\$M);

# ---   *   ---   *   ---
1; # ret
