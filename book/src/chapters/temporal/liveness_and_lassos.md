# 2023.17: Join, Liveness and Lassos

## The Truth About Dot

This part of the notes is meant to reinforce what we'd previously done with relational join in Forge. We'll cover some of this in class, but the rest is here for your reference.

Let's go back to the directed-graph model we used before:

```alloy
#lang forge
sig Person {
    friends: set Person,
    followers: set Person
}
one sig Nim, Tim extends Person {}
pred wellformed {
    -- friendship is symmetric
    all disj p1, p2: Person | p1 in p2.friends implies p2 in p1.friends
    -- cannot follow or friend yourself
    all p: Person | p not in p.friends and p not in p.followers
}
run {wellformed} for exactly 5 Person

pred reachableIn1To7Hops[to: Person, from: Person, fld: Person->Person] {
    to in from.fld or
    to in from.fld.fld or
    to in from.fld.fld.fld or 
    to in from.fld.fld.fld.fld or
    to in from.fld.fld.fld.fld.fld or
    to in from.fld.fld.fld.fld.fld.fld or
    to in from.fld.fld.fld.fld.fld.fld.fld 
    --  ... and so on, for any finite number of hops
    --  this is what you use the transitive-closure operator (^) 
    --  or the reachable built-in predicate for.
}
```

We said that chaining field access with `.` allows us to compute reachability in a certain number of hops. That's how `reachableIn1To7Hops` works. 

However, there's more to `.` than this.

### Beyond Field Access

Let's run this model, and open up the evaluator. I'll show the first instance Forge found using the table view:

![](https://i.imgur.com/CXrslMn.png)

We saw that `Tim.friends` produces the set of `Tim`'s friends, and that `Tim.friends.friends` produces the set of `Tim`'s friends' friends. But let's try something else. Enter this into the evaluator:

```
friends.friends
```

This looks like a nonsense expression: there's no object to reference the `friends` field of. But it means something in Forge:

![](https://i.imgur.com/2m2esUg.png)

What do you notice about this result? Recall that this is just a parenthetical way to show a set of tuples: it's got $(Person0, Person0)$ in it, and so on.

<details>
<summary>Think, then click!</summary>

This seems to be the binary relation (set of 2-element tuples) that describes the friend-of-friend relationship. Because we said that friendship is symmetric, everyone who has friends is a friend-of-a-friend of themselves. And so on.
    
</details>
</br>

The `.` operator in Forge isn't exactly field access. It behaves that way in Froglet, but now that we have sets in the language, it's more powerful. It lets us combine relations in a path-like way.

### Relational Join

Here's the precise definition of the _relational join_ operator (`.`):

If `R` and `S` are relations (with $n$ and $m$ columns, respectively), then `R.S` is defined to be the set of $(n+m-2)$-column tuples: $\{(r_1, ..., r_{n-1}, s_2, ..., s_m) |\; (r_1, ..., r_n) \in R, (s_1, ..., s_m) \in S, \text{ and } r_n = s_1 \}$

That is, whenever the inner columns of the two relations line up on some value, their join contains some tuple(s) that have the inner columns eliminated. 

In a path-finding context, this is why `Tim.friends.friends.friends.friends` has one column, and all the intermediate steps have been removed: `Tim` has one column, and `friends` has 2 columns. `Tim.friends` is the $(1+2-2)$-column relation of `Tim`'s friends. And so on: every time we join on another `friends`, 2 columns are removed.  

Let's try this out in the evaluator:

![](https://i.imgur.com/oeZWrIT.png)

![](https://i.imgur.com/B3Hyk8h.png)

Does this mean that we can write something like `followers.Tim`? Yes; it denotes the set of everyone who has `Tim` as a follower:

![](https://i.imgur.com/yVaYWoz.png)

Note that this is very different from `Tim.followers`, which is the set of everyone who follows `Tim`:

![](https://i.imgur.com/MKu2M29.png)

### Testing Our Definition

We can use Forge to validate the above definition, for relations with fixed arity. So if we want to check the definition for pairs of *binary* relations, up to a bound of `10`, we'd run:

```alloy
test expect {
    joinDefinitionForBinary: {
        friends.followers = 
        {p1, p2: Person | some x: Person | p1->x in friends and 
                                           x->p2 in followers}
    } for 10 Person is theorem
}
```

Notice that we don't include `wellformed` here: if we did, we wouldn't be checking the definition for _all_ possible graphs.

### Join Errors

Forge will give you an error message if you try to use join in a way that produces a set with _no_ columns:

![](https://i.imgur.com/KOd4CSt.png)

or if it detects a type mismatch that would mean the join is necessarily empty:

![](https://i.imgur.com/lwYeUk3.png)

![](https://i.imgur.com/Uc8n94G.png)

When you see a parenthesized formula in an error like this, you can read it by interpreting operator names in prefix form. E.g., this one means `Int.friends`. 

~~~admonish note title="Spring 2024"
Many of these errors have now been updated to show the proper, non-parenthetical form.
~~~

### What's Join Good For?

Here's an example. Suppose you're modeling something like Dijkstra's algorithm. You'd need a weighted directed graph, which might be something like this:

```alloy
sig Node {
    edges: Node -> Int
}
```

But then `edges` has three columns, and you won't be able to use either `reachable` or `^` on it directly. Instead, you can eliminate the rightmost column with join: `edges.Int`, and then use that expression as if it were a `set` field.

## Counterexamples To Liveness

Last time we noticed that "every thread, whenever it becomes interested in the critical section, will eventually get access" is a different kind of property---one that requires an _infinite_ counterexample to disprove about the system. We called this sort of property a _liveness property_.

In a finite-state system, checking a liveness property amounts to looking for a bad cycle: some trace, starting from an initial state, that loops back on itself. Since these traces don't always loop back to the first state, we'll often call these _lasso traces_, named after a loop of rope.

Here's an example. Consider the (reachable states only) transition system we drew last time:

![](https://i.imgur.com/EPMcgrl.png)

Can you find a lasso trace that violates our liveness property?

<details>
<summary>Think, then click!</summary>
Here's one of them: 
    
* $(Dis, 0, Dis, 0)$; then
* $(Dis, 0, W, 1)$; then
* $(Dis, 0, C, 1)$; then back to
* $(Dis, 0, Dis, 0)$.
    
This lasso trace _does_ just happen to loop back to its first state. It shows the second process executing forever, and the first process remains uninterested forever. 

Is this good or bad? It depends on how we write the property. And certainly, we could find worse traces!
    
</details>

## Checking Liveness In Forge (Attempt 1)

How could we encode this sort of check in Forge? We wouldn't be able to use the inductive method---at least, not in a naïve way. So let's use the finite-trace approach we used to generate games of Tic-Tac-Toe. However, we can't just say that _some state_ in a trace violates the property: we need to encode the search for a bad *cycle*, too. 

### Setting Up

We'll add the same finite-trace infrastructure as before. This time we're able to use full Forge, so **as a demo** we'll use the transpose (`~`) operator to say that the initial state has no predecessors.

```alloy
one sig Trace {
    initialState: one State,
    nextState: pfunc State -> State
}

pred trace {
    no Trace.initialState.~(Trace.nextState)
    init[Trace.initialState]
    all s: State | some Trace.nextState[s] implies {
        delta[s, Trace.nextState[s]]
    }
}
```

### Enforcing Lasso Traces

It's helpful to have a helper predicate that enforces the trace being found is a lasso. 

```alloy
pred lasso {
    trace
    all s: State | some Trace.nextState[s]
}
```

Let's test this predicate to make sure it's satisfiable. And, because we're careful, let's make sure it's _not_ satisfiable if we don't give the trace enough states to loop back on itself:

```alloy
test expect {
  lassoVacuity: { lasso } is sat
  lassoVacuityNotEnough: { lasso } for 2 State is unsat
}
```

### Beware...

There is actually a hidden overconstraint bug in our `lasso` predicate. It's not so extreme as to make the predicate unsatisfiable---so the test above passes! What's the problem?

<details>
<summary>Think, then click!</summary>

We said that the initial state has no predecessor. This will prevent the lasso from looping back to the start---it will always have some states before the cycle begins. If the bug we're looking for always manifests as a loop back to the starting state, we would be **lulled into a false sense of success** by Forge. 
    
</details>
</br>

**Watch out for this kind of bug!**

This is why thinking through vacuity testing is important. It's also a reason why, maybe, we'd like to avoid having to write all this temporal boilerplate (and potentially introduce bugs).

### Identifying A Bad Cycle

If we know that the trace is a lasso, we can write a predicate that identifies some process being starved. This isn't easy, though. To see why, look at this initial attempt:

```alloy
run {
  lasso
  all s: State | s.loc[ProcessA] != InCS
}
```

This is _unsatisfiable_, which is what we'd expect. So what's wrong with it?

We might first wonder, as we usually should, whether the test allocates enough states to reasonably find a counterexample. We've got 8 reachable states, so maybe we'd need 8 (or 9?) states in the test. That's true! 

But there's something else wrong here, and it's more subtle. We'll need to address both to make progress. 

<details>
<summary>Think, then click!</summary>

The `badLasso` predicate wouldn't hold true if the system allowed `ProcessA` to enter the critical section _once_ (and only once). We need to say that the _loop_ of the lasso doesn't allow a process in, no matter what happens before the cycle starts.    
    
</details>
</br>

That sounds like a lot of work. More importantly, it sounds really easy to get wrong. Maybe there's a better way.
