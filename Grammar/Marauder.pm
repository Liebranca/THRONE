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
  use Arstd::IO;

  use Tree::Grammar;

  use lib $ENV{'ARPATH'}.'/avtomat/hacks/';
  use Shwl;

  use lib $ENV{'ARPATH'}.'/avtomat/';

  use Lang;
  use Grammar;

  use lib $ENV{'ARPATH'}.'/THRONE/';
  use RPG::Dice;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.1;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

BEGIN {

  sub Frame_Vars($class) { return {

#    -creg   => undef,
#    -cclan  => 'non',
#    -cproc  => undef,

    %{Grammar->Frame_Vars()},

#    -passes => ['_ctx','_opz','_run'],

  }};

# ---   *   ---   *   ---

  our $REGEX={

    term => qr{(?: \n|\s|;\s*|$)},

    name => qr{([\w][\w\-]*)},
    dice => $RPG::Dice::IRE,

    ncolon => qr{[^:]+},

    degree => Lang::eiths(

      [qw(

        '   "   ^
        ^'  ^"  *
        *'  *"  *^

        *^' *^" **

      )],

      escape=>1

    ),

#    mode => Lang::eiths(
#
#      [qw(
#
#        self touch target
#
#      )],
#
#      insens=>1
#
#    ),

    q[list-item] => qr{(?<! [>\\])\*}x,
    q[nlist-item] => qr{

      ( >\* | \\ \* | [^;*] )+

    }x,

    q[attr-token] => qr{

      (?: \[ (?<calc> (.?)+ ) \])
    | (?<item> [^\s]+)

    }x,

  };

# ---   *   ---   *   ---
# detecting lists

  rule('~<list-item>');
  rule('~<nlist-item>');
  rule('$<attr> list-item nlist-item');

  rule('+<attr-list> &list_flatten attr');

# ---   *   ---   *   ---
# ^post-parse

sub attr($self,$branch) {

  my $st=$branch->bhash();
  $branch->clear();

  strip(\$st->{q[nlist-item]});

  my $v=$st->{q[nlist-item]};
  $self->attr_tok($branch,\$v);

};

# ---   *   ---   *   ---
# ^helper

sub attr_tok($self,$dst,$vref) {

  state $re=$REGEX->{q[attr-token]};
  my $anchor=$dst;

  # tokenize line
  while($$vref=~ s[$re][]) {

    my $tok;

    # recurse
    if($+{calc}) {

      $tok=$+{calc};

      my $branch=$anchor->{leaves}->[-1];
      $branch//=$anchor;

      $self->attr_tok($branch,\$tok);

      next;

    # common token
    } else {

      $tok=$+{item};
      my $branch=$anchor->init($tok);

      if($tok=~ m{\[}) {
        $anchor=$branch;
        $anchor->{value}='$[]';

      } elsif($tok=~ m{\]}) {
        $anchor=$anchor->{parent};
        $branch->{parent}->pluck($branch);

      };

    };

  };

};

# ---   *   ---   *   ---
# ^read helper

sub attr_rd($self,$branch) {

  my $st={

    call => $NULLSTR,

    argc => 0,
    argv => [],

    ltok => $NULLSTR,

  };

  my @pending=@{$branch->{leaves}};

  for my $leaf(@pending) {

    my $tok = $leaf->{value};
    my @lv  = @{$leaf->{leaves}};

    # recurse
    $self->attr_rd($leaf) if @lv;

    # handle iv-call
    if($tok eq '->*') {
      push @{$st->{argv}},$st->{call};
      $st->{call}=$st->{ltok};

    } elsif(! $st->{call}) {
      $st->{call}=$tok;

    } else {
      push @{$st->{argv}},$tok;

    };

    $st->{ltok}=$tok;

  };

};

# ---   *   ---   *   ---
# ^start of list

  rule('%<colon=:>');
  rule('~<ncolon>');

  rule(q[

    $<attr-name>
    &attr_name

    ncolon colon

  ]);

# ---   *   ---   *   ---
# ^post parse

sub attr_name($self,$branch) {

  my $st=$branch->bhash();

  $branch->clear();
  $branch->{value}="$st->{ncolon}";

};

# ---   *   ---   *   ---

  rule('$<spell-def> attr-name attr-list');

  rule('~<term>');
  rule('~<name>');
  rule('~<degree>');

# ---   *   ---   *   ---

  rule('$%<beg-parens=\(>');
  rule('$?~<dice>');
  rule('$%<end-parens=\)>');

  rule(q[

    $<spell-dice>
    &spell_dice

    beg-parens
    dice

    end-parens

  ]);

sub spell_dice($self,$branch) {

  my $st=$branch->bhash();
  $st->{dice}//='d1';

  $branch->clear();

  $branch->{value}='dice';
  $branch->init($st->{dice});

};

# ---   *   ---   *   ---

  rule(q[

    $<spell-decl>

    name
    spell-dice
    degree

  ]);

  rule(q[

    |<expr-list>
    &clip

    spell-decl spell-def

  ]);

  rule('<expr> &clip expr-list term');

  our @CORE=qw(expr);

# ---   *   ---   *   ---

}; # BEGIN

# ---   *   ---   *   ---
# test

  my $prog = q[

damage () **

  args:
    * self
    * d
    ;

  apply:
    * dec self->HP [
        [d]
      / [self ->* resist]

    ];

attack (d4) '

  args:
    * caster
    * target
    * d
    ;

];

#  on touch:
#
#    * damage target [
#
#        [d/2]
#
#      + [caster ->* weapon]
#      + [caster ->* tactic]
#
#    ];

  my $ice  = Grammar::Marauder->parse("$prog");

  $ice->{p3}->prich();

# ---   *   ---   *   ---
1; # ret
