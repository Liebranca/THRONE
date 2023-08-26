#!/usr/bin/perl
# ---   *   ---   *   ---
# RPG MAGIC
# It's enchanting!
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package RPG::Magic;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys/';
  use lib $ENV{'ARPATH'}.'/lib/';

  use Style;
  use Chk;

  use Arstd::IO;
  use Arstd::PM;

  use Shb7;
  use parent 'St';

  use lib $ENV{'ARPATH'}.'/THRONE/';

  use Grammar::peso::meta;
  use Grammar::Marauder;

  use RPG::Bar;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly my $TICK_NOOP=>sub ($M) {};
  Readonly my $GRAM=>'Grammar::Marauder';

# ---   *   ---   *   ---
# GBL

  my $Icemap={};

# ---   *   ---   *   ---
# reads in peso rom and
# transpiles it to perl

sub fread($class,@files) {

  my @args=('perl',-meta=>$PE_META);

  map {

    my $dst="$ARG.pm";
    my $src="$ARG.rom";

    $GRAM->xpile($src,@args,-o=>$dst)
    if Shb7::moo($dst,$src);

  } @files;

};

# ---   *   ---   *   ---
# get effect-specific method

sub AUTOLOAD($self,@args) {

  our $AUTOLOAD;

  my $key   = $AUTOLOAD;
  my $class = ref $self;

  # abort if dstruc
  return if ! autoload_prologue(\$key);


  # abort if method not found
  my $name = "$class\::$self->{name}";
  my $tab  = $self->{tab};

  my $fn   = $tab->{$key}
  or throw_bad_autoload($name,$key);


  return (is_coderef($fn))
    ? $fn->(@args)
    : $fn
    ;

};

# ---   *   ---   *   ---
# cstruc

sub new($class,$name,$crux,%O) {

  # defaults
  $O{beq}   //= [];
  $O{tab}   //= {};
  $O{tick}  //= $TICK_NOOP;


  # handle inheritance
  my $tab={(map {
    my $super=$class->fetch($ARG);
    %{$super->{tab}};

  } @{$O{beq}}),%{$O{tab}}};

  $tab->{tick}=$O{tick};

  # make ice
  my $self=bless {

    name  => $name,
    tab   => $tab,
    crux  => $crux,

  },$class;

  # ^register
  ! exists $Icemap->{$name}
  or throw_redecl($name);

  $Icemap->{$name}=$self;


  return $self;

};

# ---   *   ---   *   ---
# ^errme

sub throw_redecl($name) {

  errout(

    q[Attempt to overwrite '%s' ]
  . q[from the magic periodic table],

    lvl  => $AR_FATAL,
    args => [$name],

  );

};

# ---   *   ---   *   ---
# ^get existing

sub fetch($class,$name) {

  my $out=$Icemap->{$name}
  or throw_no_ice($name);

  return $out;

};

# ---   *   ---   *   ---
# ^errme

sub throw_no_ice($name) {

  errout(

    q[Element '%s' not found in ]
  . q[the magic periodic table],

    lvl  => $AR_FATAL,
    args => [$name],

  );

};

# ---   *   ---   *   ---
# creates an instance of a
# fired group of magical effects

sub charge($class,$spell,$dst,$src,$mag) {

  my @eff=@{$spell->{eff}};


  # ^ice holds spell state
  return bless {

    spell => $spell,

    dst   => $dst,
    src   => $src,

    mag   => $mag,
    dur   => $spell->{dur},

    ahead => [@eff],

    self  => undef,
    prev  => [],


  },$class;

};

# ---   *   ---   *   ---
# ^execute next effect

sub get_next($M) {

  $M->{self}=shift @{$M->{ahead}};
  $M->{self}->{crux}->($M);

  push @{$M->{prev}},$M->{self};

};

# ---   *   ---   *   ---
1; # ret
