# Ripple Carry Adder 

Let's model a third system in Froglet. We'll focus on something even more concrete, something that is implemented in _hardware_: a circuit for adding together two numbers called a _ripple-carry adder_ (RCA). 

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

## Examples

We'll always try to write at least some positive _and_ negative examples.

### Positive Examples

**FILL**

### Negative Examples

**FILL**

## Run 

**FILL**

## More Domain Predicates and Validation

**FILL**


