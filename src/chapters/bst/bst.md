# Modeling Systems (Basics: BSTs)

Let's move from tic-tac-toe to something more substantial: data structures and their correctness. In this section, we'll model _binary search trees_ and use Forge to investigate how and why they work. We'll start with modeling their structure, and later we'll model operations like `search`.

As before, we'll follow this rough progression:
  - define the pertinent datatypes and fields;
  - define a well-formedness predicate;
  - write some examples;
  - run and exercise the base model; 
  - write domain predicates.
Keep in mind that this isn't a strict "waterfall" style progression; we may return to previous steps if we discover it's necessary. 

~~~admonish warning title="TODO: sketch"
TODO: reader may need a quick primer
~~~

### Datatypes and fields

A binary search tree is, first and foremost, a binary tree. Each node in the tree has at most one left child and at most one right child. Unlike in tic-tac-toe, this definition is recursive:

```forge,editable
#lang forge/froglet
sig Node {
    left: lone Node, 
    right: lone Node
}
```

### Wellformedness

```forge,editable
pred wellformed {

}
```




- pull in progression of examples from Alloy/Forge talk. 
- stop short of traces; focus on getting to semantic diff between the invariants

- Note: perhaps these should be _staggered_ more? 
  - basic types
  - wellformedness
  - domain predicates
  - comparing different domain predicates
  - transitions (TTT only? -- comes later -- or need to add them to BST, which overcomplicates)
