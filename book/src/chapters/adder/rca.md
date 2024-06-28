# Ripple Carry Adder 

Let's model a third system in Froglet. We'll focus on something even more concrete, something that is implemented in _hardware_: a circuit for adding together two numbers called a _ripple-carry adder_ (RCA). Along the way, even though the adder doesn't "change", we'll still learn a useful technique for modeling systems that change over time. 

To understand an RCA, let's first think about adding together a pair of one-bit numbers. We might draw a table with four rows to represent this:

| Input Bit A | Input Bit B | Result Bit |
| ----------- | ----------- | ---------- | 
|           0 |           0 |          0 |          
|           0 |           1 |          1 |          
|           1 |           0 |          1 |          
|           1 |           1 |          2 |          

But, wait a moment. If we're building this into a circuit, and these inputs and outputs are single bits, we can't return `2` as the result. Similarly to how we might manually add `9` and `19` on paper, carrying a `1` in the `10`s place, to get `28`...

**(TODO: insert picture of the addition-on-paper)**

We need to carry a bit with value `1` in the `2s` place.

| Input Bit A | Input Bit B | Result Bit | Carry Bit (double value!) | 
| ----------- | ----------- | ---------- | ------------------------- |
|           0 |           0 |          0 |                         0 |
|           0 |           1 |          1 |                         0 |
|           1 |           0 |          1 |                         0 |
|           1 |           1 |          0 |                         1 |

Suppose we've built a circuit like the above using logic gates; this is called a _full adder_ (FA).

**(TODO: insert picture of a single adder doing this: 2 inputs, 2 outputs)**

Now the question is: how do we build an adder that can handle numbers of the sizes that real computers use: 8-bit, 32-bit, or even 64-bit values? The answer is that we'll chain together multiple adder circuits like the above, letting the carry bits "ripple" forward as an extra, 3rd input to all the adders except the first one. E.g., if we were adding together 4-bit numbers, we'd chain together 4 adders like so:

**(TODO: insert picture of a chain of 4 adders, with a concrete input and outputs)**

Our task here is to model this circuit in Forge, and confirm that it actually works correctly. 

~~~admonish note title="Circuits aren't easy"
This might look "obvious", but there are things that can go wrong even at this level. 

If you've studied physics or electrical engineering, you might also see that this model won't match reality: it takes _time_ for the signals to propagate between adders, and this delay can cause serious problems if the chain of adders is too long. We'll address that with a new, more sophisticated model, later. 
~~~

## Datatypes

We'll start by defining a boolean data type, for the wire values.

```forge,editable
abstract sig Bool {}
one sig True, False extends Bool {}
```

Then we'll define a `sig` for full adders, which will be chained together to form the ripple-carry adder:

```forge,editable
sig FA { 
  -- input and output bits 
  a, b: one Bool,  
  -- input carry bit
  cin: one Bool,
  -- output value
  s: one Bool,
  -- output carry bit 
  cout: one Bool
}
```

~~~admonish warning title="Bool is not boolean!"
Beware confusing the `Bool` sig we created, which is a definition in our model and denotes a set of `Bool` atoms, with the booleans that Forge formulas evaluate to. Forge doesn't "know" anything special about the definition above, which means we won't be able to write something like: `(some FA) = True`. To Forge, `True` is an just expression that denotes some value, but `some FA` must evaluate to either true or false. 
~~~

Finally, we'll define the ripple-carry adder chain:

~~~forge,editable
one sig RCA {
  -- the first full adder in the chain
  firstAdder: one FA,
  -- the next full adder in the chain (if any)
  nextAdder: pfunc FA -> FA
}
~~~

Notice that there is only ever one ripple-carry adder in an instance, and that it has fields that define which full adder comes first (i.e., operates on the `1`s place), and what the succession is. We will probably need to enforce what these mean once we start defining wellformedness. 

## Wellformedness

What do we need to encode in a `wellformed` predicate? Right now, it seems that nothing has told Forge that `firstAdder` should really _be_ the first adder, nor that `nextAdder` defines a linear path through all the full adders. So we should probably start with those two facts. 

```forge,editable
pred wellformed {
  -- The RCA's firstAdder is "upstream" from all other FAs
  all fa: FA | (fa != RCA.firstAdder) implies reachable[fa, RCA.firstAdder, RCA.nextAdder]
  -- there are no cycles in the nextAdder function.
  all fa: FA | not reachable[fa, fa, RCA.nextAdder]  
}
```

We've used the `reachable` helper before, but it's worth mentioning again: `A` is reachable from `B` via _one or more applications_ of `f` if and only if `reachable[A, B, f]` is true. That "one or more applications" is important, and is why we needed to add the `(fa != RCA.firstAdder) implies` portion of the first constraint: `RCA.firstAdder` shouldn't be the successor of any full adder, and if it were its own successor, that would be a cycle in the line of adders. If we had left out the implication, and written just `all fa: FA | reachable[fa, RCA.firstAdder, RCA.nextAdder]`, `RCA.firstAdder` would need to have a predecessor, which would contradict the second constraint.

## More Predicates

Before we write some examples for `wellformed`, let's also try to model how each adder should behave, given that it's wired up to other adders in this specific order. Let's write a couple of helpers first, and then combine them to describe the behavior of each adder, given its place in the sequence.

### When is an adder's output bit set to true? 

Just like `pred`icates can be used as boolean-valued helpers, `fun`ctions can act as helpers for arbitrary return types. Let's try to write one that says what the _output_ bit should be for a specific full adder, given its input bits. 

```forge
// Helper function: what is the output bit for this full adder?
fun adder_S_RCA[f: one FA]: one Bool  {
  // FILL THIS IN
} 
```

Looking at the table above, the adder's output value is true if and only if an odd number of its 3 inputs is true. That gives us 4 combinations:
* `A`, `B`, and `CIN`;
* `A` only; 
* `B` only; or
* `C` only. 

We'll use Forge's `let` construct to make it easier to write the value for each of these wires, and then combine them using logical `or`. 

```forge
// Helper function: what is the output bit for this full adder?
fun adder_S_RCA[f: one FA]: one Bool  {
  // Note: "True" and "False" are values in the model, we cannot use them as Forge formulas.
  let A = (f.a = True), B = (f.b = True), CIN = (f.cin = True) |
	 ((A and B and CIN) or 
    (A and (not B) and (not CIN)) or 
    ((not A) and B and (not CIN)) or 
    ((not A) and (not B) and CIN))
	 	  =>   True 
      else False
} 
```

~~~admonish tip title="Couldn't we have just used a `pred` here?"
It's admittedly a bit strange to write a helper function that returns a `Bool`, rather than a predicate that returns a Forge boolean. We could make a `pred` work; we'd just have to eventually use `True` and `False` somewhere, since they are the values that the output bits can take on. 
~~~

### When is an adder's carry bit set to true? 

This one is quite similar. The carry bit is set to true if and only if 2 or 3 of the adder's inputs are true. 

```forge
// Helper function: what is the output carry bit for this full adder?
fun adder_cout_RCA[f: one FA]: one Bool {
 let A = (f.a = True), B = (f.b = True), CIN = (f.cin = True) |
     ((not A and B and CIN) or 
      (A and not B and CIN) or 
      (A and B and not CIN) or 
      (A and B and CIN)) 
	      =>   True 
        else False
} 
```

### Adder Behavior

Finally, what ought an adder's behavior to be? Well, we need to specify its output bits in terms of its input bits. We'll also add a constraint that says this adder's output carry bit flows into its successor's input carry bit.  

```forge
pred fullAdderBehavior[f: FA] {
  -- Each full adder's outputs are as expected
  f.s = adder_S_RCA[f]
  f.cout = adder_cout_RCA[f]
  -- Full adders are chained appropriately
  (some RCA.nextAdder[f]) implies (RCA.nextAdder[f]).cin = f.cout 
}
```

~~~admonish note title="Wouldn't it be better to put the carry-bit connection in `wellformed`?" 
There's a strong argument for that. The way the wires are connected isn't really part of a single full adder's behavior in itself. If I were going to re-write this model, I would probably either move that line into `wellformed` or somewhere else that has responsibility for the connectivity of the full adders. 
~~~

Finally, we'll make a predicate that describes the behavior of the overall ripple-carry adder: 

```
// Top-level system specification: compose preds above
pred rca {  
  wellformed
  all f: FA | fullAdderBehavior[f] 
}
```

~~~admonish note title="Notice what we've done."
Here's something to keep in mind for when we start the next chapter. By wiring together full adders into a sequence via the `rca` predicate, we are now implicitly hinting at time in our model: signal flows through each adder, in order, over time. We'll re-use this same technique in the next chapter to combine different system states into a succession of them that represents a complete run of the system.
~~~

Now we're ready to write some examples. We'll make a pair of examples for `wellformed` and an overall example for the full system. In practice, we'd probably want to write a couple of examples for `fullAdderBehavior` as well, but we'll leave those out for brevity. 

## Examples

Always try to write at least some positive _and_ negative examples.

### Positive Example

```forge
example twoAddersLinear is {wellformed} for {
  RCA = `RCA0 
  FA = `FA0 + `FA1
  -- Remember the back-tick mark here! These lines say that, e.g., for the atom `RCA0, 
  -- its firstAdder field contains `FA0. And so on.
  `RCA0.firstAdder = `FA0
  `RCA0.nextAdder = `FA0 -> `FA1
}
```

~~~admonish tip title="Notice that this example is limited."
Because we are testing `wellformed`, we left out fields that didn't matter to that predicate. Forge will feel free to adjust them as needed. When a field is left unspecified, the example is said to be *partial*, and it becomes a check for consistency. E.g., in this case, the example passes because the partial instance given *can* satisfy `wellformed`&mdash;not that it must satisfy `wellformed`&mdash;although in this case the difference is immaterial because `wellformed` really doesn't care about any of the other fields. 
~~~

### Negative Example

```forge
example twoAddersLoop is {not wellformed} for {
  RCA = `RCA0 
  FA = `FA0 + `FA1
  `RCA0.firstAdder = `FA0
  `RCA0.nextAdder = `FA0 -> `FA1 + `FA1 -> `FA0
}
```

## Run 

Let's have a look at a ripple-carry adder in action. We'll pick a reasonably small number of bits: 4. 

```forge
run {rca} for exactly 4 FA
```

**(FILL: screenshot)**



## Verification

Ok, we've looked at some of the model's output, and it seems right. But how can we be really confident that the ripple-carry adder _works_? Can we use our model to _verify_ the adder? Yes, but we'll need to do a bit more work. 

**FILL: verification story with ghost int**

The verification step took over a minute on my laptop! That's rather slow for a model this size. When this sort of unexpected slowdown happens, it's often because we've given the solver too much freedom, causing it to explore a much larger search space than it should have to. This is especially pronounced when we expect an "unsatisfiable" result&mdash;then, the solver really does need to explore _everything_ before concluding that no, there are no solutions. We're in that situation here, since we're hoping there are no counter-examples to correctness. 

So let's ask ourselves: *What did we leave the solver to figure out on its own, that we maybe could give it some help with?**

<details>
<summary>Think, then click!</summary>

There are at least two things. 
* First, the exact ordering of full adders isn't something we provided. We just said "create up to 6 of them, and wire them together in a line". Considering just the 6-adder case (and not the 5-adder case, 4-adder case, etc.), how many ways are there to arrange the adders? $6! = 720$. Unless the solver can detect and eliminate these symmetries, it's doing a _lot_ more work than it needs to. 
* Second, we said that `Helper.place` mapped full adders to integers. But does the solver need to consider _all_ integers? No! Just `1`, `2`, `4`, `8`, and so on. The vast majority of integers in the scope we provided cannot be used&mdash;and the solver will have to discover that on its own.

</details>

These both present opportunities for optimization! For now, let's just tackle the first one: we need to somehow give Forge a specific ordering on the adders. 

**FILL: `is plinear` -- not `linear`. What it does, why we don't do it in a constraint (no way to name specific atoms outside an example yet...)**

Now Forge finishes the check in under a second on my laptop. Eliminating symmetries can make a huge difference! 
