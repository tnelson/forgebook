#lang forge 

/*
  "There's lights that are on and lights that are off."
*/

/*
-- There is a kind of thing called a university. 
sig University {}
-- There is a specific, particular university: Brown. And another, WPI
one sig Brown, WPI extends University {} 
-- but there might be _other_ Universities. 
-- If I had instead said:
abstract sig University {} 
-- then the only universities allowed would be Brown and WPI, because "abstract"
-- means that you can be a university, but you must be something more specific too.
-- without abstract, you can just be a university and nothing more specific. 
-- I can make a hierarchy: 
abstract sig University {}  -- the only universities allowed are ones that "fit" sub-types
sig TwoYear, FourYear extends University {} -- you CAN be just an anonymous TwoYear or FourYear
-- but you could also be something more specific 
one sig WPI extends FourYear {}
one sig DVC extends TwoYear {}
one sig Brown extends FourYear {}
*/

-- A status is either on or off. 
abstract sig Status {}
-- Just like "Brown University" there is only *one* object that represents "On"-ness.
-- "On" is a type. But there's only ever "one" of it. So we can use it to refer to that value.
one sig On, Off extends Status {}

-- I can have as many lights as I want. 
sig Light {
  --status: one Status, -- but each light has only one status
  neighbors: set Light -- my neighbors change too when my lever is pulled
}

-- run {} for exactly 5 Light

-- GEOMETRY!!!
pred wellformed { 
  -- neighbors are neighbors of each other
  -- ANY PAIR of lights you find in the instance... 
  all l1, l2: Light | {
    -- ... this has to be true.
    -- "all" can be read "any". It's short for "for all ..."
    (l1 in l2.neighbors and l2 in l1.neighbors)
    or
    (l1 not in l2.neighbors and l2 not in l1.neighbors)
  }
  -- no being your own neighbor
  all l: Light | l not in l.neighbors
}

-- HOW ARE THE LIGHTS LAID OUT?
pred puzzle_shape {
    -- Linear puzzle
    -- There are start and end lights 
    some s, e: Light | { 
        s != e 
        one s.neighbors 
        one e.neighbors 
        (s not in e.neighbors and e not in s.neighbors)

        -- Each light only has two neighbors 
        all l: Light | { 
            l = s or 
            l = e or 
            #l.neighbors = 2
        }
        -- Tim might have written this (stylistic choice, because highlights the obligation)
        -- ... but let's check to make sure that these are the same?
        all l: Light | (l != e and l != s) implies {
            #l.neighbors = 2
        }
    }
    -- s and e are only available INSIDE their squigglies (so not out here!)
    
}


pred puzzle {
  -- there is some light that starts on
  //some l: Light | l.status = On
}

-- We can tell Forge to NOT try to eliminate instances that are "the same"
-- (Definition: up to renaming atoms, but NOT shuffling any "one sig"s or fields etc.)
-- option sb 0

/*
run {
  wellformed
  puzzle_shape
} for exactly 5 Light
*/


------------------
-- Let's find out!

pred way1[s, e: Light] {
    all l: Light | { 
        l = s or 
        l = e or 
        #l.neighbors = 2
    }
}
pred way2[s, e: Light] {
    all l: Light | (l != e and l != s) implies {
        #l.neighbors = 2
    }
}
-- If both of these tests pass, they are logically equivalent (UP TO THE BOUNDS GIVEN)!
assert all s,e: Light | way1[s,e] is sufficient for way2[s,e] for 10 Light
assert all s,e: Light | way2[s,e] is sufficient for way1[s,e] for 10 Light
