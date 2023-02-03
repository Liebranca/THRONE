# THE SOCIAL ENGINE

## PREAMBLE

NPCs are generally dumb and solely there to react to the player, as if they had no lives of their own; very little effort has ever been done in perfecting the formula of 'X will remember that', which in my view does not suffice.

But what would constitute a good translation of social interaction to the naturally simplistic medium of games?

I've been quite clear in these documents that a game *must* simplify reality; frankly, too much effort in the opposite direction is to turn entertainment into a chore.

So no: it must be game-like, which I will once again define as barely resembling reality at surface level -- if you must eat cheese to restore health then, effectively. your character has a hunger meter.

Many do not share this opinion; they'd rather over-complicate their mechanics by adding to an ever-increasing list of anti-features, willfully blind to how every new aspect of gameplay that detracts from the core loop has the utmost potential to become a burden on the player rather than an element of fun. 

I'd like it if no care were to be put into further hammering these points: my exact same observations can be made by anyone with a lick of sense, and thus, I conclude that sense is what feature-creep devotees lack; no number of times I beat this drum will knock it back into them, as it was never there to beg with.

However, as my thoughts strive for clarity of expression, I will be forced to care; as such, questions of realism shall be addressed as they come up.

## SYSTEM OVERVIEW

An actor is an entity capable of bringing change uppon playable space; it's actions are driven by goals.

Goals are minimalistic evaluations, such as acquiring resources, traveling to a given location, spending time somewhere or with someone or something, or engaging in a particular activity.

For all intents and purposes, these goals constitute the better part of an actor's personality: what they do is what they are. The other part corresponds to traits and quirks, which are mere modifiers to their behaviour.

The __mood__ of an actor is thus given by recent events and the success rate of their goals. At every step of the simulation, occurrences are recorded into an actor's memory and checked against their goals, traits and quirks; depending on how favorably or unfavorably an individual sees this event, their mood will change.

Events register a snapshot of the actor's state and proximity at a given point in time; where they were, who was with them and what they were doing, as well as their mood during those moments.

Way actors react to events is two-fold: one, how it affects them, and two, how it affects others. Depending on what each actor did during this event is how their relationship is calculated.

To better illustrate these mechanics, let's look at an example scenario:

### THE ACTORS

Boro, a traveling knight, has the traits `courage` and `passion`, balanced by the quirk of `impatience`. His goals are doing battle, standing by his comrades and perfecting his skill with the blade.

Being courageous and passionate, he's more than content when fulfilling his desires of fighting or training alongside his band -- but because he is impatient, he does not enjoy spending too long idling.

One of Boro's companions, Ajira, has the traits `intellectual` and `empathy`, with `awkwardness` as quirk. Her goals are helping others in need, seeing new places and reading.

Due to her empathy, she's offended by acts of cruelty, though her being awkward presents a difficulty in communicating with others. Being an intellectual and an avid reader as well as fond of travel, she can enjoy both adventure and study.

### THE EVENT

During one of their travels, the group spots a caravan being attacked by bandits. Boro immediatelly jumps into the fray while Ajira looks to assist the wounded.

The battle is won and the bandits flee, leaving one of their own behind. Acknowleding defeat, the abandoned man drops his weapon and pleads for mercy, but possesed by his love of fighting, Boro executes the injured delinquent without a second thought.

Meanwhile, Ajira fails to heal one of the wounded merchants, who bleeds to death; and finding herself unable to save a life is only made worse by seeing the grief in the survivors' eyes.

### THE AFTERMATH

Having fought side by side with his comrades and emerging victorious, Boro is more than satisfied: his relationship with his companions is strenghtened and his mood goes up. This instance, for him, will be a fond memory.

Ajira, on the other hand, failed to save a man's life and is appalled that one of her companions slew a man who had surrendered. Though she finds herself unable to confront him about it, her relationship with Boro suffers, and her mood downs dramatically. She will not remember this moment kindly.

However, due to how strongly this incident has affected Ajira, it will be visible to others, moreso if their relationship is high: one who is close enough would attempt asking about it, and if also close to Boro, would inform him of how his acts affected her.

And thus Boro, knowing that a given action offended one of his companions, might stop himself next time, and even offer an apology if his relationship to Ajira is high enough.

### TAKEAWAY

A memory of an event is not merely a snapshot, frozen in time: they are oft changed by knowledge we acquire at a later date, and one would hope, that the happenings we live through contribute to a re-shaping of self.

Characters cannot merely react to the player; rather, they must react to the world around them, *including* the player. The challenge lies in that, for a game, such a system must be simplified without losing it's essence: actors follow their initial programming, have some capacity for remembering certain periods of time, and can use their memory to adjust that initial programming -- and that adjustment, that character growth, must be governed by how the actor 'feels' towards that environment they interact with.

What this creates is a social simulation. I will now describe how this would work mechanically.

## PERTAINING TO ACTOR CREATION

First and foremost is the declaration of an actor: it is impossible to describe a being in full, much less in brief, thus here is where simplification must come into play more strongly.

My suggestion is that of two traits, one quirk and three goals; adding more variables would both be a hinderance to the programmer and make the simulation harder to upscale.

Traits must benefit the actor in some capacity; quirks musn't necessarily be wholly negative and only have to balance out the benefits of traits; in any case, the distinction between them is only cathegorical as their function is the same: to drive behaviour.

Goals are different in that they control __what__ the actor desires to achieve; there is still a certain overlap, given that a cowardly character would not see combat or even comfrontation as desirable.

Thus, traits must come first, narrow down the quirks, and from traits and quirks the available goals must be further narrowed down. This makes it so a desired behaviour can be programmed with ease, as it flows naturally from every decision made at decl-time.

## BEHAVIOUR EQ PRIORITIES

We shall define behaviour as the way an actor responds to a given context uppon being prompted. For each context, a list of possible responses must be presented: an actors's personality is then tasked with deciding on a reaction.

Therefore, behaviour of an actor is their preference for a certain set of responses. With this, we can define the trait `courage` as follows:

```
courage=>{

  act => [qw(rally engange resist fight)],
  ban => [qw(cowardice)],

},

```

Id est, a list of actions the actor prefers to take at any given moment, sorted by priority, followed by those they'd be loathe to pick.

Let the function `behave` provide an actor with a list of options: if avail, they will pick the one most preferred by their dominant trait; else, they'll consider options from their secondary trait, then their quirk, and finally their goals.

If no option in the provided list suits an actor's preference, they'll consider whichever one isn't in their list of dislikes; and if left with no other option, they'll pick their least disliked.

With this very minimalistic implementation, we have hints of the theorized system already at play: knowing how far down or up in an actor's personal list of likes and dislikes an act is.

Furthermore, when having to decide on a list of options that the actor has no preference or dislikes in, we'll say the situation falls on their zone of indifference, meaning: they'll be out of their element, and leave the decision to chance, or in more mechanical terms, a dice roll.

Then, depending on the aftermath of the event that prompted the decision, the actor can obtain some grasp on their feelings towards the actions they took, and position the action within their priorities accordingly. That way, __an actor's behaviour can evolve__.

### REALISTIC VERSUS GAME-LIKE

In the real world, a person would not or at least not *always* make their decisions way our actors do: but stop to think about how much more complexity you'd have to add unto this subsystem in order to achieve that additional layer of triple-quoted realism, then consider the fact this is only one component of the world simulation `THRONE` aims for, and you'll begin to see the cracks.

Designing a game to __be__ a game is one thing, designing a realistic simulation *within* a game is another. I have chosen the former.

## ACTOR MEMORY

An instance of `memory` shall be a stack of hashrefs, representing actions taken by characters during a period of time, generally a quarter of a day. For each element in the stack, there's the name of the action itself, the actor that took it, the actor's feelings towards it and the success status of the act, together with the results of any relevant dice rolls made.

Uppon `reflect`, an actor evaluates their actions and adjusts the preference values for each. Reflection may be triggered when a memory is referenced via conversation, when mood drops or rises past a threshold some time after a memory is created, or at random during periods of quiet.

Each memory contains accompanying context data: actors' mood, relations  and location at the time, as well as other actors' feelings towards certain actions, if they are known.

When reflecting, an overall score is calculated for a memory. If positive, the behaviour expressed by the actor is reinforced and mood is improved; otherwise, and depending on how low the score is, the actor drops their preference for certain acts and loses some points to their mood.

If two or more actors share a memory, their relationship can be affected by this overall score. Furthermore, if they are close enough, high like or dislike of a given act will also influence their future behaviour.

Going back a few chapters, in our initial example, Ajira's empathy indirectly affects Boro, to the point where he starts to develops a dislike for `no-mercy`, an act of the `cruelty` quirk he was previously indifferent to.

An actor may `infer` someone else's opinion if they have a preference for that act and someone's mood drastically changes. However, actors cannot read minds: they must either succeed an inference check, be already aware of someone's feelings, be told, or ask away themselves.





