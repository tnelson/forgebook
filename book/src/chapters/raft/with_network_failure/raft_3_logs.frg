#lang forge/temporal 

open "messages.frg"
open "rpc.frg"
open "raft_3.frg" // election system


/** Is <e> considered committed from the perspective of leader <l>? */
pred is_committed[e: Entry, l: Server] {
    
}
