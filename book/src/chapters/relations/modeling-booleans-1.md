# Modeling Boolean Logic (Syntax, Semantics, and Sets)

~~~admonish note title="CSCI 1710"
Welcome back from long weekend!

* Start on Curiosity Modeling if you haven't already. You don't need "approval", but check my advice in the megathread. Post on Ed if you have questions or concerns. I haven't seen many ideas in the thread yet; please do share yours! 
* Professionalism is important in 1710. If you are unprofessional with your project or case study partner(s), your grade may suffer. 

~~~

Livecode is [here](./booleanLogic.frg).

Today, we'll be writing a new model from scratch. Across today and Friday, we'll have 3 goals:
* distinguishing _syntax_ versus _semantics_ (and what that even means);
* introducing sets to Forge; and
* learning a way to model recursive concepts in a language without recursion.

<!-- ## Forge 2 Review

See Lecture capture. We discussed a handful of test cases that you all reported for Forge 2.

[Form link for visualization feedback](https://forms.gle/2GGtmBfSTfqFiU557).  -->

## In-class exercise

We'll warm up with an in-class exercise. I'd like everyone to take 5 minutes responding to this [request for feedback about Toadus Ponens](https://docs.google.com/forms/d/e/1FAIpQLSfv7p6PH1ZkXQuSc-29NmFRwDS5JQiDX-6cHdHehvabpfBE7g/viewform). Feedback here is actionable; e.g., we might be able to make Forge give an overall test report rather than stopping after the first test failure---something that came out of the feedback so far.  

## Boolean Formulas

You've all worked a lot with boolean formulas before. Any time you write the conditional for an `if` statement in a programming language, and you need `and`s and `or`s and `not`s, you're constructing a boolean formula. E.g., if you're building a binary search tree, you might write something like:

```java=
if(this.getLeftChild()!= null &&
   this.getLeftChild().value < goal) { 
    ... 
}
```

The conditional inside the `if` is a boolean formula with two _variables_ (also sometimes called _atomic propositions_): `leftChild != null` and `leftChild.value < goal`. Then a single `&&` (and) combines the two.

We might describe this example in Forge as:

```alloy
example leftBranchFormula is {} for {
  And = `And0
  Var = `VarNeqNull + `VarLTLeft
  Formula = And + Var
}
```

Can you think of more examples of boolean formulas?

## Modeling Boolean Formulas

Let's define some types for formulas in Froglet. It can be helpful to have an `abstract sig` to represent all the formula types, and then extend it with each kind of formula:

```alloy
-- Syntax: formulas
abstract sig Formula {}
-- Forge doesn't allow repeated field names, so manually disambiguate
sig Var extends Formula {} 
sig Not extends Formula {child: one Formula} 
sig Or extends Formula {o_left, o_right: one Formula}
sig And extends Formula {a_left, a_right: one Formula}
```

If we really wanted to, we could go in and add `sig Implies`, `sig IFF`, and other operators. For now, we'll stick with these.

As in the family-trees homework, we need a notion of well-formedness. What would make a formula in an instance "garbage"? Well, if the syntax tree contained a cycle, the formula wouldn't be a formula! We'd like to write a `wellformed` predicate that excludes something like this:

```alloy
pred trivialLeftCycle { 
    some a: And | a.a_left = a
}
pred notWellformed { not wellformed }
assert trivialLeftCycle is sufficient for notWellformed
```

Like (again) in family trees, we've got multiple fields that a cycle could occur on. We don't just need to protect against this basic example, but against cycles that use multiple kinds of field. Let's build a helper predicate:

```alloy
-- IMPORTANT: remember to update this if adding new fmla types!
pred subFormulaOf[sub: Formula, f: Formula] {
  reachable[sub, f, child, a_left, o_left, a_right, o_right]
}
```

At first, this might seem like a strange use of a helper---just one line, that's calling `reachable`. However, what if we need to check this in multiple places, and we want to add more formula types (`Implies`, say)? Then we need to remember to add the fields of the new `sig` everywhere that `reachable` is used. This way, we have _one_ place to make the change.

```alloy
-- Recall we tend to use wellformed to exclude "garbage" instances
--   analogous to PBT *generator*; stuff we might want to verify 
--   or build a system to enforce goes elsewhere!
pred wellformed {
  -- no cycles
  all f: Formula | not subFormulaOf[f, f]
}
```

We'll want to add `wellformed` to the first example we wrote, but it should still pass. Let's run the model and look at some formulas!

```alloy
run {wellformed}
```

That's prone to giving very small examples, though, so how about this?
```alloy
run {
  wellformed
  some top: Formula | {
    all other: Formula | top != other => {
      subFormulaOf[other, top]
    }
  }
} for exactly 8 Formula
```

Note this is another good use for a `subFormulaOf` predicate: if we wrote a bunch of tests that looked like this, and then added more, we wouldn't have to remember to add the new field to a bunch of separate places.

## `inst` Syntax

The syntax that you use in `example`s can be used more generally. We can define a partial instance of our own using the `inst` command. We can then provide the instance to `run`, tests, and other commands along with numeric bounds. This is sometimes _great_ for performance optimization. 

For example:

```alloy
inst onlyOneAnd {
  And = `And0  
}

run {
  wellformed
} for exactly 8 Formula for onlyOneAnd
```

Compare the statistical info for the run with and without this added partial instance information. Do you notice any changes? What do you think might be going on, here? 

<details>
<summary>Think, then click!</summary>

The statistical information is reporting runtime, but also something else. It turns out these express how big the boolean constraint problem is. 

</details>

Last time we started modeling boolean formulas in Forge. We'd defined what a "well-formed" formula was, and then ran Forge to produce an example with `run {wellformed}`.

That's prone to giving very small examples, though, so how about this?
```alloy
run {
  wellformed
  some top: Formula | {
    all other: Formula | top != other => {
      subFormulaOf[other, top]
    }
  }
} for exactly 8 Formula
```

Note this is an example of why we wrote a `subFormulaOf` predicate: it's convenient for re-use! If we wrote a bunch of tests that looked like this, and then added more, we wouldn't have to remember to add the new field to a bunch of separate places.

<!-- ## Sets in Forge -- Survey

[Survey](https://forms.gle/TRu83Wy8fVg8XHpb7) -->


## Modeling the _Meaning_ Of Boolean Circuits

What's the _meaning_ of a formula? So far they're just bits of syntax. Sure, they're pretty trees, but we haven't defined a way to understand them or interpret them. 

This distinction is _really_ important, and occurs everywhere we use a language (natural, programming, modeling, etc.). Let's go back to that BST example:

```java=
if(this.getLeftChild() != null && this.getLeftChild().value < goal) { 
    ... 
}
```

Suppose that the BST class increments a counter whenever `getLeftChild()` is called. If it's zero before this `if` statement runs, what will it be afterward?

<details>
<summary>Think, then click!</summary>

It depends! If the left-child is non-null, the counter will hold `2` afterward. but what if the left-child is null? 
    
If we're working in a language like Java, which "short circuits" conditionals, the counter would be `1` since the second branch of the `&&` would never need to execute. 
    
But in another language, one that _didn't_ have short-circuiting conditionals, the counter might be `2`. 
</details>
<br/>

If we don't know the _meaning_ of that `if` statement and the `and` within it, we don't actually know what will happen! Sure, we have an intuition---but when you're learning a new language, experimenting to check your intuition is a good idea. Syntax can mislead us. 

So let's understand the meaning, the _semantics_, of boolean logic. What can I _do_ with a formula? What's it meant to enable? 

<details>
<summary>Think, then click!</summary>
If I have a formula, I can plug in various values into its variables, and see whether it evaluates to true or false for those values.  

So let's think of a boolean formula like a function from variable valuations to boolean values. 
</details>
<br/>

There's many ways to model that, but notice there's a challenge: what does it mean to be a function that maps _a variable valuation_ to a boolean value? Let's make a new `sig` for that: 

```alloy
-- If we were talking about Forge's underlying boolean 
-- logic, this might represent an instance! More on that soon.
sig Valuation {
  -- [HELP: what do we put here? Read on...]
}
```

We have to decide what field a `Valuation` should have. And then, naively, we might start out by writing a _recursive_ predicate or function, kind of like this pseudocode:

```alloy
pred semantics[f: Formula, val: Valuation] {
  f instanceof Var => val sets the f var true
  f instanceof And => semantics[f.a_left, val] and semantics[f.a_right, val]
  ...
}
```

This _won't work!_ Forge is not a recursive language. We've got to do something different.

Let's move the recursion into the model itself, by adding a mock-boolean sig: 

```alloy
one sig Yes {}
```
and then adding a new field to our `Formula` sig (which we will, shortly, constrain to encode the semantics of formulas):

```alloy
   satisfiedBy: pfunc Valuation -> Yes
```

This _works_ but it's a bit verbose. It'd be more clean to just say that every formula has a _set_ of valuations that satisfy it. So I'm going to use this opportunity to start introducing sets in Forge. 

#### Language change!

First, let's change our language from `#lang forge/bsl` to `#lang forge`. This gives us a language with more expressive power, but also some subtleties we'll need to address.

~~~admonish tip title="Relational Forge"
This language is called **Relational Forge**, for reasons that will become apparent. For now, when you see `#lang forge` rather than `#lang forge/bsl`, expect us to say "relational", and understand there's more expressivity there than Froglet gives you.
~~~

#### Adding sets...

Now, we can write:

```alloy
abstract sig Formula {
  -- Work around the lack of recursion by reifying satisfiability into a field
  -- f.satisfiedBy contains an instance IFF that instance makes f true.
  -- [NEW] set field
  satisfiedBy: set Valuation
}
```

and also:

```alloy
sig Valuation {
  trueVars: set Var
}
```

And we can encode the semantics as a predicate like this:

```alloy
-- IMPORTANT: remember to update this if adding new fmla types!
-- Beware using this fake-recursion trick in general cases (e.g., graphs)
-- It's safe to use here because the data are tree shaped. 
pred semantics
{
  -- [NEW] set difference
  all f: Not | f.satisfiedBy = Valuation - f.child.satisfiedBy
  -- [NEW] set comprehension, membership
  all f: Var | f.satisfiedBy = {i: Valuation | f in i.trueVars}
  -- [NEW] set union
  all f: Or  | f.satisfiedBy = f.o_left.satisfiedBy + f.o_right.satisfiedBy
  -- [NEW] set intersection
  all f: And | f.satisfiedBy = f.a_left.satisfiedBy & f.a_right.satisfiedBy
}
```

There's a lot going on here, but if you like the idea of sets in Forge, some of these new ideas might appeal to you. However, there are some _Forge_ semantics questions you might have. 

<details>
<summary>Wait, was that a joke?</summary>
No, it actually wasn't! Are you sure that you know the _meaning_ of `=` in Forge now? 
</details>
<br/>

Suppose I started explaining Forge's set-operator semantics like so:

* Set union (`+`) in Forge produces a set that contains exactly those elements that are in one or both of the two arguments. 
* Set intersection (`&`) in Forge produces a set that contains exactly those elements that are in both of the two arguments.
* Set difference (`-`) in Forge produces a set that contains exactly those elements of the first argument that are not present in the second argument.
* Set comprehension (`{...}`) produces a set containing exactly those elements from the domain that match the condition in the comprehension.


That may sound OK at a high level, but you shouldn't let me get away with _just_ saying that. (Why not?) 

<details>
<summary>Think, then click!</summary>

What does "produces a set" mean? And what happens if I use `+` (or other set operators) to combine a set and another kind of value? And so on... 

</details>
<br/>

We're often dismissive of semantics---you'll hear people say, in an argument, "That's just semantics!" (to mean that the other person is being unnecessarily pedantic and quibbling about technicalities, rather than engaging). But especially when we're talking about computer languages, precise definitions _matter a lot_! 

~~~admonish warning title="The key idea"
Here's the vital high-level idea: **in Relational Forge, all values are sets.** A singleton value is just a set with one element, and `none` is the empty set. That's it. 
~~~

This means that `+`, `&`, etc. and even `=` are well-defined, but that our usual intuitions (sets are different from objects) start to break down when we add sets into the language. **This is one of the major reasons we started with Froglet**, because otherwise the first month of 1710 is a lot of extra work for people who haven't yet taken 0220, or who are taking it concurrently. Now, everyone is familiar with things like constraints and quantification, and there's less of a learning curve.

From now on, we'll admit that everything in Forge is a set, but introduce the ideas that grow from that fact gradually, resolving potential confusions as we go.

#### Returning to well-formedness

Now we have a new kind of ill-formed formula: one where the `semantics` haven't been properly applied. So we enhance our `wellformed` predicate:

```alloy
pred wellformed {
  -- no cycles
  all f: Formula | not subFormulaOf[f, f]
  -- the semantics of the logic apply
  semantics
}
```


## Some Validation

Here are some examples of things you might check in the model. Some are validation of the model (e.g., that it's possible to have instances that disagree on which formulas they satisfy) and others are results we might expect after taking a course like 0220.

```alloy
-- First, some tests for CONSISTENCY. We'll use test-expect/is-sat for these. 
test expect {
  nuancePossible: {
    wellformed
    -- [NEW] set difference in quantifier domain
    --   Question: do we need the "- Var"?
    some f: Formula - Var | {
      some i: Valuation | i not in f.satisfiedBy
      some i: Valuation | i in f.satisfiedBy
    }    
  } for 5 Formula, 2 Valuation is sat  
  ---------------------------------
  doubleNegationPossible: {
    wellformed 
    some f: Not | {
      -- [NEW] set membership (but is it "subset of" or "member of"?)
      f.child in Not      
    }
  } for 3 Formula, 1 Valuation is sat  
} 

-- Now, what are some properties we'd like to check? 
-- We already know a double-negation is possible, so let's write a predicate for it
-- and use it in an assertion. Since it's satisfiable (above) we need not worry 
-- about vacuous truth for this assertion.
pred isDoubleNegationWF[f: Formula] { 
    f in Not  -- this is a Not
    f.child in Not -- that is a double negation
    wellformed
} 
pred equivalent[f1, f2: Formula] {
    f1.satisfiedBy = f2.satisfiedBy
}
-- Note that this check is always with respect to scopes/bounds. "equivalent" isn't 
-- real logical equivalence if we have a bug in our model! 
assert all n: Not | isDoubleNegationWF[n] is sufficient for equivalent[n, n.child.child] 
  for 5 Formula, 4 Valuation is unsat    

-- de Morgan's law says that 
-- !(x and y) is equivalent to (!x or !y) and vice versa. Let's check it. 

-- First, we'll set up a general scenario with constraints. This _could_ also 
-- be expressed with `inst`, but I like using constraints for this sort of thing. 
pred negatedAnd_orOfNotsWF[f1, f2: Formula] {
    wellformed
    
    -- f1 is !(x and y)
    f1 in Not 
    f1.child in And      
    -- f2 is (!x or !y)
    f2 in Or
    f2.o_left in Not
    f2.o_right in Not
    f2.o_left.child = f1.child.a_left
    f2.o_right.child = f1.child.a_right      
}

assert all f1, f2: Formula | 
  negatedAnd_orOfNotsWF[f1, f2] is sufficient for equivalent[f1, f2]
  for 8 Formula, 4 Valuation is unsat      

-- If we're going to trust that assertion passing, we need to confirm 
-- that the left-hand-side is satisfiable! 
test expect {
    negatedAnd_orOfNotsWF_sat: {
        some f1, f2: Formula | negatedAnd_orOfNotsWF[f1, f2]
    } for 8 Formula, 4 Valuation is sat
}
```
  

<!-- ```  
  ---------------------------------    
  andAssociativePossible: {
    -- ((X and Y) and Z) 
    --      ^ A1MID  ^ A1TOP
    -- (X and (Y and Z)
    --      ^ A2TOP  ^ A2MID
    wellformed
    some A1TOP, A2TOP, A1MID, A2MID : And {
      A1TOP.a_left = A1MID
      A2TOP.a_right = A2MID
      A1TOP.a_right = A2MID.a_right
      A1MID.a_left = A2TOP.a_left
      A1MID.a_right = A2MID.a_left
    }
  } for 8 Formula, 4 Valuation is sat 
  andAssociativeCheck: {
    -- ((X and Y) and Z) 
    --      ^ A1MID  ^ A1TOP
    -- (X and (Y and Z)
    --      ^ A2TOP  ^ A2MID
    wellformed
    some A1TOP, A2TOP, A1MID, A2MID : And {
      A1TOP.a_left = A1MID
      A2TOP.a_right = A2MID
      A1TOP.a_right = A2MID.a_right
      A1MID.a_left = A2TOP.a_left
      A1MID.a_right = A2MID.a_left
      A1TOP.satisfiedBy != A2TOP.satisfiedBy
    }
  } for 8 Formula, 4 Valuation is unsat 
} 
```
-->


