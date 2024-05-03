# Intro to Modeling Systems (Part 2: BSTs)

Now that we've written our first model&mdash;tic-tac-toe boards&mdash;let's switch to something a bit more serious: binary search trees. A binary search tree (BST) is a binary tree with an added property about its structure. Let's start modeling. As before, we'll follow this rough 5-step progression:
  - define the pertinent datatypes and fields;
  - define a well-formedness predicate;
  - write some examples;
  - run and exercise the base model; 
  - write domain predicates.
Keep in mind that this isn't a strict "waterfall" style progression; we may return to previous steps if we discover it's necessary. 

## Datatypes 

A binary tree is made up of nodes. Each node in the tree has at most one left child and at most one right child. Unlike in tic-tac-toe, this definition is recursive:

```forge,editable
#lang forge/froglet
sig Node {
  key: one Int,     -- every node has some key 
  left: lone Node,  -- every node has at most one left-child
  right: lone Node  -- every node has at most one right-child
}
```

## Wellformedness

What makes a binary tree a binary tree? We might start by saying that: 
* it's _tree-shaped_: there are no cycles and nodes have at most one parent node; and 
* it's _connected_: all non-root nodes have a common ancestor. 

It's sometimes useful to write domain predicates early, and then use them to define wellformedness more clearly. For example, let's encode what it means for a node to be a root node:

```forge,editable
pred isRoot[n: Node] {
  -- a node is a root if it has no ancestor
  no n2: Node | n = n2.left or n = n2.right
}
```

```forge,editable
pred wellformed {
  -- no cycles: no node can reach itself via a succession of left and right fields
  all n: Node | not reachable[n, n, left, right] 
  
  -- all non-root nodes have a common ancestor from which both are reachable
  -- the "disj" keyword means that n1 and n2 must be _different_
  all disj n1, n2: Node | (not isRoot[n1] and not isRoot[n2]) implies {
    some anc: Node | reachable[n1, anc, left, right] and 
                     reachable[n2, anc, left, right] }

  -- nodes have a unique parent (if any)
  all disj n1, n2, n3: Node | 
    not ((n1.left = n3 or n1.right = n3) and (n2.left = n3 or n2.right = n3))
}
```

## Write an example or two

**TODO: this should come second, probably**

**[FILL: example trees: singleton, empty, unbalanced...]**

It's often best to write some positive _and_ negative examples. I've listed some possibilities below. 

~~~admonish note title="Are these examples enough?"
Just like with testing a program, it's not always immediately clear when to _stop_ testing a model. 
Fortunately, Forge gives us the ability to explore and exercise the model more thoroughly than just 
running a program does. 
~~~

### Positive examples

A binary tree with no nodes should be considered well-formed.

A binary tree with a single node should be considered well-formed. 

A binary tree with more than one rank should be considered well-formed. 

An unbalanced binary tree is still well-formed.

### Negative examples 

A single node that is its own left-child is not well-formed. 

A single node that is its own right-child is not well-formed. 

A single node that's reachable via a longer cycle using both left- and right-children is not well-formed. 

A "forest" of multiple, disconnected trees is not well-formed. 

## View some instances

```
-- View a tree or two
run {binary_tree} for exactly 8 Node
```

**[FILL: Oops, not quite right, we were missing a constraint; underconstraint bug -- fix it]**

Missing: 
```
  -- left+right differ (unless both are empty)
  all n: Node | some n.left => n.left != n.right 
```

**FILL: and iterate.**

## Going further

```
-- Run a test: our predicate enforces a unique root exists (if any node exists)
pred req_unique_root {   
  no Node or {
    one root: Node | 
      all other: Node-root | other in descendantsOf[root]}}
assert binary_tree is sufficient for req_unique_root for 5 Node  
```









