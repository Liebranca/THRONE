#!/usr/bin/perl
# ---   *   ---   *   ---
# MARAUDER IO
# Communications!
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package Grammar::Marauder::io;

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
  $PE_STD->use_value();
  $PE_STD->use_eye();

  $MAR_STD->uses('var');

# ---   *   ---   *   ---
# GBL

  our $REGEX={

    q[io-key]=>re_pekey(qw(
      in out io

    )),

  };

# ---   *   ---   *   ---
# parser rules

  rule('~<io-key>');
  rule('$<io> io-key nterm term');

# ---   *   ---   *   ---
# ^post-parse

sub io($self,$branch) {

  # unpack
  my ($type,$names,$values)=
    $self->rd_name_nterm($branch);

  # ^set undef to null
  $self->{mach}->defnull(
    'void',\$values,@$names

  );

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

  return if ! @{$branch->{leaves}};


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
# outs codestr

sub io_xlate($self,$branch) {

  my $st  = $branch->{value};
  my @out = ();

  map {
    push @out,$$ARG->pl_xlate();

  } array_values($st->{iptr});

  $st->{pl_xlate}='(' . (join q[,],@out) . ')';

};

# ---   *   ---   *   ---
# do not make a parser tree

  our @CORE=qw();

# ---   *   ---   *   ---

}; # BEGIN

# ---   *   ---   *   ---
1; # ret
