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
    nextState: pfunc SearchState -> SearchState
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

Let's do some basic validation:

```forge
test expect {
    -- let's check that these two transitions are mutually-exclusive
    r_l_together: {some s: SearchState | {descendLeft[s] and descendRight[s]}} for 7 Node is unsat
    -- let's check that transitions are all possible to execute
    r_sat: {some s: SearchState | descendRight[s]} for 7 Node is sat
    l_sat: {some s: SearchState | descendLeft[s]} for 7 Node is sat
    -- initial state is satisfiable
    init_sat: {some s: SearchState | init[s]} for 7 Node is sat
}
```

---

Now we'll combine these predicates into one that defines the entire recursive descent. The shape of this predicate is somewhat boilerplate; soon we'll see how to get rid of it entirely. For now, we'll just copy from the tic-tac-toe example and make small, local changes. Namely:
* we called the trace sig `Search`, not `Game`;
* we called the state sig `SearchState`, not `Board`; and 
* we have two different transition predicates to include.

```forge
pred traces {
    -- the graph is well-formed to begin with
    binary_tree
    -- The trace starts with an initial state
    init[Search.initialState]
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
run {traces} for exactly 7 Node, 5 SearchState for {nextState is plinear}
```

The output may initially be overwhelming: by default, it will show _all_ the atoms in the world and their relationships, including each `SearchState`. You could stay in the default visualizer and mitigate the problem a _little_ by clicking on "Theme" and then "Add Projection" for `SearchState`. The problem is that this hides the `current` node indicator for the current state, since the current state becomes implicit. 

Instead, let's use a custom visualization. There are multiple options included with this book:
* [`bst.js`](./bst.js), which visualizes the tree itself, without any regard to the descent. This is useful for debugging the basic tree model and the invariants themselves.
* [`bst_descent.js`](./bst_descent.js), which visualizes the _descent_ in one picture. 
* (Don't run this yet!) `bst_temporal.js`, which visualizes a Temporal Forge version of the model, which we'll get to soon.

If we run `bst_descent.js` for this instance, it will draw the tree and highlight the path taken in the recursive descent. A node with the target key will have a thick border. A node that's visited in the descent will have a red border. So a correct descent should never show a node with a thick border that isn't red. 

**TODO fill: how to run? Did we describe this already?**


### Different Invariants 


-- Let's look at traces of the search using each version of the invariant. 
-- If you use the custom visualizer, *visited* nodes will have a red border, 
-- and *target* node(s) will have a thick border.

-- We'll make this a bit more interesting, and tell Forge:
--   + not to show us immediate success/failure traces; and
--   + to show us traces where the target is present in the tree
// run {
//   some Node             -- non-empty tree
//   binary_search_tree_v1 -- use first invariant version
//   searchTrace           -- do a search descent
//   not stop              -- don't *immediately* succeed 
//   not next_state stop   -- don't succeed in 1 descent, either
//   SearchState.target in Node.key -- the target is present
// } for exactly 8 Node
// -- And the same using version 2:
// run {
//   some Node             -- non-empty tree
//   binary_search_tree_v2 -- use second invariant version
//   searchTrace           -- do a search descent
//   not stop              -- don't *immediately* succeed 
//   not next_state stop   -- don't succeed in 1 descent, either
//   SearchState.target in Node.key -- the target is present
// } for exactly 8 Node    -- don't *immediately* succeed 

// -- Use "Next Config" to move to a different tree example.
// -- One of the two should eventually produce an instance witnessing the _failure_ of 
// -- binary search: a target in the tree that is never found.

// ----------------------------------------------------------------------------------


