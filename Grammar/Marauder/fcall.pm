#!/usr/bin/perl
# ---   *   ---   *   ---
# MARAUDER FCALL
# Incantations
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package Grammar::Marauder::fcall;

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
  use lib $ENV{'ARPATH'}.'/THRONE/';

  use Grammar;
  use Grammar::peso::std;
  use Grammar::Marauder::std;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.2;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

BEGIN {


  # beqs
  $PE_STD->use_common();
  $PE_STD->use_value();
  $PE_STD->use_eye();

  fvars($MAR_STD);

# ---   *   ---   *   ---
# GBL

  our $REGEX={};

# ---   *   ---   *   ---
# parser rules

  rule('$<fcall> expr opt-nterm term');

# ---   *   ---   *   ---
# ^post-parse

sub fcall($self,$branch) {

  # flatten expression subtree
  $self->expr_collapse($branch);

  # ^unpack
  my ($fn,$args)=
    $self->rd_name_nterm($branch);


  # member calls are parsed as
  # compound operators; we use
  # value type to identify them
  my $type=$fn->{type};
  my $memf=$type eq 'ops';


  # ^non member calls use a plain
  # bareword rather than an obj
  $fn=(! $memf)
    ? $fn->deref()
    : $fn
    ;

  $args //= [];


  # ^repack
  $branch->{value}={

    memf => $memf,

    fn   => $fn,
    args => $args,

    xfn  => undef,

  };


  $branch->clear();


  # ^fork member calls
  if($memf) {

    $branch->fork_chain(
      dom  => ref $self,
      name => 'm_fcall',
      skip => 0,

    );

  };

};

# ---   *   ---   *   ---
# ^binds fptrs

sub fcall_ctx($self,$branch) {

  my $st=$branch->{value};

  $self->fcall_args($branch,$st->{args});
  $st->{xfn}=$self->fcall_find($st->{fn});

};

# ---   *   ---   *   ---
# ^adds implicit arguments

sub fcall_args($self,$branch,$args) {

  my $mach = $self->{mach};

  my $f    = $self->{frame};
  my $type = $f->{-chier_t};

  if($type eq 'rune') {

    unshift @$args,$mach->vice(
      'bare',raw=>'M',

    );

  };

};

# ---   *   ---   *   ---
# ^F lookup

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
  my $fn  = $st->{xfn};


  # fetch arg values
  my @args=$self->array_ptr_deref(
    @{$st->{args}},
    $self->{mach}->get_args()

  );

  # ^call
  return $fn->(@args);

};

# ---   *   ---   *   ---
# ^as a value expansion
#
# TODO: handle member calls

sub fcall_vex($self,$o) {

  my $fn   = $self->fcall_find($o->{proc});
  my $args = $o->{args};

  $o->{raw}=$fn->(@$args);

  return $o->{raw};

};

# ---   *   ---   *   ---
# ^runs member F

sub m_fcall_run($self,$branch) {

  my $st=$branch->{value};

  # get member F wrapper
  my $fn=$self->deref($st->{fn});
     $fn=$fn->get();

  # ^fetch arg values
  my @args=$self->array_ptr_deref(
    @{$st->{args}}

  );


  # ^call
  return $fn->(@args);

};

# ---   *   ---   *   ---
# outs codestr

sub fcall_perl_xlate($self,$branch) {

  my $st    = $branch->{value};

  my $fn    = $st->{fn};
  my $args  = $st->{args};

  my $mach  = $self->{mach};
  my $scope = $mach->{scope};

  my $rhs   = join q[,],map {
    $ARG->perl_xlate(id=>0,scope=>$scope)

  } @$args;


  $branch->{perl_xlate}="$fn($rhs);\n";

};

# ---   *   ---   *   ---
# ^outs codestr for member

sub m_fcall_perl_xlate($self,$branch) {

  my $st    = $branch->{value};

  my $fn    = $st->{fn};
  my $args  = $st->{args};

  my $mach  = $self->{mach};
  my $scope = $mach->{scope};


  my ($lhs) = $fn->perl_xlate(id=>0,scope=>$scope);
  my $rhs   = join q[,],map {
    $ARG->perl_xlate(id=>0,scope=>$scope)

  } @$args;


  $branch->{perl_xlate}="$lhs($rhs);\n";

};

# ---   *   ---   *   ---
# do not make a parser tree!

  our @CORE=qw();

# ---   *   ---   *   ---

}; # BEGIN

# ---   *   ---   *   ---
1; # ret
