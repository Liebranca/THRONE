# ECONOMY IS CURRENCY

`RPG::Eco`, at it's core, is just a counter. You want to go up without going down. Or rather, go up more than you do down -- gain versus loss, more commonly known as __trade__.

The mechanisms for the management of one resource apply to all, with different considerations on what constitutes a good trade being relegated almost entirely to the environment and haggling dice rolls.

# MECHANISM

By arbiter decision, value is based on levels of manufacture and scarcity of materials. This is an oversimplification of reality, as game logic oft is.

Every item is considered a resource; one resource is made up of components. Components can be crafted into a new item, and items can be decomposed back into their elements.

As mentioned, value of an item is decided on three factors:

1. How commonplace the materials of an item are at a given location.
2. The amount of crafting steps required to make the item.
3. Crafting and haggling dice rolls.

But these are still *just* counters. What `RPG::Eco` does is manage exchange and conversion of resources between containers.

Each container is owned by an actor or faction; economic activity is driven by their goals. For instance: the government requires a given resource for coinage, and so they hire craftmen, miners and caravans to restock until the need for coins or raw materials is satisfied.

The three basic types of economic activity would then be extraction, transport, and manufacture. These exist separate of `RPG::Eco` itself -- they merely interact with the system through an interface.

Extraction means exploiting some natural resource, eg farming, fishing, digging for ores and chopping down trees. Transport should be self-explanatory: moving the resources around from one container to another.

Manufacture, then, is all activity surrounding the transformation of raw materials into goods, from pottery to jewelry and grand weapons of war.

All of this is facilitated by a mere increase or decrease of counters; it can be summarized as converting one number into another.

The interesting thing, then, is the rules for how the numbers can be manipulated. Is robbery allowed? Do you require an anvil to forge a sword? What about smelters?

# INTERFACE

A container `$c` can be created via `RPG::Eco->new()` and resources can be modified directly through `$c->grant()`. A basic implementation of resource extraction could look something like this:

```perl

# resource container
my $mine_stock = RPG::Eco->new('Copper Mine');

# create a worker
my $miner=RPG::Actor->new(

  name=>'Don Pickaxe',

  skill=>{
    mining => 4,

  },

  # will dig for ore if copper in
  # stock drops below value
  goal=>[

    \&go_mining=>sub($stock) {
      $stock->have('copper',200);

    },

  ],

);

# ---   *   ---   *   ---
# given location as some coordinate
# marking the area where ores are found

sub go_mining($miner,$stock,$loc) {

  if(!$miner->within($loc)) {
    $miner->travel_to($loc);

  } else {

    my $base   = 10;
    my $res    = 'copper';

    my $skill  = $miner->{skill}->{mining};
    my $chance = $miner->roll("${skill}d8");

    $stock->grant($res=>$base*$chance)

  };

};

# ---   *   ---   *   ---
# check stock

my ($fn,$goal)=(
  $miner->{goal}->[0],
  $miner->{goal}->[1],

);

# goal is not satisfied
if(!$goal->($mine_stock)) {
  $fn->($miner,$mine_stock,$mine_loc);

};

```

Actors are driven to action by simplistic counter checks; the conditions within whichever function they must run to achieve said goal then take care of modifying the counters that decide whether the action will be repeated next turn.

An additional layer of depth is provided by the `craft`, `smelt` and `trade` methods available to `RPG::Eco` containers. In brief:

- `craft` attempts to create a resource from the ones available in a container.
- `smelt` walks back the process, making base resources from a crafted one.
- `trade` exchanges resources between containers.

These are minimalistic mechanics meant to provide the user with a greater degree of freedom to implement whichever systems they want, realistic or not.

`trade` could just be used to buy and sell goods, but it could also be used to implement robbery and stashes. I am insistent on the fact that these are all *just* counters because that's how it must be thought of: the fun is in making actors in a simulation read and manipulate these numbers.

Ultimately, our NPCs are incapable of actually caring. So make it *seem* like they do. Have your actors read the numbers, and have the readings affect their behaviour.
