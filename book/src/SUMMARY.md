<!-- This will be ignored by the mdbook parser -->
<!-- # Logic for Systems: Lightweight Formal Methods for the Practical Engineer -->
# Summary 
[How to Read this book](./welcome.md)
<!-- "prefix chapters"; cannot be nested -->

# Preamble: Beyond Testing
- [Logic for Systems](./chapters/manifesto/manifesto.md)
- [What good is this book? (TODO: pull some context from paper)](./chapters/manifesto/job.md) 
- [From Tests to Properties](./chapters/properties/pbt.md)

<!-- # What do tic-tac-toe, binary trees, and operating systems have in common? -->
<!-- STATIC INSTANCES; NO TRANSITIONS YET -->
# Modeling Static Scenarios
- [Tic-Tac-Toe](./chapters/ttt/ttt.md)             
- [Binary Search Trees](./chapters/bst/bst.md)     
- [Ripple-Carry Adder (TODO: FINISH VERIFICATION PROSE, PICTURES)](./chapters/adder/rca.md)   
- [Q&A: Static Modeling](./chapters/qna/static.md) 

<!-- - The challenge of testing
  - Python: tic-tac-toe. Let's test our TTT program.
    - What does it mean to test such a program?
    - Fuzzing (doesn't crash mid-game)
    - Is there only one "best" move? No. Relational problems.
    - Property-based testing (generator vs. is-valid) 
    
    
    - Satisfiability and unsatisfiability
    - => as "if"; classical logic weirdness when it comes up first
    - methodology, shapes
    -->

<!--
- From tests to specification   [ended up doing this in reverse]
    - our is-valid looks really similar to Froglet predicate
    - our generator looks really similar to a different Froglet predicate
    - algorithms differ, specification is forever (random search vs bounded-exhaustive search vs proof vs…) -->

# Discrete Event Systems
- [T.T.T. Games: Inductive Verification (EDIT)](./chapters/ttt/ttt_games.md)
- [Counterexamples to Induction: Binary Search on Arrays (EDIT)](./chapters/inductive/bsearch.md)
- [BSTs: Recursive Descent (EDIT)](./chapters/bst/descent.md)
- [Validating Models (FILL)](./chapters/validation/validating_events.md) 
- [Q&A: Event Systems (FILL/ADAPT)](./chapters/qna/events.md) 

<!-- correspondence??? -->

   <!-- - Froglet: binary search on array model
        - Preservation of invariant
        - Preservation fails: binary search is broken (if the array is too big – see Bloch’s post)
        - Enrichment of invariant -->

<!-- can we trust the model?
        - vacuity, other pitfalls in verification -->

# Modeling Relationships 
- [Relational Forge, Modeling Logic (EDIT)](./chapters/relations/modeling-booleans-1.md)
- [Reachability](./chapters/relations/reachability.md)
- [Modeling Mutal Exclusion](./chapters/relations/sets-induction-mutex.md)
- [Beyond Assertions](./chapters/relations/sets-beyond-assertions.md)
- [Reference-Counting Memory Management (FILL)]()

- [Validating Relational Models (FILL)]()
- [Comparing Prim's and Dijkstra's Algorithms (FILL from model)]()
- [How does Forge Work?](./chapters/solvers/bounds_booleans_how_forge_works.md)
- [Q&A: Relations]() 

<!-- ## Atoms from bits (Relational Forge)
 
  - Relations in Forge (cities, objects/heap, course requirements, ACL synthesis)
	- Lab follow-up: reference-counting GC

  - Relational: Boolean logic (modeled)

  - Relational: Prim’s algorithm (modeled, validation)
  - Prim's vs. Dijkstra's (both so alike, but so different)

  - Validation (part 2)
     - domain vs. system, “optional” predicates, combinations and consistency

  - Correspondence between models, abstraction functions
  - Tying it all together: how does Forge work?
 -->

# Temporal Specification
- [Safety and Liveness](./chapters/temporal/liveness_and_lassos.md)
- [Temporal Forge 1](./chapters/temporal/temporal_operators.md)
- [Temporal Forge 2](./chapters/temporal/temporal_operators_2.md)
- [Obligations and the Past](./chapters/temporal/obligations_past.md)
- [Modeling Mutual Exclusion](./chapters/temporal/fixing_lock_temporal.md)
- [Validation: Temporal Pitfalls]()
- [Q&A: Temporal Logic]() 

<!--  
## Tomorrow and Tomorrow and Tomorrow (Temporal Forge)

  - Relational: Mutual exclusion: "Lock 1" from 1760 (raising flags)
      - Back to induction: mutual-exclusion preserved
      - But non-starvation is more subtle, calls for more language power!

  - Temporal: basic model (counter, lights puzzle) LTL, liveness, and lassos
      - eventually, always, next state
      - until
      - past-time operators

  - Temporal: Lock1: Deadlock vs. Livelock
      - Modeling "Oops" for Lock1

  - Temporal: "Lock 2" from 1760 (polite processes)
      - Modeling "Oops" for Lock2: The importance of a good domain model

  - Temporal: Peterson's lock (combining Lock1 + Lock2)
      - Fairness: precondition or property?

  - Validation (part 3): temporal pitfalls
  -->

# Case Studies
- [Model-Based ("Stateful") Testing (FILL)]()
- [Concolic Execution (DEMO: KLEE)]()
- [Policy and Network Analysis (DEMO: ABAC, Margrave, Zelkova)]()
- [Crypto Protocol Analysis (DEMO: crypto lang, CPSA or other)]()
- [Program Synthesis (DEMO: SSA synth, Sygus)]()

<!-- ## Case Studies: Applications and Demos

  - Policy / firewall analysis, control
    - Reading: Zelkova, Azure
    - Demo: ABAC language

  - Crypto
    - Reading: CPSA, ProVerif, (+ the one with pictures we cited)
    - Demo: Needham-Schr. Language

  - Synthesis
    - Reading: SSA bit-vector function synthesis, SyGuS
    - Demo: Resistor / novelty clock language

  - …many more…

  - Model-based testing (“stateful testing”) 
     - Hypothesis
     - (Need a good MBT example to use Forge for test generation. Another DSL input?) -->


  
<!-- ## Forge documentation (living document)

- Docs and book should be combined. -->

<!-- ## Modeling Tips

- Guide to debugging models
  - the evaluator 
  - cores 
- tips and tricks
- modeling pitfalls (a la Jackson) – higher-order quant, bounds, etc.  
 -->




<!-- ## Solvers and algorithms

  - Boolean SAT (DPLL)

  - Propositional Resolution
    - Model (likely can’t model full SAT runs, but can model steps)

  - Tracking learned clauses in SAT

  - SMT: eager vs. lazy, boolean skeletons
  - SMT: example theory solver: integer inequalities

  - CEGIS

  - Decidability, completeness, and incompleteness -->

# Construction Storage
- [unused 1](./chapters/solvers/cegis.md)
- [unused 2](./chapters/solvers/dpll.md)
- [unused 3](./chapters/solvers/resolution.md)
- [unused 4](./chapters/solvers/smt.md)


# Forge Documentation
- [Placeholder Test for search](./chapters/docs/test.md)


<!-- ## Exercises

Python:
  - PBT
Froglet:
  - ABAC + Intro Froglet (family trees)
  - Physical keys and locks
  - Curiosity Modeling (hard to put into a textbook, but can frame it)
Relational Forge:
  - Memory management
Temporal Forge:
  - River crossing, correspond. between puzzles
  - Tortoise and Hare algorithm
  - Elevators
Algorithms:
  - SAT + PBT
  - SAT + Resolution + PBT
SMT:
  - Pythagorean triples
  - Kenken
  - Synthesis

-->
