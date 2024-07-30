#lang forge

/*
  Model of binary search trees + descent
  Tim, 2024

  Note assumption: this model doesn't take duplicate entries into account.
  This version is the _finite trace_ model, not the _temporal forge_ model.
*/

sig Node {
  key: one Int,     -- every node has some key 
  left: lone Node,  -- every node has at most one left-child
  right: lone Node  -- every node has at most one right-child
}
fun descendantsOf[ancestor: Node]: set Node {
  ancestor.^(left + right) -- nodes reachable via transitive closure
}
pred binary_tree {
  -- no cycles
  all n: Node | n not in descendantsOf[n] 
  -- connected via finite chain of left, right, and inverses
  all disj n1, n2: Node | n1 in n2.^(left + right + ~left + ~right)
  -- left+right differ (unless both are empty)
  all n: Node | some n.left => n.left != n.right 
  -- nodes have a unique parent (if any)
  all n: Node | lone parent: Node | n in parent.(left+right)
}

-- View a tree or two
-- run {binary_tree} for exactly 10 Node

-- Run a test: our predicate enforces a unique root exists (if any node exists)
pred req_unique_root {   
  no Node or {
    one root: Node | 
      all other: Node-root | other in descendantsOf[root]}}
assert binary_tree is sufficient for req_unique_root for 5 Node  

pred isRoot[n: Node] {
  -- a node is a root if it has no ancestor
  no n2: Node | n = n2.left or n = n2.right
}

---------------------------------------------------------------------------------

-- We have two potential predicates that might represent the ordering invariant.
-- One is correct, and the other is a common misunderstanding.

pred invariant_v1[n: Node] {
  -- "Every node's left-descendants..." via reflexive transitive closure
  all d: n.left.*(left+right)  | d.key < n.key
  -- "Every node's left-descendants..." via reflexive transitive closure
  all d: n.right.*(left+right) | d.key > n.key
}
pred binary_search_tree_v1 {
  binary_tree  -- a binary tree, with an added invariant
  all n: Node | invariant_v1[n]  
}
pred invariant_v2[n: Node] {
  -- "Every node's immediate children..."
  some n.left implies n.left.key < n.key
  some n.right implies n.right.key > n.key
}
pred binary_search_tree_v2 {
  binary_tree  -- a binary tree, with an added invariant
  all n: Node | invariant_v2[n]
}

-- Get examples of the difference between the two. 
-- bstdiff: run {not { binary_search_tree_v1 iff binary_search_tree_v2}} for 5 Node 
-- These definitely not the same. Let's explore the impact of the difference.

----------------------------------------------------------------------------------

-- Since a BST descent doesn't need to backtrack, the state can be fairly simple.
sig SearchState {
    current: lone Node -- the node currently being visited
}
one sig Search {
    target: one Int, -- the target of the search (never changes)
    -- The first state and successor-state function for this trace
    initialState: one SearchState,
    nextState: pfunc SearchState -> SearchState
}

-- Initial-state predicate for the search
pred init[s: SearchState] {    
    isRoot[s.current]
}

-- Transition predicates: descend from the current node into one of its children.
pred descendLeft[pre, post: SearchState] {
  -- GUARD 
  Search.target < pre.current.key
  some pre.current.left
  -- ACTION
  post.current = pre.current.left
}
pred descendRight[pre, post: SearchState] {
  -- GUARD 
  Search.target > pre.current.key
  some pre.current.right
  -- ACTION
  post.current = pre.current.right
}

pred traces {
    -- The trace starts with an initial state
    init[Search.initialState]
    no sprev: SearchState | Search.nextState[sprev] = Search.initialState
    -- Every transition is a valid move
    -- Every transition is a recursive step. Note that we don't need a "do nothing"
    -- transition here! (Why not?)
    all s: SearchState | some Search.nextState[s] implies {
        descendLeft [s, Search.nextState[s]] or 
        descendRight[s, Search.nextState[s]]
    }
    -- All SearchStates are used
    SearchState in Search.initialState.*(Search.nextState)
}

-- BASIC VALIDATION
test expect {
    -- let's check that these two transitions are mutually-exclusive
    r_l_together: {some s1,s2: SearchState | {descendLeft[s1, s2] and descendRight[s1, s2]}} for 7 Node is unsat
    -- let's check that transitions are all possible to execute
    r_sat: {some s1,s2: SearchState | descendRight[s1, s2]} for 7 Node is sat
    l_sat: {some s1,s2: SearchState | descendLeft[s1, s2]} for 7 Node is sat
    -- initial state is satisfiable
    init_sat: {some s: SearchState | init[s]} for 7 Node is sat
}

run {
  binary_tree 
  traces
  some s: SearchState | s.current.key = Search.target or no (s.current.left + s.current.right)
} for exactly 7 Node, 5 SearchState for {nextState is plinear}

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