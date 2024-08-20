#lang forge

option verbosity 3
sig Interface {}
sig IP {}
sig ForwardingTable {
  posture: set Interface -> IP -> IP -> Interface
}
run {} for 1 Interface, 1 IP, 1 ForwardingTable, 0 Int



