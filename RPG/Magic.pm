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

  use Arstd::Path;
  use Arstd::IO;
  use Arstd::PM;

  use Shb7;
  use parent 'St';

  use lib $ENV{'ARPATH'}.'/THRONE/';

  use Grammar::peso::meta;
  use Grammar::Marauder;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.3;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly my $GRAM=>'Grammar::Marauder';

# ---   *   ---   *   ---
# GBL

  my $Icemap={};

# ---   *   ---   *   ---
# reads in peso rom and
# transpiles it to perl
#
# loads in subs decl'd in
# those rom files to Icemap

sub fread($class,@files) {

  my @args=('perl',-meta=>$PE_META);

  map {

    my $fname = basef($ARG);
    my $dir   = dirof(__FILE__);

    my $dst   = "$dir/Runes/$fname.pm";
    my $src   = "$ARG.rom";

    my $pkg   = "RPG::Runes::$fname";


    # regenerate file if need
    $GRAM->xpile(

      $src,@args,

      -o   => $dst,
      -pkg => $pkg,

    ) if Shb7::moo($dst,$src);


    # ^load file and get coderefs
    cload($pkg);
    my %subs=subsof([$pkg]);

    $Icemap->{$fname}={map {
      my $fn="$pkg\::$ARG";
      $ARG=>\&$fn;

    } keys %subs};


  } @files;

};

# ---   *   ---   *   ---
# ^get existing

sub fetch($class,@path) {

  my $cref=$Icemap;

  map {
    $cref=$cref->{$ARG}

  } @path;

  defined $cref or throw_no_ice(@path);


  return $cref;

};

# ---   *   ---   *   ---
# ^errme

sub throw_no_ice(@path) {

  my $name=join q[ ],@path;

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

    spell  => $spell,

    target => $dst,
    caster => $src,

    dice   => $mag,
    tick   => 0,

    dur    => $spell->{dur},

    ahead  => [@eff],

    self   => undef,
    prev   => [],


  },$class;

};

# ---   *   ---   *   ---
# ^execute next effect

sub get_next($M) {

  $M->{self}=shift @{$M->{ahead}};
  $M->{self}->($M);

  push @{$M->{prev}},$M->{self};

};

# ---   *   ---   *   ---
1; # ret
