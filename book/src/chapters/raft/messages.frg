#lang forge/temporal 

/*
  A simple model of message passing. To the extent possible, this model should be 
  domain-inspecific; it can be imported and its predicates called from the transitions
  of other models. 

  NOT MODELED: message replay, message alteration in transit
*/

abstract sig Message {}
one sig Network {
    messages: set Message 
}

/** When the system starts, there are no messages "in flight". */
pred message_init { 
    no Network.messages
}

/** Add a message to the set of messages "in flight". */ 
pred send[m: Message] {
    Network.messages' = Network.messages + m
}

/** A message can also be received if it's "in flight". */
pred receive[m: Message] {
    Network.messages' = Network.messages - m
}

/** A message might be dropped. On the surface, this is the same as `receive`. */
pred drop[m: Message] {
    Network.messages' = Network.messages - m
}