## From Boards to Games

What do you think a _game_ of tic-tac-toe looks like? How should we model the moves between board states?

<details>
<summary>Think, then click!</summary>

It's often convenient to think of the game as a big graph, where the nodes are the states (possible board configurations) and the edges are transitions (in this case, legal moves of the game). Here's a rough sketch:  
    
![](https://i.imgur.com/YmsbRp8.png)
  
</details>
<br/>

A game of tic-tac-toe is a sequence of steps in this graph, starting from the empty board. Let's model it.

First, what does a move look like? A player puts their mark at a specific location. In Alloy, we'll represent this using a _transition predicate_: a predicate that says when it's legal for one state to evolve into another. We'll often call these the _pre-state_ and _post-state_ of the transition:

```alloy
pred move[pre: Board, row: Int, col: Int, p: Player, post: Board] {
  // ...
}
```

What constraints should we add? It's useful to divide the contents of such a predicate into:
* a _guard_, which allows the move only if the pre-state is suitable; and 
* an _action_, which defines what is in the post-state based on the pre-state and the move parameters.
 
For the guard, in order for the move to be valid, it must hold that in the pre-state:
* nobody has already moved at the target location; and
* it's the moving player's turn.

For the action:
* the new board is the same as the old, except for the addition of the player's mark at the target location.

Now we can fill in the predicate. Let's try something like this:

```alloy
pred move[pre: Board, row: Int, col: Int, p: Player, post: Board] {
  -- guard:
  no pre.board[row][col]   -- nobody's moved there yet
  p = X implies XTurn[pre] -- appropriate turn
  p = O implies OTurn[pre]  
  
  -- action:
  post.board[row][col] = p
  all row2: Int, col2: Int | (row!=row2 and col!=col2) implies {        
     post.board[row2][col2] = pre.board[row2][col2]     
  }  
}
```

There are many ways to write this predicate. However, we're going to stick with this form because it calls out an important point. Suppose we had only written `post.board[row][col] = p` for the action, without the `all` on the next following lines. Those added lines, which we'll call a _frame condition_, say that all other squares remain unchanged; without them, the contents of any other square might change in any way. Leaving them out would cause an _underconstraint_ bug: the predicate would be too weak to accurately describe moves in tic-tac-toe. 

**Exercise**: comment out the 3 frame-condition lines and run the model. Do you see moves where the other 8 squares change arbitrarily?

**Exercise**: could there be a bug in this predicate? (Run Forge and find out!)

<details>
<summary>Think, then click</summary>

The `all row2...` formula says that for any board location where _both the row and column differ_ from the move's, the board remains the same. But is that what we really wanted? Suppose `X` moves at location `1`, `1`. Then of the 9 locations, which is actually protected?

|Row|Column|Protected?|
|---|------|----------|
|  0|     0|yes       |
|  0|     1|no (column 1 = column 1)|
|  0|     2|yes       |
|  1|     0|no (row 1 = row 1)|
|  1|     1|no (as intended)|
|  1|     2|no (row 1 = row 1)|
|  2|     0|yes       |
|  2|     1|no (column 1 = column 1)|
|  2|     2|yes       |

Our frame condition was _too weak_! We need to have it take effect whenever _either_ the row or column is different. Something like this will work:

```alloy
  all row2: Int, col2: Int | 
    ((row2 != row) or (col2 != col)) implies {    
       post.board[row2][col2] = pre.board[row2][col2]     
  }  

``` 
</details>

### A Simple Property

Once someone wins a game, does their win still persist, even if more moves are made? I'd like to think so: moves never get undone, and in our model winning just means the existence of 3-in-a-row for some player. We probably even believe this property without checking it. However, it won't always be so straightforward to show that properties are preserved by the system. We'll check this one in Forge as an example of how you might prove something similar in a more complex system.

~~~admonish note title="Looking ahead"
This is our first step into the world of verification. Asking whether or not a program, algorithm, or other system always satisfies some assertion is a core problem in formal methods, and has a long and storied history. 
~~~

We'll tell Forge to find us pairs of states, connected by a move: the _pre-state_ before the move, and the _post-state_ after it. That's _any_ potential transition in tic-tac-toe. The trick is in adding two more constraints. We'll say that someone has won in the pre-state, but they _haven't won_ in the post-state.

```alloy
pred winningPreservedCounterexample {
  some pre, post: Board | {
    some row, col: Int, p: Player | 
      move[pre, post, row, col, p]
    winner[pre, X]
    not winner[post, X]
  }
}
run {
  all s: Board | wellformed[s]
  winningPreservedCounterexample
}
```

The check passes---Forge can't find any counterexamples. We'll see this reported as "UNSAT" in the visualizer. 

~~~admonish tip title="Next button" 
The visualizer also has a "Next" button. If you press it enough times, Forge runs out of solutions to show. 
~~~

## Generating Complete Games

Recall that our worldview for this model is that systems _transition_ between _states_, and thus we can think of a system as a directed graph. If the transitions have arguments, we'll sometimes label the edges of the graph with those arguments. This view is sometimes called a _discrete event_ model, because one event happens at a time. Here, the events are moves of the game. In a bigger model, there might be many different types of events.

**TODO: I think this goes later in the book, we don't want to start on finite traces yet.**

Today, we'll ask Forge to find us traces of the system, starting from an initial state. We'll also add a `Game` sig to incorporate some metadata.

```alloy
one sig Game {
  initialState: one Board,
  next: pfunc Board -> Board
}

pred traces {
    -- The trace starts with an initial state
    starting[Game.initialState]
    no sprev: Board | Game.next[sprev] = Game.initialState
    -- Every transition is a valid move
    all s: Board | some Game.next[s] implies {
      some row, col: Int, p: Player |
        move[s, row, col, p, Game.next[s]]
    }
}
```

By itself, this wouldn't be quite enough; we might see a bunch of disjoint traces. We could add more constraints manually, but there's a better option: tell Forge, at `run`time, that `next` represents a linear ordering on states.

```alloy
run {
  traces
} for {next is linear}
```

The key thing to notice here is that `next is linear` isn't a _constraint_; it's a separate annotation given to Forge alongside a `run` or a test. Never put such an annotation in a constraint block; Forge won't understand it. These annotations narrow Forge's _bounds_ (the space of possible worlds to check) which means they can often make problems more efficient for Forge to solve.

In general, Forge accepts such annotations _after_ numeric bounds. E.g., if we wanted to see full games, rather than unfinished game prefixes (the default bound on any sig, including `Board`, is up to 4) we could have asked:

```alloy
run {
  traces
} for exactly 10 Board for {next is linear}
```

You might notice that because of this, some traces are excluded. That's because `next is linear` forces exact bounds on `Board`. More on this next time.

<!-- ## Testing Models: Examples

Forge has a number of features that make it easier to _test_ your models. Here's one: `example`. We'll make a new file for our tests called `feb03_ttt.tests.frg` and open the model there. 

An _example_ in Forge is like a `run` except that it only opens the visualizer if the test fails. The example defines a full instance and then checks whether that instance satisfies a given predicate. So we'll make a new predicate that's "instance-wide", and checks wellformedness for all boards.

```alloy
#lang forge/bsl 
open "feb03_ttt.frg"

pred allWellformed {
    all b: Board | wellformed[b]
}
```

Then we'll fill in an example. These have a standard format, but the language of an example is a bit different: you're defining an _instance_, not a set of constraints.

```alloy
-- *TEST CASE* in Forge: this instance satisfies this predicate
example middleRowWellformed is {allWellformed} for {
    -- "for 3 Int" (prefer that outside examples)
    #Int = 3
    -- the backquote denotes an OBJECT by name
    -- use only these on the right-hand side of = here
    X = `X0
    O = `O0
    Player = `X0 + `O0
    Board = `Board0
    board = `Board0 -> (1 -> 0 -> `X0 + 
                        1 -> 1 -> `X0 +
                        1 -> 2 -> `X0)    
}
```

This is a bit verbose, but it completely defines an instance with 1 board and 3 moves placed. You can read the `board =` line as saying, for `Board0`, there's a dictionary with these 3 entries.

More on testing next time! -->

## The Evaluator

Moreover, since we're now viewing a single fixed instance, we can _evaluate_ Forge expressions in it. This is great for debugging, but also for just understanding Forge a little bit better. Open the evaluator here at the bottom of the right-side tray, under theming. Then enter an expression or constraint here:

![](https://i.imgur.com/tnT8cgo.png)

Type in something like `some s: State | winner[s, X]`. Forge should give you either `#t` (for true) or `#f` (for false) depending on whether the game shows `X` winning the game.

### Optimizing

You might notice that this model takes a while to run, after we start reasoning about full games. Why might that be? Let's re-examine our bounds and see if there's anything we can adjust. In particular, here's what the evaluator says we've got for integers:

![](https://i.imgur.com/UJJUqdB.png)

Wow---wait, do we really **need** to be able to count up to `7` for this model? Probably not. If we change our integer bounds to `3 Int` we'll still be able to use `0`, `1`, and `2`, and the search space is much smaller.




<!-- ~~~admonish note title="For Brown CSCI 1710"
You might have seen on your homework that we're asking you to generate a family tree demonstrating how someone can be their own "grandparent", without also being their own "ancestor". This might, quite reasonably, sound contradictory.

One of the tricky things about modeling is that often you're trying to formalize something informal. Is it possible that one of those statements is about biology, and one is a social definition, which might be a bit more broad? 
~~~ -->

## Anticipated Questions

**TODO: much of this should be moved later**

### A Visual Sketch of How Forge Searches

Suppose we're using Forge to search for family trees. There are infinitely many potential family tree instances, but Forge needs to work with a finite search space. This is where the bounds of a `run` come in; they limit the set of instances Forge will even consider. Constraints you write are _not yet involved_ at this point.

Once the bounded search space has been established, Forge uses the constraints you write to find satisfying instances within the bounded search space.

![](https://i.imgur.com/eQ76Hv8.png)

The engine uses bounds and constraints very differently, and inferring constraints is often less efficient than inferring bounds. But the engine treats them differently, which means sometimes the distinction leaks through.

### "Nulls" in Forge

In Forge, there is a special value called `none`. It's analogous (but not the same!) to a `null` in languages like Java. 

Suppose I added this predicate to our `run` command in the tic-tac-toe model:

```alloy
pred myIdea {
    all row1, col1, row2, col2: Int | 
        (row1 != row2 or col1 != col2) implies
            Game.initialState.board[row1][col1] != 
            Game.initialState.board[row2][col2]
}
```

I'm trying to express that every entry in the board is different. This should easily be true about the initial board, as there are no pieces there.

For context, recall that we had defined a `Game` sig earlier:

```alloy
one sig Game {
  initialState: one State,
  nextState: pfunc State -> State
}
```

What do you think would happen?

<details>
<summary>Think (or try it in Forge) then click!</summary>

It's very likely this predicate would be unsatisfiable, given the constraints on the initial state. Why? 
    
Because `none` equals itself! We can check this:
    
```alloy
test expect {
    nullity: {none != none} is unsat
} 
```    
    
Thus, when you're writing constraints like the above, you need to watch out for `none`: the value for _every_ cell in the initial board is equal to the value for _every_ other cell!
</details>


~~~admonish tip title="Reachability and none"
The `none` value in Forge has at least one more subtlety: `none` is "reachable" from everything if you're using the built-in `reachable` helper predicate. That has an impact even if we don't use `none` explicitly. If I write something like: `reachable[p.spouse, Nim, parent1, parent2]` I'm asking whether, for some person `p`, their spouse is an ancestor of `Nim`. If `p` doesn't have a spouse, then `p.spouse` is `none`, and so this predicate would yield true for `p`.
~~~

### Some as a Quantifier Versus Some as a Multiplicity

The keyword `some` is used in 2 different ways in Forge:
* it's a _quantifier_, as in `some b: Board, p: Player | winner[s, p]`, which says that somebody has won in some board; and
* it's a _multiplicity operator_, as in `some Game.initialState.board[1][1]`, which says that that cell of the initial board is populated. 

### Implies vs. Such That

You can read `some row : Int | ...` as "There exists some integer `row` such that ...". The transliteration isn't quite as nice for `all`; it's better to read `all row : Int | ...` as "In all integer `row`s, it holds that ...". 

If you want to _further restrict_ the values used in an `all`, you'd use `implies`. But if you want to _add additional requirements_ for a `some`, you'd use `and`.  Here are 2 examples:
* **All**: "Everybody who has a `parent1` doesn't also have that person as their `parent2`": `all p: Person | some p.parent1 implies p.parent1 != p.parent2`.
* **Some**: "There exists someone who has a `parent1` and a `spouse`": `some p: Person | some p.parent1 and some p.spouse`.

**Technical aside:** The type designation on the variable can be interpreted as having a character similar to these add-ons: `and` (for `some`) and `implies` (for `all`). E.g., "there exists some `row` such that `row` is an integer and ...", or "In all `row`s, if `row` is an integer, it holds that...".

### There Exists `some` *Atom* vs. Some *Instance*

Forge searches for instances that satisfy the constraints you give it. Every `run` in Forge is about _satisfiability_; answering the question "Does there exist an instance, such that...". 

Crucially, **you cannot write a Forge constraint that quantifies over _instances_ themselves**. You can ask Forge "does there exist an instance such that...", which is pretty flexible on its own. E.g., if you want to check that something holds of _all_ instances, you can ask Forge to find counterexamples. This is how `assert ... is necessary for ...` is implemented, and how the examples from last week worked.

### One Versus Some

The `one` quantifier is for saying "there exists a UNIQUE ...". As a result, there are hidden constraints embedded into its use. `one x: A | myPred[x]` really means, roughly, `some x: A | myPred[x] and all x2: A | not myPred[x]`. This means that interleaving `one` with other quantifiers can be subtle; for that reason, we won't use it except for very simple constraints.

If you use quantifiers other than `some` and `all`, beware. They're convenient, but various issues can arise.

### Testing Predicate Equivalence

Checking whether or not two predicates are _equivalent_ is the core of quite a few Forge applications---and a great debugging technique sometimes. 

How do you do it? Like this:

```alloy
pred myPred1 {
    some i1, i2: Int | i1 = i2
}
pred myPred2 {
    not all i2, i1: Int | i1 != i2
}
assert myPred1 is necessary for myPred2
assert myPred2 is necessary for myPred1
```

If you get an instance where the two predicates aren't equivalent, you can use the Sterling evaluator to find out **why**. Try different subexpressions, discover which is producing an unexpected result! E.g., if we had written (forgetting the `not`):

```alloy
pred myPred2 {
    all i2, i1: Int | i1 != i2
}
```

One of the assertions would fail, yielding an instance in Sterling you could use the evaluator with.

#### More Testing Syntax and a Lesson

I'm not going to use this syntax in class if I don't need to, because it's less _intentional_. But using it here lets me highlight a common conceptual issue with Forge in general.

```alloy
test expect {
    -- correct: "no counterexample exists"
    p1eqp2_A: {
        not (myPred1 iff myPred2)        
    } is unsat
    -- incorrect: "it's possible to satisfy what i think always holds"
    p1eqp2_B: {
        myPred1 iff myPred2
    } is sat

}
```

These two tests do not express the same thing! One asks Forge to find an instance where the predicates are not equivalent (this is what we want). The other asks Forge to find _an_ instance where they _are_ equivalent (this is what we're hoping holds for any instance, not just one)!

~~~admonish warning title="Use `assert`" 
We encourage using `assert` whenever possible in practice. We'll show you soon how to use `assert` with predicates that take arguments, etc. 
~~~