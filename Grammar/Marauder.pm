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

    %{Grammar->Frame_Vars()},
    -passes => ['_ctx','_opz','_run'],

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

  rule('+<attr-list> attr');

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

  state $re     = $REGEX->{q[attr-token]};
  my    $anchor = $dst;

  # tokenize line
  while($$vref=~ s[$re][]) {

    my $tok;

    # recurse
    if($+{calc}) {

      $tok=$+{calc};

      my $branch=$anchor->{leaves}->[-1];
      $branch//=$anchor;

      $self->attr_tok($branch,\$tok);

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

    say $tok;

  };

};

# ---   *   ---   *   ---
# context pass

sub attr_ctx($self,$branch) {

  my $st=$self->attr_rd($branch);

  $branch->clear();
  $branch->{value}=$st;

};

# ---   *   ---   *   ---
# ^read helper

sub attr_rd($self,$branch) {

  my $st={

    call => $NULLSTR,

    argc => 0,
    argv => [],

    ltok => $NULLSTR,
    tree => [],

  };

  my @pending=@{$branch->{leaves}};

  for my $leaf(@pending) {

    my $tok = $leaf->{value};
    my @lv  = @{$leaf->{leaves}};

    # recurse
    push @{$st->{tree}},
      $self->attr_rd($leaf)

    if @lv;

    # handle iv-call
    if($tok eq '->*') {
      push @{$st->{argv}},$st->{call};
      $st->{call}=$NULLSTR;

    } elsif(! $st->{call}) {
      $st->{call}=$tok;

    } else {
      push @{$st->{argv}},$tok;

    };

    $st->{ltok}=$tok;

  };

  return $st;

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
# combo

  rule(q[

    $<spell-def>
    &spell_def

    attr-name attr-list

  ]);

# ---   *   ---   *   ---
# ^post-parse

sub spell_def($self,$branch) {

  my @lv     = @{$branch->{leaves}};
  my ($name) = $branch->pluck($lv[0]);

  $branch->{value}=$name->{value};
  $lv[1]->flatten_branch();

};

# ---   *   ---   *   ---

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
# combo

  rule(q[

    $<spell-decl>
    &spell_decl

    name
    spell-dice
    degree

  ]);

# ---   *   ---   *   ---
# ^post-parse

sub spell_decl_ctx($self,$branch) {

  # get nodes up to next hierarchical
  my @out=$branch->{parent}->match_until(
    $branch,qr{^spell-decl$}

  );

  # ^all remaining on fail
  @out=$branch->{parent}->all_from(
    $branch

  ) if ! @out;

  $branch->pushlv(@out);

};

# ---   *   ---   *   ---

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

ajira () *^"

  spells:
    * thunder
    * plasma-cannon
    ;

];

# ---   *   ---   *   ---

#  props:
#    * character
#    * human female
#    * portrait $24
#    ;
#
#  effects:
#    * ignition-mastery
#    * farsight
#    * surge
#    * madrias-curse
#    ;
#
#  weapon:
#    * martyrdom
#    ;
#
#  apparel:
#    * leather-gloves
#    * black-hood
#    * cotton-cape
#    * hardy-chains
#    * snow-shoes
#    ;

# ---   *   ---   *   ---

  my $ice  = Grammar::Marauder->parse(
    "$prog",-r=>2

  );

#  $ice->{p3}->prich();

# ---   *   ---   *   ---
1; # ret
