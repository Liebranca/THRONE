#!/usr/bin/perl
# ---   *   ---   *   ---
# MARAUDER STD
# Magical boilerpaste
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package Grammar::Marauder::std;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;
  use Arstd::PM;

# ---   *   ---   *   ---
# adds to your namespace

  use Exporter 'import';
  our @EXPORT=qw($MAR_STD);

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  sub Frame_Vars($class) { return {

    %{Grammar->Frame_Vars()},
    -passes  => ['_ctx','_walk','_run'],

  }};


  Readonly our $MAR_STD=>
    'Grammar::Marauder::std';

# ---   *   ---   *   ---
# beqs list of packages

sub uses($class,@pkg) {

  my $dst  = caller;
  my $base = 'Grammar::Marauder';

  map {

    my $pkg="$base\::$ARG";

    cload($pkg);
    submerge(

      [$pkg],

      subex => qr{^throw_},
      xdeps => 1,

      main  => $dst

    );


    $dst->dext_rules($pkg,$ARG);

  } @pkg;

};

# ---   *   ---   *   ---
1; # ret
