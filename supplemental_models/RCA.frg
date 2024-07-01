#lang forge/bsl

/*
  Model of a ripple-carry adder circuit. Adapted from an Alloy model of the same by 
  Julianne Rudner. Although the carrying can be thought of as temporal, here we model 
  the entire process as one monolithic execution -- i.e., with no propagation delay.

  This is an initial example, which we have not tried to optimize very much.
*/

/********************/
/* Data definitions */
/********************/

// Booleans, rather than integers, for wire values
abstract sig Bool {}
one sig True, False extends Bool {}

// Full adders, which will be chained together to form the ripple-carry adder
sig FA { 
  -- input and output bits 
  a, b: one Bool,  
  -- input carry bit
  cin: one Bool,
  -- output value
  s: one Bool,
  -- output carry bit 
  cout: one Bool
}

// The ripple carry adder, which chains together all the full adders
one sig RCA {
  -- the first full adder in the chain
  firstAdder: one FA,
  -- the next full adder in the chain (if any)
  nextAdder: pfunc FA -> FA
}

/******************/
/* Wellformedness */ 
/******************/

pred wellformed {
  -- there's some FA upstream from all other FAs
  all fa: FA | (fa != RCA.firstAdder) implies reachable[fa, RCA.firstAdder, RCA.nextAdder]
  -- there are no cycles 
  all fa: FA | not reachable[fa, fa, RCA.nextAdder]  
}

test expect {
    {wellformed} is sat
}

/**********************************************************************/
/* System predicates: define how each full adder behaves in isolation */ 
/**********************************************************************/

// Helper function: what is the output bit for this full adder?
fun adder_S_RCA[f: one FA]: one Bool  {
  // Note: "True" and "False" are values in the model, we cannot use them as Forge formulas.
  let A = (f.a = True), B = (f.b = True), CIN = (f.cin = True) |
	 ((A and B and CIN) or 
    (A and (not B) and (not CIN)) or 
    ((not A) and B and (not CIN)) or 
    ((not A) and (not B) and CIN))
	 	  =>   True 
      else False
} 

// Helper function: what is the output carry bit for this full adder?
fun adder_cout_RCA[f: one FA]: one Bool {
 let A = (f.a = True), B = (f.b = True), CIN = (f.cin = True) |
     ((not A and B and CIN) or 
      (A and not B and CIN) or 
      (A and B and not CIN) or 
      (A and B and CIN)) 
	      =>   True 
        else False
} 

// Full adder behavior
pred add_per_unit[f: FA] {
  -- Each full adder behaves as expected
  f.s = adder_S_RCA[f]
  f.cout = adder_cout_RCA[f]
  -- Full adders are chained appropriately
  --   (Note the parentheses here, which are necessary as of May 2024)
  (some RCA.nextAdder[f]) implies (RCA.nextAdder[f]).cin = f.cout 
}

/*****************************************************/
/* Top-level system specification: compose preds above
/*****************************************************/

pred rca {  
  wellformed
  all f: FA | add_per_unit[f] 
}


/*****************************************************/
/* Basic positive and negative examples for wellformed
/*****************************************************/

example twoAddersLinear is {wellformed} for {
  RCA = `RCA0 
  FA = `FA0 + `FA1
  -- Remember the back-tick mark here! These lines say that, e.g., for the atom `RCA0, 
  -- its firstAdder field contains `FA0. And so on.
  `RCA0.firstAdder = `FA0
  `RCA0.nextAdder = `FA0 -> `FA1
}

example twoAddersLoop is {not wellformed} for {
  RCA = `RCA0 
  FA = `FA0 + `FA1
  `RCA0.firstAdder = `FA0
  `RCA0.nextAdder = `FA0 -> `FA1 + `FA1 -> `FA0
}



// Specific example: add together 2 6-bit values. 
// We'll express this as a predicate to demonstrate the use of `let`.
// Note that the ordering of full adders starts with the *least* significant bit.
// 6'b100111+6'b100111, i.e., 32+4+2+1 (39) plus itself
pred example1_as_predicate {
    // Because these rely on the previous, each is a separate "let"
    let fa0 = RCA.firstAdder | 
    let fa1 = RCA.nextAdder[fa0] | 
    let fa2 = RCA.nextAdder[fa1] | 
    let fa3 = RCA.nextAdder[fa2] | 
    let fa4 = RCA.nextAdder[fa3] | 
    let fa5 = RCA.nextAdder[fa4] | {
        fa0.a=True  and fa0.b=True
        fa1.a=True  and fa1.b=True
        fa2.a=True  and fa2.b=True
        fa3.a=False and fa3.b=False
        fa4.a=False and fa4.b=False
        fa5.a=True  and fa5.b=True
    }
}

// Run example using 6 full adders (one for each bit of input)
test expect {
  consistency_e1_as_predicate: {rca example1_as_predicate} for 1 RCA, exactly 6 FA is sat
}

// We can also express this example as an `example` in Froglet, which will automatically 
// check that the instance given satisfies the predicate `rca`. 
example example1_as_example is {rca} for {
  RCA = `RCA0 
  FA = `FA0 + `FA1 + `FA2 + `FA3 + `FA4 + `FA5
  -- Remember the back-tick mark here! Dot in examples only works for assignment per _atom_.
  `RCA0.firstAdder = `FA0
  `RCA0.nextAdder = `FA0 -> `FA1 + `FA1 -> `FA2 + `FA2 -> `FA3 + 
                    `FA3 -> `FA4 + `FA4 -> `FA5
  -- We need to define True and False, if we want to use those sig names below
  True = `True0
  False = `False0
  Bool = True + False
  -- `example` does not support inline `and` like predicates do:
  `FA0.a = True   `FA0.b = True
  `FA1.a = True   `FA1.b = True
  `FA2.a = True   `FA2.b = True  
  `FA3.a = False  `FA3.b = False
  `FA4.a = False  `FA4.b = False     
  `FA5.a = True   `FA5.b = True
}

/////////////////////////////////////////////////////////////////////

-- run {rca}








/////////////////////////////////////////////////////////////////////

// To help ease verification, augment instances with place-values of each full adder
// which we can then use to compute the "true value" of an input or output. E.g., 
// the first full adder would have place-value 1, and its successors would have 
// place-value 2, then 4, etc. 
one sig Helper {
  place: func FA -> Int
}
-- The "places" value should agree with the "nextAdder" function.
pred assignPlaces {
  -- The least-significant bit is 2^0
  Helper.place[RCA.firstAdder] = 1
  -- Other bits are worth 2^(i+1), where the predecessor is worth 2^i.
  all fa: FA | some RCA.nextAdder[fa] => {    
    Helper.place[RCA.nextAdder[fa]] = multiply[Helper.place[fa], 2]
  }
}

fun trueValue[b: Bool, placeValue: Int]: one Int {
  -- TODO: for efficiency, would it be better to just use 0/1, not Bool?
  (b = True) => placeValue else 0
}

// Requirement: the adder is correct. We phrase this as: for every full adder, the true 
// value of its output is the sum of the true values of its inputs (where "true value" means 
// the value of the boolean, taking into account its position).
pred req_adderCorrect_wrong {
  (rca and assignPlaces) implies {
    all fa: FA | { 
        -- This will fail, because carrying needs to be considered, too. 
        -- Notice how even if the model (or system) is correct, sometimes the property is wrong!
        trueValue[fa.s, Helper.place[fa]] = add[trueValue[fa.a, Helper.place[fa]], 
                                                trueValue[fa.b, Helper.place[fa]]]
    }
  }
}
pred req_adderCorrect {
  (rca and assignPlaces) implies {
    all fa: FA | { 
        -- Include carrying, both for input and output. The _total_ output's true value is equal to
        -- the the sum of the total input's true value.

        -- output value bit + output carry bits; note carry value is *2 (and there may not be a "next adder")
        add[trueValue[fa.s, Helper.place[fa]], 
            multiply[trueValue[fa.cout, Helper.place[fa]], 2]] 
        = 
        -- input a bit + input b bit + input carry bit
        add[trueValue[fa.a, Helper.place[fa]],     
            trueValue[fa.b, Helper.place[fa]],    
            trueValue[fa.cin, Helper.place[fa]]]  
        -- Notice: I don't use trailing comments much on lines, because I want to be able to easily paste 
        -- these into the evaluator.
    }
  }
}

option sb 20000



test expect {
  -- Test with a bitwidth of 9, letting us count between [-256, 255].
  -- The maximum value we expect with *6* full adders is 111111 = 63, plus 
  -- a carry bit, giving us 1111111 = 127. We aren't using the negatives. 
  
  --r_adderCorrect: {req_adderCorrect} for 6 FA, 1 RCA, 8 Int is theorem

  r_adderCorrect: {req_adderCorrect} for 6 FA, 1 RCA, 8 Int for {nextAdder is plinear} is theorem
}

-- NOTE: very high #clauses: 645459; ~86 seconds to solve (quick translation)
--   remove boolean abstract?
--   eliminate negatives? (this is a case for actual integers, since we're talking of value)


/////////////////////////////////////////////////////////////////////
// TODO: validation

