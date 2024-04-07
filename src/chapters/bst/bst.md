# Intro to Modeling Systems (Part 2: BSTs)

-- SEPARATE THIS: TTT up to _before_ transition predicates!!!


Now that we've written our first model&mdash;tic-tac-toe boards&mdash;let's switch to something a bit more serious: binary search trees. A binary search tree (BST) with an added property about its structure. So let's start with binary trees, and then add the search part. We'll start, as usual, by declaring the data type:

```forge,editable
#lang forge/bsl

sig Node {
  key: one Int,     -- every node has some key 
  left: lone Node,  -- every node has at most one left-child
  right: lone Node  -- every node has at most one right-child
}
```

So far, this datatype 

**TODO: check lang name, switch to froglet**

What makes a binary tree a binary tree? One way to say it is:
* it's a _tree_: there are no cycles and nodes have at most one parent node; and 
* 




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
run {binary_tree} for exactly 8 Node

-- Run a test: our predicate enforces a unique root exists (if any node exists)
pred req_unique_root {   
  no Node or {
    one root: Node | 
      all other: Node-root | other in descendantsOf[root]}}
assert binary_tree is sufficient for req_unique_root for 5 Node  



...









