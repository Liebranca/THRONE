#!/usr/bin/perl
# --- * --- * ---
# ST
# Cool tricks
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# --- * --- * ---

package RPG::St;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys';

  use Style;
  use Chk;
  use Fmat;

  use Arstd::String;
  use Arstd::IO;

  use parent 'St';

# --- * --- * ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR = 'IBN-3DILA';

# --- * --- * ---
# ROM

  sub Reg_Vars($class) {[]};

# --- * --- * ---
# proc input

sub VOCIFERATE($slurp,%O) {

  my @voces=();

  while(@$slurp) {

    my $vociferation  = shift @$slurp;
    my ($key,@values) = @{(shift @$slurp)};

    # defaults
    if(!defined $O{$key}) {
      $O{$key}//=\@values;

    # overwrit
    } else {
      $vociferation = shift @{$O{$key}};
      $O{$key}      = shift @{$O{$key}};

    };

    # strip
    $vociferation=~ s[^\s*|\s*$][]sxmg;

    # get ptrs
    my $tail = \$O{$key}->[ 0];
    my $head = \$O{$key}->[-1];
    my @requ = ($tail,$head,$O{$key});

    # validate input
    my $vox={
      prelude => $vociferation,
      value   => fmatchk(@requ),

    };

    $O{$key}=$vox->{value};

    push @voces,$vox;

  };

  $O{-prich}=sub {
    my $s=vox_join(@voces);
    linewrap(\$s,80);

    say $s;

  };

  return %O;

};

# ---   *   ---   *   ---
# creates printout of vociferated RPG element

sub vox_join(@voces) {

  my @me=();

  for my $vox(@voces) {

    my $repl=(is_arrayref($vox->{value}))
      ? vox_list($vox->{value})
      : $vox->{value}
      ;

    push @me,q[ ] if @me

    && $me[-1]=~ m[\w$]
    && $vox->{prelude}=~ m[^\w]

    ;

    push @me,$vox->{prelude},q[ ],$repl;

  };

  return join q[],@me;

};

# ---   *   ---   *   ---
# this, this and that

sub vox_list($ar) {

  my $out=shift @$ar;

  while(@$ar>1) {
    $out.=q[, ].(shift @$ar);

  };

  if(@$ar==1) {
    $out.=q[ and ].(shift @$ar);

  };

  return $out;

};

# ---   *   ---   *   ---
# validates qw value-lists

sub fmatchk(@requ) {

  my ($tail,$head,$values)=@requ;

  my $out=(
     is_single(@requ)
  || is_list(@requ)
  || is_qwstr(@requ)

  ) ? $$tail
    : throw_unrecog($values)
    ;

  return $out;

};

# ---   *   ---   *   ---
# ^errmes

sub throw_unrecog($values) {

  my $me='['.(join q[,],$values).']';

  errout(
    q[Unrecognized format;%s],

    args => [$me],
    lvl  => $AR_FATAL,

  );

};

# ---   *   ---   *   ---
# .key => value

sub is_single($tail,$head,$values) {

  my $out=$tail eq $head;
  $$tail=eval($$tail) if $out;

  return $out;

};

# ---   *   ---   *   ---
# .key => [list]

sub is_list($tail,$head,$values) {

  my $out=0;

  # first is whole value
  if($$tail=~ m{
    (?: ^'[^']+'$)
  | (?: \d+)

  }x) {

    $$tail = [map {eval($ARG)} @$values];
    $out   = 1;

  };

  return $out;

};

# ---   *   ---   *   ---
# .key => 'stringify array of tokens'

sub is_qwstr($tail,$head,$values) {

  my $out=0;

  # '*
  my $begstr=
      ($$tail=~ m[^'])
  && !($$tail=~ m['$])
  ;

  # ^iv: *'
  my $endstr=
      ($$head=~ m['$])
  && !($$head=~ m[^'])
  ;

  # one and not both
  throw_unclosed_q($values)
  if $begstr && !$endstr
  || $endstr && !$begstr
  ;

  # both
  if($begstr && $endstr) {
    $$tail = eval(join q[ ],@$values);
    $out   = 1;

  };

  return $out;

};

# ---   *   ---   *   ---
# ^errmes

sub throw_unclosed_q($values) {

  my $me='['.(join q[,],@$values).']';

  errout(
    q[Unclosed quotes on Reg_Vars;%s],

    args => [$me],
    lvl  => $AR_FATAL,

  );

};

# ---   *   ---   *   ---

sub subclan($class,%O) {

  my ($usage,@slurp) = @{$class->Reg_Vars()};
  my %defaults       = eval($usage.q[(\@slurp,%O)]);

  $defaults{-prich}->();

};

# --- * --- * ---
1; # ret
