# REASONING

The incorporation of a frame, that is, a container of instances that abstracts away the common notion of the constructor, means that a chunk of a program's memory can be utilized solely for the state of a clan or subclan component.

When `RPG::Dice::roll` with a wrath of 2d4, a copy of dice is required for this specific roll. If at any point in time the exact same roll is required, the construct is already cached in the frame's memory.

A frame turns a module into a matrix of instances, as evidenced by `AR::Tree`. With `roll` as sole entry point, `RPG::Dice` becomes as abstract as yet another IO component along a pipeline.

# OBSERVATION

It is self-managing: the user only ever interacts with the module for direct response. Thus, the clan in it's entirety can be summarized in a brief chain:

```$

reg frame;
  RPG::Dice tab instas;

proc fetch;

  on    self
  from  frame.instas;

        out self;
  or    out {$CLAN ->* new};

  off;

proc roll;
  in    self;
  fetch self;

  ...;


```

Which grants us:

```$

'2d4' ->* roll;

```

With `wed -ivio`, this would equal `roll 2d4`, which is a perfect construct; brief and no ambiguity to it's function or purpose.

Furthermore, cache can be made ahead of time, due to the nature of the inputs. Thus,

```$

# die generated on import
lib <AR/THRONE>;
  use   RPG::Dice 2d4,1d3;

# inherit
reg crolls;
  self  RPG::Dice;
  wed   -ivio self;

# cache re-roll
proc crux;
  roll  2d4;
  roll  1d3;

```

# CONCLUSION

In peso, `proc eq type`, which has broad implications, as previously discussed. But as with every other language, where I to `lis` roll to crux, I'd be binding a program's entry point to a function. A *traditional* class should be understood in that very way, and how often we forget.
