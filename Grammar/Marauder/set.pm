#!/usr/bin/perl
# ---   *   ---   *   ---
# MARAUDER SET
# cpy,mov,wap,clr
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package Grammar::Marauder::set;

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
  $PE_STD->use_value();
  $PE_STD->use_eye();

  fvars($MAR_STD);

# ---   *   ---   *   ---
# GBL

  our $REGEX={

    q[set-key]=>re_pekey(qw(
      cpy mov wap clr

    )),

  };



# ---   *   ---   *   ---
# parser rules

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
# out codestr

sub set_perl_xlate($self,$branch) {

  my $st    = $branch->{value};

  my $mach  = $self->{mach};
  my $scope = $mach->{scope};

  my $type  = $st->{type};
  my $vars  = $st->{vars};

  my $out   = $NULLSTR;

  if($type eq 'clr') {

    my $var = $vars->[0];
    my $id  = "\$$var->{id}";

    my $raw = $var->get();

    if(is_hashref($raw)) {
      $raw={};

    } elsif(is_arrayref($raw)) {
      $raw=[];

    } elsif($var->{type} eq 'num') {
      $raw=0;

    } elsif($var->{type} eq 'str') {
      $raw=$NULLSTR;

    } else {
      $raw=$NULL;

    };

    $out="$id=$raw;";

  } else {

    my ($a,$b)=@$vars;

    my ($dst)=(! $a->{id})
      ? $a->perl_xlate(id=>0,scope=>$scope)
      : $a->perl_xlate(value=>0,scope=>$scope)
      ;

    my ($value)=$b->perl_xlate(
      id=>0,scope=>$scope

    );


    if($type eq 'cpy') {
      $out="$dst=$value;";

    } elsif($type eq 'mov') {
      $out="$dst=$value;$value=undef;";

    } else {
      $out="($dst,$value)=($value,$dst);";

    };

  };

  $branch->{perl_xlate}=$out;

};

# ---   *   ---   *   ---
# do not generate a parser tree!

  our @CORE=qw();

# ---   *   ---   *   ---

}; # BEGIN

# ---   *   ---   *   ---
1; # ret
