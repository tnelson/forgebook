# Counterexamples To Induction

You'll need [this exercise template](./binarysearch_template.frg) for these notes, which cover 3 class sessions. The completed version, complete with in-class comments, is [here](./binarysearch_inclass.frg).

We prototyped some confidence tests about the `reachable` predicate ([livecode file](./testing_reachable.frg)).


## Induction

When we're talking about whether or not a reachable state violates a desirable property $P$ (recall we sometimes say that if this holds, $P$ is an _invariant_ of the system), it's useful to think geometrically. Here's a picture of the space of _all states_, with the cluster of "good" states separated from the "bad":

![](https://i.imgur.com/n3F16P4.png)

If this space is large, we probably can't use trace-finding to get a real _proof_: we'd have to either reduce the trace length (in which case, maybe there's a bad state _just barely_ out of reach of that length) or we'd be waiting until the sun expands and engulfs the earth.

Traces are still useful, especially for finding shallow bugs, and the technique is used in industry! But we need more than one tool in our bag of tricks. 

### Step 1: Initiation or Base Case

Let's break the problem down. What if we just consider reachability for traces of length $0$---that is, traces of only one state, an `initial` state?

This we can check in Forge just by asking for a state `s` satisfying `{initial[s] and wellformed[s] and not P[s]}.` There's no exponential blowup with trace length since the transition predicates are never even involved! If we see something like this:

![](https://i.imgur.com/Aia9V0q.png)

We know that at least the starting states are good. If instead there was a region of the starting states that overlapped the bad states, then we immediately know that the property isn't invariant.

### Step 1.5: Noticing and Wondering

We can surely also check whether there are bad states within $1$ transition. We're using the transition predicate (or predicates) now, but only _once_. Forge can also do this; we ask for a pair of states `s0`, `s1` satisfying `{initial[s0] and someTransition[s0, s1] and not P[s1]}` (where `someTransition` is my shorthand for allowing any transition predicate to work; we could write the predicate ourselves). 

If Forge doesn't find any way for the second state to violate $P$, it means we have a picture like this:

![](https://i.imgur.com/NdA7RwF.png)

It's looking promising! Note that in general, there might be overlap (as shown) between the set of possible initial states and the set of possible second states. (For example, imagine if we allowed a `doNothing` transition at any time).

If we keep following this process exactly, we'll arrive back at the trace-based approach: a set of 3rd states, a set of 4th states, and so on. That's sometimes useful (and people do it in industry---if you're interested, you can see the original paper by [Biere, et al.](https://www.cs.cmu.edu/~emc/papers/Books%20and%20Edited%20Volumes/Bounded%20Model%20Checking.pdf)) but it won't scale to systems with very long traces.

**Sometimes great ideas arise from dire limitations.** What if we limit ourselves to only ever asking Forge for these _two state_ examples? That would solve the exponential-blowup problem of traces, but how can we ever get something useful, that is, a result that isn't limited to trace length 1?

I claim that we can (often) use these small, efficient queries to show that $P$ holds at _any_ finite length from a starting state. But how? 

By no longer caring whether the pre-state of the check is reachable or not. 

### Step 2: Consecution or Inductive Case

We'll ask Forge whether `{P[s0] and someTransition[s0, s1] and not P[s1]}` is satisfiable for _any_ pair of states. Just so long as the pre-state satisfies $P$ and the post-state doesn't. We're asking Forge if it can find a transition that looks like this:

![](https://i.imgur.com/CWSjSrr.png)

If the answer is _no_, then it is simply impossible (up to the bounds we gave Forge) for any transition predicate to stop property $P$ from holding: if it holds in the pre-state, it _must_ hold in the post-state. 

But if that's true, and we know that all initial states satisfy $P$, then all states reachable in $1$ transition satisfy $P$ (by what we just checked). And if that's true, then all states reachable in $2$ transitions satisfy $P$ also (since all potential pre-states must satisfy $P$). And so on: _any_ state that's reachable in a finite number of transitions must satisfy $P$. 

If you've seen "proof by induction" before in another class, we've just applied the same idea here. Except, rather than using it to show that the sum of the numbers from $1$ to $n$ is $\frac{k(k+1)}{2}$, we've just used it to prove that $P$ is invariant in our system. 

In Tic-Tac-Toe, this would be something like "cheating states can't be reached with legal moves". In an operating system, this might be "two processes can never modify a block of memory simultaneously". In hardware, it might be "only one device has access to write to the bus at any point". In a model of binary search, it might be "if the target is in the array, it's located between the `low` and `high` indexes".

For most computer-scientists, I think that this feels like a far more relatable and immediately useful example of the induction principle. That's not to dismiss mathematical induction! I quite like it (and it's useful for establishing some useful results related to Forge). But multiple perspectives enrich life.

### Exercise: Try it!

In the binary-search model, there's a pair of tests labeled `initStep` and `inductiveStep`, under a comment that says "Exercise 1". Fill these in using the logic above, and run them. Do they both pass? Does one fail?

### What if Forge finds a counterexample?

What if Forge _does_ find a transition that fails to preserve our property $P$? Does it mean that $P$ is not an invariant of the system?

<details>
<summary>Think, then click!</summary>

No! It just means that $P$ isn't _inductively invariant_.  **The pre-state that Forge finds might not _itself_ be reachable!**
    
This technique is a great way to quickly show that $P$ is invariant, but if it fails, we need to do more work.

</details>

We see this happen when we try to run the above checks for our binary-search model! The `inductiveStep` test fails, and we get a counterexample. 

### Fix 1: Adding Reasonable Assumptions

Sometimes there are conditions about the world that we need in order for the system to work at all. For example, we already require the array to be sorted. Are there other requirements?

It's possible that the counterexample we're shown involves a subtle *bug* in binary search: if the array is large relative to the maximum integer in the system, the value `(high+low)` can overflow. 

We're not trying to _fix_ this problem in the algorithm. This is a real bug, and modeling found it. So let's log the issue and add a _global assumption_ that the array is not so large. We'll add that in the `safeArraySize` predicate, which we'll then use in the 2 checks. How can we express what we want---that the array is not too large?

<details>
<summary>Think, then click!</summary>
    
The core challenge here is that we'll never have enough integers to actually count `#Int`. However, we _can_ ask for the maximum integer---`max[Int]`. So we could say that `arr.lastIndex` is less than `divide[max[Int], 2]`. This might be a little conservative, but it guarantees that the array is never larger than half of the maximum integer. 
    
</details>
</br>

**Exercise**: Try expressing this in the `safeArraySize` predicate, and adding it to the test that failed. Add a comment explaining why this is a requirement.


### Fix 2: Enriching the Invariant 

Sometimes the property we're hoping to verify is simply not preserved by system transitions in general, but the pre-state in any counterexample isn't actually reachable. **This is the tradeoff of the inductive approach!** We have to do some work to make progress.

Concretely, we'll need to _verify something stronger_. At the very least, if $S$ is the pre-state of the counterexample we were given, we need to also add "and this state isn't $S$" to the property $P$ we're checking. In practice, we usually add something more general that covers whatever quality it is about $S$ that makes it unreachable. 

The technique is sometimes called "enriching the invariant". 

**Exercise**: Do you believe the counterexample you're getting is reachable? If not, what is it about the state that looks suspicious?

**Exercise**: Now add new constraints to the `bsearchInvariant` predicate that exclude this narrow criterion. Be careful not to exclude too much! An over-constrained property can be easy to verify, but may not actually give many guarantees.


## But Can We Trust The Model?

What would it mean for this verification idea if there were simply no initial states, or no way to take a certain transition? That would probably be a bug in the model; how would it impact our proof?

Look again at the two checks we wrote. If `initial` were unsatisfiable by any state, surely the Step 1 check would also be unsatisfiable (since it just adds _more_ constraints). Similarly, unsatisfiable transition predicates would limit the power of Step 2 to find ways that the system could transition out of safety. This  would mean that our confidence in the check was premature: Forge would find no initial bad states, _but only because we narrowed its search to nothing_! 

This problem is called _vacuity_, and I'll give you another example. Suppose I told you: "All my billionaire friends love Logic for Systems". I have, as far as I know anyway, no billionaire friends. So is the sentence true or false? If you asked Forge, it would say that the sentence was true---after all, there's no billionaire friend of mine who _doesn't_ love Logic for Systems...

This is a problem you might first hear about in other courses like 0220, or in the philosophy department. There's a risk you'll think vacuity is silly, or possibly a topic for debate among people who like drawing their As upside down and their Es backwards, and love writing formulas with lots of Greek letters in. **Don't be fooled!** Vacuity is a major problem even in industrial settings like Intel, because verification tools are literal-minded. (Still doubtful? Ask Tim to send you links, and check out the EdStem post at the top of these notes.)

At the very least, we'd better test that the left-hand-side of the implication can be satisfied. This isn't a guarantee of trustworthiness, but it's a start. And it's easy to check with Forge. 
