# 2023.18: Temporal Operators in Forge

~~~admonish tip title="CSCI 1710"
I want to remind everyone that if you got a check-minus, it doesn't mean "not passing"; it doesn't even mean "can't get an A". It means "not A quality work on **this** assignment". You do not need any check-plusses to get an A. Check-plusses are rare.
~~~

Livecode is [here](./mutex_temporal.frg).

## Temporal Operators: Survey

I wonder if we could add notions of "always" and "eventually" and so on to Forge. That would help us avoid some of the errors that occur when we try to represent lasso traces manually.

~~~admonish note title="CSCI 1710"
Your class exercise today is to try out [this survey](https://docs.google.com/forms/d/e/1FAIpQLSf4nNtzjVhEv3daqZeySbsApoX9L2cwVts23qIzOlX6Ug8nug/viewform?usp=sf_link).  

We're asking whether a _specific trace_ satisfies a constraint that uses the new operators.
~~~

## Temporal Forge

Here's a quick run-down:
* lasso traces are kind of a bother to handle manually; 
* properties like the ones we checked last time more naturally expressed with (carefully defined) operators like `always` and `eventually`; and
* supporting more industrial model-checking languages in Forge will give everyone a better grounding in using those tools in the future (outside of class, but also on the term project). These tools very often use such operators.

Temporal Forge takes away the need for you to explicitly model traces. It forces the engine to only ever find lasso traces, and gives you some convenient syntax for working under that assumption. A field can be declared `var`, meaning it may change over time. And so on. 

I'll repeat the most important clause above: Forge's temporal mode **forces the engine to only ever find lasso traces**. It's very convenient if that's what you want, but don't use it if you don't!

Here's an example of what I mean. I'll give you a small example of a temporal-mode model in Forge. Suppose we're modeling a system with a single integer counter...

```
#lang forge/temporal

-- enable traces of up to length 10
option max_tracelength 10

one sig Counter {
  var counter: one Int
}

run {
-- Temporal-mode formulas "start" at the first state
-- The counter starts out at 0
  Counter.counter = 0
  -- The counter is incremented every transition:
  always Counter.counter' = add[Counter.counter, 1]
} for 3 Int
```

This is _satisfiable_, but only by exploiting integer overflow. If we weren't able to use overflow, this would be _unsatisfiable_: there wouldn't be enough integers available to form a lasso. And Temporal Forge **only looks for lassos**.


### Converting to Temporal Forge

Let's convert the model from last time into temporal mode. We'll add the necessary options first. Note that options in Forge are usually _positional_, meaning that it is usually a good idea to have options at the beginning unless you want to vary parameters per `run`.

```alloy
#lang forge/temporal

option max_tracelength 10
```
Be sure to get the underscores right! Misspellings like `maxtracelength` aren't an option for Forge. 

Mixing Temporal Forge with the kind of state-aware model we had before can be tough. In temporal mode, we don't have the ability to talk about specific pre- and post-states, which means we have to change the types of our predicates. For `init`, we have:

```alloy
-- No argument! Temporal mode is implicitly aware of time
pred init {
    all p: Process | World.loc[p] = Disinterested
    no World.flags 
}
```

The loss of a `State` `sig` is perhaps disorienting. How does Forge evaluate `init` without knowing which state we're looking at? **In temporal mode, every constraint is evaluated not just about an instance, but also in the context of some _moment in time_**. You don't need to explicitly mention the moment. So `no World.flags` is true if, at the current time, there's no flags raised. 

Similarly, we'll need to change our transition predicates:

```alloy
-- Only one argument; same reason as above
pred raise[p: Process] {
    // pre.loc[p] = Disinterested
    // post.loc[p] = Waiting
    // post.flags = pre.flags + p
    // all p2: Process - p | post.loc[p2] = pre.loc[p2]
    World.loc[p] = Disinterested
    World.loc'[p] = Waiting
    World.flags' = World.flags + p
    all p2: Process - p | World.loc'[p2] = World.loc[p2]
}
```

I've left the old version commented out, so you can contrast the two. Again, the predicate is true subject to an implicit moment in time. **The priming (') operator means "this expression in the next state"**; so if `raise` holds at some point in time, it means there is a specific relationship between the current and next moments.

We'll convert the other predicates similarly, and then run the model:

```alloy
run {
    -- start in an initial state
    init
    -- in every state of the lasso, the next state is defined by the transition predicate
    always delta
}
```

There are some threats to success here (like deadlocks!) but we'll return to those on Friday. Likewise, there are some issues with the model remaining that we haven't yet dealt with.

## Running A Temporal Model

When we run, we get this:

![](https://i.imgur.com/LsN0gfB.png)

### New Buttons!

In temporal mode, Sterling has 2 "next" buttons, rather than just one. The "Next Trace" button will hold all non-`var` relations constant, but ask for a new trace that varies the `var` relations. The "Next Config" button forces the non-`var` relations to differ. These are useful, since otherwise Forge is free to change the value of any relation, even if it's not what you want changed. 

### Trace Minimap

In temporal mode, Sterling shows a "mini-map" of the trace in the "Time" tab. You can see the number of states in the trace, as well as where the lasso loops back. 

**It will always be a lasso, because temporal mode never finds anything but lassos.**

You can use the navigation arrows, or click on specific states to move the visualization to that state: 

![](https://i.imgur.com/KnLqfJm.png)

Theming works as normal. For the moment, custom visualizer scripts need to visualize a single state at at time.

