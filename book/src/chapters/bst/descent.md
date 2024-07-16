# BSTs: Recursive Descent

When we last modeled [binary search trees](../bst/bst.md), we defined what it meant to be a binary tree, and had two different candidates for the BST invariant. Now we'll return to BSTs and model the classic recursive _BST search_ algorithm. Just like games of tic-tac-toe, a BST search can be represented as a sequence of states that evolve as the algorithm advances. 

As a reminder, we had defined binary-tree nodes like this:

```forge
sig Node {
  key: one Int,     -- every node has some key 
  left: lone Node,  -- every node has at most one left-child
  right: lone Node  -- every node has at most one right-child
}
```

Just like in the last example, we'll start by adding a sig for the state of the system. The "system" here is the recursive search, so it should have fields that are used in that context. Really, the only thing that changes during the recursive descent is the node currently being visited:

```forge
-- Since a BST descent doesn't need to backtrack, the state can be fairly simple.
sig SearchState {
    current: lone Node -- the node currently being visited
}
```

Then we'll define a `one` sig for the overall search. As with tic-tac-toe, Forge will find instances that represent a single search, embodied by the `Search` atom and its fields:

```forge
one sig Search {
    target: one Int, -- the target of the search (never changes)
    -- The first state and successor-state function for this trace
    initialState: one SearchState,
    nextState: pfunc Board -> Board 
}
```

What does an initial state of the search look like? We'd better be at the root of the tree! 

```forge
pred init[s: SearchState] {    
    isRoot[s.current]
}
```

Now for the more complicated part. How does a step of the recursive descent work? At any given node:
* First, it checks whether `current.key = target`. If yes, it's done.
* It checks whether `current.key < target`. If yes, it moves to the left child if it exists, and returns failure otherwise.
* It checks whether `current.key > target`. If yes, it moves to the right child if it exists, and returns failure otherwise.

That's not so bad, but it feels like there are two different kinds of transition that our system might take. Let's give each of them their own predicates, just to avoid them getting tangled with each other: 
* `descendLeft` will apply if the target is to the left.
* `descendRight` will apply if the target is to the right.
If neither can apply, the algorithm is done: either the target has been found, or the search has "hit bottom" without finding the target.

Let's start writing them, beginning with `descendLeft`. We'll follow the discipline of separating the _guard_ and _action_ of each transition `pred`:

```forge
pred descendLeft[pre, post: SearchState] {
  -- GUARD 
  Search.target < pre.current.key
  some pre.current.left
  -- ACTION
  post.current = pre.current.left
}
```

Because only the current node is a component of the search state, we only need to define the new current node in the action.

**Exercise:** Write `descendRight` yourself. The structure should be very similar to `descendLeft`. 

<details>
<summary>Think, then click!</summary>

You might write something like this:

```forge
pred descendRight[pre, post: SearchState] {
  -- GUARD 
  Search.target > pre.current.key
  some pre.current.right
  -- ACTION
  post.current = pre.current.right
}
```
</details>

---

Now we'll combine these predicates into one that defines the entire recursive descent. The shape of this predicate is somewhat boilerplate; soon we'll see how to get rid of it entirely. For now, we'll just copy from the tic-tac-toe example and make small, local changes. Namely:
* we called the trace sig `Search`, not `Game`;
* we called the state sig `SearchState`, not `Board`; and 
* we have two different transition predicates to include.

```forge
pred traces {
    -- The trace starts with an initial state
    starting[Search.initialState]
    no sprev: SearchState | Search.nextState[sprev] = Search.initialState
    -- Every transition is a valid move
    all s: SearchState | some Search.nextState[s] implies {
        descendLeft [s, Search.nextState[s]] or 
        descendRight[s, Search.nextState[s]]
    }
}
```

Let's run it!

```forge
run {traces} for exactly 7 Node
```

**TODO ....*