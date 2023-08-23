#!/usr/bin/perl
# ---   *   ---   *   ---
# MARAUDER HIER
# Hierarchicals and their
# ramifications ;>
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package Grammar::Marauder::hier;

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

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

BEGIN {


  # beqs
  $PE_STD->use_common();
  $PE_STD->use_eye();

  fvars(

    $MAR_STD,

    -chier_t => undef,
    -chier_n => undef,

  );

# ---   *   ---   *   ---
# GBL

  our $REGEX={

    q[hier-key] => re_pekey(qw(
      rune spell

    )),

  };

# ---   *   ---   *   ---
# parser rules

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

  my $mach  = $self->{mach};
  my $scope = $mach->{scope};

  my @path  = $self->hier_path($branch);

  $scope->decl_branch($branch,@path);

  $self->hier_sort($branch);

  $self->hier_vars($branch);
  $self->hier_input($branch);


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

  # parenting
  my @lv=$branch->match_up_to($re);
  $branch->pushlv(@lv);


  # implicit return at end of branch
  my $ret=$branch->init('ret');

  $ret->fork_chain(

    dom  => ref $self,
    name => 'ret',

    skip => 1,

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
  my @ar=($out,$in);

  map {

    # make leaf node
    my $io=$branch->init('io',unshift_leaves=>1);

    # ^grandchild to hold values
    $io->init({
      $ARG => (shift @ar),
      type => $ARG,

    });

  } qw(out in);


  # ^run merge proc on leaves
  $branch->{leaves}->[0]->fork_chain(
    dom  => ref $self,
    name => 'io',
    skip => 1,

  );

};

# ---   *   ---   *   ---
# ^adds implicit vars accto
# hierarchical type

sub hier_vars($self,$branch) {

  my $mach = $self->{mach};

  my $st   = $branch->{value};
  my $type = $st->{type};

  my $vars = [];


  # ^add magic charge for runes
  if($type eq 'rune') {

    my $names  = [];
    my $values = [];

    map {

      my $name  = $ARG;
      my $value = "M->$ARG";

      # ^ipret
      ($name,$value)=
        $self->rd_nterm("$name $value");

      push @$names,@$name;
      push @$values,@$value;

    } qw(target caster dice);


    push @$vars,{

      type   => 'var',

      names  => $names,
      values => $values,

      ptr    => [],

    };

  };


  # add var nodes
  map {

    # make leaf node
    my $var=$branch->init($ARG,unshift_leaves=>1);

    # ^run ctx proc
    $var->fork_chain(

      dom  => ref $self,
      name => 'var',
      skip => 1,

    );


  } @$vars;

};

# ---   *   ---   *   ---
# reset scope path

sub hier_path($self,$branch) {

  # get ctx
  my $f  = $self->{frame};
  my $st = $branch->{value};

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
  my @stk=$mach->get_args();
     @stk=$self->array_ptr_deref(@stk);


  # ^store
  $self->hier_io_set($branch,'in',@stk);
  $self->hier_io_set($branch,'out');

};

# ---   *   ---   *   ---
# ^overwrites io vars

sub hier_io_set($self,$branch,$key,@values) {

  my $mach  = $self->{mach};
  my $scope = $mach->{scope};

  my @path  = $scope->path();
  my $lv    = $scope->haslv(@path,$key);

  my $st    = $branch->{value};
  my $slot  = $st->{$key};


  # set default values
  $self->hier_io_defaults($slot,$lv)
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
    @$prev=$self->array_ptr_deref(@ptr);

    map {
      $ARG->{raw}=(shift @values)

    } @ptr;


  # ^no IO slots, errcheck input
  } elsif(@values) {
    throw_overargs(@path);

  };

};

# ---   *   ---   *   ---
# ^get

sub hier_io_get($self,$branch,$key) {

  my $mach  = $self->{mach};
  my $scope = $mach->{scope};

  my @path  = $scope->path();
  my $lv    = $scope->haslv(@path,$key);

  my $st    = $branch->{value};
  my $slot  = $st->{$key};

  my @out   = ($lv)
    ? $lv->leafless_values()
    : ()
    ;

  return @out;

};

# ---   *   ---   *   ---
# copies default values for
# IO var slots

sub hier_io_defaults($self,$slot,$lv) {

  return if ! $lv;

  my @ptr=$lv->leafless_values();
  push @$slot,[$self->array_ptr_deref(@ptr)];

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
  my @out=$self->hier_io_restore($par,'out');

  # ^push to proc stack
  my $dst=$par->{value}->{ptr};

  my $out=(@out > 1)
    ? [@out]
    : $out[0]
    ;

  push @{$$dst->{raw}},$out;


  # restore previous inputs
  $self->hier_io_restore($par,'in');

  # restore previous path
  my $mach  = $self->{mach};
  my $scope = $mach->{scope};

  my $st    = $par->{value};
  my $from  = pop @{$st->{from}};

  $scope->path(@$from) if $from;
  $self->{c3}->jmp(undef);


  return $out;

};

# ---   *   ---   *   ---
# ^restores previous values

sub hier_io_restore($self,$branch,$key) {

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
# outs codestr

sub hier_pl_xlate($self,$branch) {

  my $st=$branch->{value};
  $branch->{pl_xlate}="sub $st->{name}";

  # set path to current branch
  $self->hier_path($branch);

};

sub ret_pl_xlate($self,$branch) {

  my $par = $branch->{parent};
  my @ptr = $self->hier_io_get($par,'out');

  my @id  = map {
    $ARG->pl_xlate(value=>0)

  } @ptr;


  $branch->{pl_xlate}=
    "return (" . (join q[,],@id) . ");\n};";

};

# ---   *   ---   *   ---
# do not generate a parser tree!

  our @CORE=qw();

# ---   *   ---   *   ---

}; # BEGIN

# ---   *   ---   *   ---
1; # ret
