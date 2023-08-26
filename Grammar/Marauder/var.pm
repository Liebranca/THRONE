#!/usr/bin/perl
# ---   *   ---   *   ---
# MARAUDER VAR
# Numbers!
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package Grammar::Marauder::var;

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

  use Grammar;
  use Grammar::peso::std;

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

# ---   *   ---   *   ---
# GBL

  our $REGEX={

    q[var-key]  => re_pekey(qw(
      var rom

    )),

  };

# ---   *   ---   *   ---
# parser rules

  rule('~<var-key>');
  rule('$<var> var-key nterm term');

# ---   *   ---   *   ---
# ^post parse

sub var($self,$branch) {

  # unpack
  my ($type,$names,$values)=
    $self->rd_name_nterm($branch);

  # ^set undef to null
  $self->{mach}->defnull(
    'void',\$values,@$names

  );


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
# out codestr

sub var_perl_xlate($self,$branch) {

  my $st   = $branch->{value};

  my @args = map {
    my ($id,$value)=$$ARG->perl_xlate(
      scope=>$self->{mach}->{scope}

    );

    $value="\\($value)" if $$ARG->is_ptr();

    "my $id=$value;\n";

  } array_values($st->{ptr});

  $branch->{perl_xlate}=join $NULLSTR,@args;

};

# ---   *   ---   *   ---
# do not make a parser tree!

  our @CORE=qw();

# ---   *   ---   *   ---

}; # BEGIN

# ---   *   ---   *   ---
1; # ret
