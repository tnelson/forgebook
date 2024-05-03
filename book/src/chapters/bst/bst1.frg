#lang forge/bsl 
-- TODO: rename language

option run_sterling "./bst.js"
-- TODO: resolve this outside dev mode (TN)

sig Node {
  key: one Int,     -- every node has some key 
  left: lone Node,  -- every node has at most one left-child
  right: lone Node  -- every node has at most one right-child
}

pred isRoot[n: Node] {
  -- a node is a root if it has no ancestor
  no n2: Node | n = n2.left or n = n2.right
}

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

-------------------------------------------------------------------------------
-- Positive examples 
-------------------------------------------------------------------------------

-- A binary tree with no nodes should be considered well-formed.
example p_no_nodes is wellformed for {
  no Node  -- there are no nodes in the tree; it is empty
}

-- A binary tree with a single node should be considered well-formed. 
example p_one_nodes is wellformed for {
  Node = `Node0 -- there is exactly one node in the tree, named "Node0".
  no left       -- there are no left-children
  no right      -- there are no right-children
}

-- A binary tree with more than one rank should be considered well-formed. 
example p_multi_rank is wellformed for {
  Node = `Node0 +                               -- rank 0
         `Node1 + `Node2 +                      -- rank 1
         `Node3 + `Node4 + `Node5 + `Node6      -- rank 2
  
  -- Define the child relationships (and lack thereof, for leaves)
  -- This is a bit verbose; we'll learn more concise syntax for this soon!
  `Node0.left = `Node1 
  `Node0.right = `Node2
  `Node1.left = `Node3
  `Node1.right = `Node4
  `Node2.left = `Node5
  `Node2.right = `Node6
  no `Node3.left  no `Node3.right 
  no `Node4.left  no `Node4.right 
  no `Node5.left  no `Node5.right 
  no `Node6.left  no `Node6.right 
}


-- An unbalanced binary tree is still well-formed.
example p_unbalanced_chain is wellformed for {
  Node = `Node0 + `Node1 + `Node2 + `Node3
  
  -- Form a long chain; it is still a binary tree.
  `Node0.left = `Node1 
  no `Node0.right 
  `Node1.left = `Node2
  no `Node1.right
  `Node2.left = `Node3
  no `Node2.right 
  
  no `Node3.left  no `Node3.right 
}

-------------------------------------------------------------------------------
-- Negative examples
-------------------------------------------------------------------------------

-- A single node that is its own left-child is not well-formed. 

-- A single node that is its own right-child is not well-formed. 

-- A single node that's reachable via a longer cycle using both left- and right-children is not well-formed. 

-- A "forest" of multiple, disconnected trees is not well-formed. 
