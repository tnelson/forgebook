# Bounds and Booleans: How Forge Works

> "The world is everything that is the case. The world is the totality of facts, not of things. The world is determined by the facts, and by these being all the facts."
> 
>  Ludwig Wittgenstein (Tractatus Logico-philosophicus)

## How Does Forge Work?

Every `run` (or `test`, or `example`) command defines a _search problem_: find some instance that satisfies the given constraints and is within the given bounds. 

When you click "Run", Forge compiles this search problem into a _boolean_ satisfiability problem, which it can give to a (hopefully well-engineered!) 3rd party boolean solver. **You'll be writing such a solver for homework after Spring break!**

There are complications, though. The search problem is in terms of atomic _things_: objects of particular types, which can go into sets and relations and so on. In contrast, a boolean problem is in terms of boolean variables: atomic _truths_ that can be combined with `and`, `or`, etc. Somehow, we need to bridge that gap.

## What Boolean Solvers Understand

As an example of where Forge needs to end up, here's an example of a real problem to pass to a boolean solver. It's in a standard format called DIMACS, and it describes finding a solution to the 4-queens problem. 

There are many different ways to express this problem to the solver, but this is one of them. What do you think it's saying, exactly?

```
c DIMACS for 4 queens
c 
p cnf 16 84
1 2 3 4 0
-1 -2 0
-1 -3 0
-1 -4 0
-2 -3 0
-2 -4 0
-3 -4 0
5 6 7 8 0
-5 -6 0
-5 -7 0
-5 -8 0
-6 -7 0
-6 -8 0
-7 -8 0
9 10 11 12 0
-9 -10 0
-9 -11 0
-9 -12 0
-10 -11 0
-10 -12 0
-11 -12 0
13 14 15 16 0
-13 -14 0
-13 -15 0
-13 -16 0
-14 -15 0
-14 -16 0
-15 -16 0
1 5 9 13 0
-1 -5 0
-1 -9 0
-1 -13 0
-5 -9 0
-5 -13 0
-9 -13 0
2 6 10 14 0
-2 -6 0
-2 -10 0
-2 -14 0
-6 -10 0
-6 -14 0
-10 -14 0
3 7 11 15 0
-3 -7 0
-3 -11 0
-3 -15 0
-7 -11 0
-7 -15 0
-11 -15 0
4 8 12 16 0
-4 -8 0
-4 -12 0
-4 -16 0
-8 -12 0
-8 -16 0
-12 -16 0
-1 -6 0
-1 -11 0
-1 -16 0
-2 -7 0
-2 -12 0
-2 -5 0
-3 -8 0
-3 -6 0
-3 -9 0
-4 -7 0
-4 -10 0
-4 -13 0
-5 -10 0
-5 -15 0
-6 -11 0
-6 -16 0
-6 -9 0
-7 -12 0
-7 -10 0
-7 -13 0
-8 -11 0
-8 -14 0
-9 -14 0
-10 -15 0
-10 -13 0
-11 -16 0
-11 -14 0
-12 -15 0
```

You won't need to write a parser for DIMACS for your homework; we'll give that to you. But the format tells us a lot about what a solver understands. Here are a few facts about DIMACS:
* Boolean variables in DIMACS are represented by integers greater than zero. 
* If `p` is a variable, then `not p` is represented as the integer `-p`. 
* Lines starting with a `c` are comments.
* The line `p cnf 16 84` says there are 16 variables and 84 _clauses_. A clause is a set of variables and their negations combined with `or`. E.g., `4 8 12 16 0` means `4 or 8 or 12 or 16` (`0` is a line-terminator).
* To satisfy the input, every clause must be satisfied.

A set of constraints expressed as a set of clauses, each of which must hold true, is said to be in _Conjunctive Normal Form_ (CNF). Boolean solvers often expect input in CNF, for algorithmic reasons we'll see after break.

Now that you know how to read the input format, you might be able to see how the boolean constraints work. Any ideas?

<details>
<summary>Think, then click!</summary>

There's one variable for every square on the $4 \times 4$ squares. `1 2 3 4` says that there must be a queen somewhere on the first row. `-1 -2` says that if there is a queen at $1,1$ there cannot also be a queen at $1,2$. And so on.    

</details>


## "The world is that which is the case"

Consider this Forge model and corresponding `run` command:

```alloy
abstract sig Person {
  followers: set Person
}
one sig Alice, Bob, Charlie extends Person {}
run {some followers} for exactly 3 Person 
```

How many potential instances are there? Note that there can only ever be exactly 3 people, since `Person` is `abstract`.

<details>
<summary>Think, then click!</summary>
There are always exactly 3 people, and the only relation that can vary is `followers`, which has 2 columns. That means $3^2 = 9$ potential pairs of people, and the field contains a set of those. So there are $2^9 = 512$ potential instances.
</details>
</br>

Notice how we reached that number. There are 9 potential pairs of people. 9 potential follower relationships. 9 essential things that may, or may not, be the case in the world. Nothing else.

If you run Forge on this model, you'll see statistics like these:

```
#vars: (size-variables 10); #primary: (size-primary 9); #clauses: (size-clauses 2)
Transl (ms): (time-translation 122); Solving (ms): (time-solving 1)
```

The timing may vary, but the other stats will be the same. The thing to focus on is: 9 `primary variables`. Primary variables correspond to these atomic truths, which in this case is just who follows who in our fixed 3-person world.

Let's try increasing the size of the world:

```alloy
run {some followers} for 4 Person
```

Now we have a 4th person---or rather, we _might_ have a 4th person. When we run, Forge shows:

```
#vars: (size-variables 27); #primary: (size-primary 17); #clauses: (size-clauses 18)
```

We've gone from 9 to 17 primary variables. Why? 

<details>
<summary>Think, then click!</summary>
    
There is another _potential_ `Person` in the world; the world may be either size 3 or 4. Whether or not this fourth person exists is 1 new Boolean variable. And since there are _4_ potential people in the world, there are now $4^2 = 16$ potential follower relationships. 
    
This equals 17 variables.
</details>
</br>

## Intermediate Representation: Lower Bounds, Upper Bounds

Forge's `inst` blocks allow more fine-grained control over what can be true in an instance. To motivate this, let's increase the verbosity and look at what Forge produces as an intermediate problem description for the above model.

```alloy
option verbose 5
```

Let's focus on a few lines:

```
(univ 20)
```

This tells the compiler that there are 20 potential objects in the world. (Why 20? Because the default bitwidth is 4. 16 integers plus 4 potential people.) These objects get assigned integer identifiers by the compiler. This is an unfortunate overlap in the engine's language: _objects_ (input) get assigned integers, as do _boolean variables_ (output). **But they are not the same thing!**

Next, the compiler gets provided a _lower_ and _upper_ bound for every relation in the model.
* The _lower_ bound is a set of tuples that must always be in the relation.
* The _upper_ bound is a set of tuples that may be in the relation.

Here are the bounds on `Int`:

```
(r:Int [{(0) (1) (2) (3) (4) (5) (6) (7) (8) (9) (10) (11) (12) (13) (14) (15)} :: {(0) (1) (2) (3) (4) (5) (6) (7) (8) (9) (10) (11) (12) (13) (14) (15)}])
```

The lower bound comes first, then a `::`, then the upper bound. Annoyingly, every integer gets assigned an object identifier, and so these tuples containing `0` through `15` are actually the representatives of integers `-8` through `7`. This is an artifact of how the solver process works.

Here's the bound on `Person` and its three sub-`sig`s:

```
(r:Person [{(16) (17) (18)} :: {(16) (17) (18) (19)}])
(r:Alice [{(16)} :: {(16)}])
(r:Bob [{(17)} :: {(17)}])
(r:Charlie [{(18)} :: {(18)}])
```

The lower bound on `Person` contains 3 object identifiers, because there must always be 3 distinct objects (representing our three `one` sigs). There's an object in the upper, but not the lower, bound, because that fourth person may or may not exist. `Alice`, `Bob`, and `Charlie` are exactly set to be those 3 always-present objects.

Finally:

```
(r:followers [(-> none none) :: {(16 16) (16 17) (16 18) (16 19) (17 16) (17 17) (17 18) (17 19) (18 16) (18 17) (18 18) (18 19) (19 16) (19 17) (19 18) (19 19)}])
```

The `followers` relation may be empty, and it may contain any of the 16 ordered pairs of potential `Person` objects.

_Any tuple in the upper bound of a relation, that isn't also in the lower bound, gets assigned a boolean variable._
* If a tuple isn't in the upper bound, it can never exist in an instance---it would always be assigned false---and so we needn't assign a variable.
* If a tuple is in the lower bound, it must always exist in an instance---it would always be assigned true---and so we can again omit a variable.

**Important: To minimize confusion between the object numbered $k$ and the Boolean variable numbered $k$, which are not the same thing, from now on in these notes, numbers will correspond only to Boolean variables.**

## From Forge Constraints to Boolean Constraints

Once we know the set of Boolean variables we'll use, we can translate Forge constraints to purely Boolean ones via substitution. 

The actual compiler is more complex than this, but here's an example of how a basic compiler might work. Suppose we have the constraint:

```alloy
all p: Person | Alice in p.followers
```

There are no `all` quantifiers in Boolean logic. How can we get rid of it?

<details>
<summary>Think, then click!</summary>
    
An `all` is just a big `and` over the upper bound on `Person`. So we substitute (note here we're using $Person3$ as if it were defined in our model, because it's a _potential_ part of every instance):
    
```alloy
Alice in Alice.followers
Alice in Bob.followers
Alice in Charlie.followers
(Person3 in Person) implies Alice in Person3.followers
``` 
</details>
</br>

There are similar rules for other operators.

## Skolemization

Forge performs a process called _Skolemization_, named after the logician [Thoralf Skolem](https://en.wikipedia.org/wiki/Thoralf_Skolem), to convert select `some` quantifiers into supplemental relations. 

The idea is: to satisfy a `some` quantifier, some object exists that can be plugged into the quantifier's variable to make the child formula true. Skolemization reifies that object witness into the model as a new constant. This:
* makes debugging easier sometimes, since you can immediately _see_ what might satisfy the quantifier constraint; and
* sometimes aids in efficiency. 

So if you see a relation labeled something like `$x_some32783`, it's one of these _Skolem_ relations, and points to a value for a `some` quantified variable `x`. (Forge adds the numeric suffix to help disambiguate variables with the same name.)


## Symmetry Breaking

Let's return to the original model:

```alloy
abstract sig Person {
  followers: set Person
}
one sig Alice, Bob, Charlie extends Person {}
run {some followers} for exactly 3 Person 
```

We decided it probably had $512$ instances. But does it _really_? Let's hit `Next` a few times, and count!

Actually, that sounds like a lot of work. Let's simplify things a bit more:

```alloy
abstract sig Person {
  follower: one Person
}
one sig Alice, Bob, Charlie extends Person {}
run {} for exactly 3 Person 
```

Now everybody has exactly one follower. There are still 9 potential tuples, but we're no longer storing _sets_ of them for each `Person`. Put another way, every instance corresponds to an ordered triplet of `Person` objects (Alice's follower, Bob's followers, and Charlie's follower). There will be $3 \times 3 \times 3 = 3^3 = 27$ instances. And indeed, if we click "Next" 26 times, this is what we find. 

Now suppose we didn't name the 3 people, but just had 3 anonymous `Person` objects:

```alloy
sig Person {
  follower: one Person
}
run {} for exactly 3 Person 
```

The math is still the same: 27 instances. But now we only get 9 before hitting the unsat indicator of "no more instances".

What's going on?

Forge tries to avoid showing you the same instance multiple times. And, if objects are un-named and the constraints can never distinguish them, instances will be considered "the same" if you can arrive at one by renaming elements of the other. E.g., 

```
Person1 follows Person2
Person2 follows Person3
Person3 follows Person1
```

would be considered equivalent to:

```
Person2 follows Person1
Person3 follows Person2
Person1 follows Person3
```

since the individual `Person` atoms are _anonymous_. We call these instances _isomorphic_ to each other, or _symmetries_ of each other.

Formally, we say that Forge finds every instance "up to isomorphism". This is useful for:
* increasing the quality of information you get from paging through instances; and
* improving the runtime on unsatisfiable problems.

This process isn't always perfect: some equivalent instances can sneak in. Removing _all_ equivalent instances turns out to sometimes be even more expensive than solving the problem. So Forge provides a best-effort, low cost attempt.

You can adjust the budget for symmetry breaking via an option:
*  `option sb 0` turns off symmetry breaking; and
*  `option sb 20` is the default.

If we turn off symmetry-breaking, we'll get the expected number of instances in the above run: 27.

### Implementing Symmetry Breaking

Forge doesn't just filter instances after they're generated; it _adds_ extra constraints that try to rule out symmetric instances. These constraints are guaranteed to be satisfied by at least one element of every equivalence class of instances. There's a lot of research work on this area, e.g., [this paper](https://kaiyuanw.github.io/papers/paper22-tacas20.pdf) from 2020.

## Looking Ahead

After Spring break, we'll come back and talk about:
* converting to CNF (Tseitin's Transformation); and
* the algorithms that Boolean solvers use.

You will write your own solver, which you might even be able to plug in to Forge and compare its performance vs. the solvers we include by default.


