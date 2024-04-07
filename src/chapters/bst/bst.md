# Intro to Modeling Systems (Part 2: BSTs)

Now that we've written our first model&mdash;tic-tac-toe boards&mdash;let's switch to something a bit more serious: binary search trees. A binary search tree (BST) with an added property about its structure. So let's start modeling by following the our 5-step process. 

## Datatypes 

A binary tree is made up of nodes:

```forge,editable
#lang forge/froglet
sig Node {
  key: one Int,     -- every node has some key 
  left: lone Node,  -- every node has at most one left-child
  right: lone Node  -- every node has at most one right-child
}
```

## Wellformedness

What makes a binary tree a binary tree? One way to say it is:
* it's _tree-shaped_: there are no cycles and nodes have at most one parent node; and 
* it's _connected_, that is, it's a tree and not a forest. 

Let's get started encoding this. Sometimes it can be helpful to write a domain predicate along with wellformedness, if it makes the model more clear, hence why we wrote `root`:

```forge,editable
#lang forge/froglet
sig Node {
  key: one Int,     -- every node has some key 
  left: lone Node,  -- every node has at most one left-child
  right: lone Node  -- every node has at most one right-child
}

pred root[n: Node] {
  -- a node is a root if it has no ancestor (note this doesn't enforce uniqueness)
  no n2: Node | n = n2.left or n = n2.right
}

pred wellformed {
  -- no cycles: no node can reach itself via a succession of left and right fields
  all n: Node | not reachable[n, n, left, right] 
  
  -- all non-root nodes have a common ancestor from which both are reachable
  -- the "disj" keyword means that n1 and n2 must be _different_
  all disj n1, n2: Node | (not root[n1] and not root[n2]) implies {
    some anc: Node | reachable[n1, anc, left, right] and 
                     reachable[n2, anc, left, right] }

  -- nodes have a unique parent (if any)
  all disj n1, n2, n3: Node | 
    not ((n1.left = n3 or n1.right = n3) and (n2.left = n3 or n2.right = n3))

}
```


## Write an example or two

## View some instances

```
-- View a tree or two
run {binary_tree} for exactly 8 Node
```

(Oops, not quite right, we were missing a constraint; underconstraint bug -- fix it)

```
  -- left+right differ (unless both are empty)
  all n: Node | some n.left => n.left != n.right 
```


## Going further


-- Run a test: our predicate enforces a unique root exists (if any node exists)
pred req_unique_root {   
  no Node or {
    one root: Node | 
      all other: Node-root | other in descendantsOf[root]}}
assert binary_tree is sufficient for req_unique_root for 5 Node  
...









