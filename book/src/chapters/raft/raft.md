# Modeling Raft 

This case study is going to be personal. That is, I'll be modeling a protocol from scratch in the honest desire to understand it better. I'll be making false starts or modeling mistakes, and leaving all of that in as part of the story. I'll talk through recovering from my own mistakes, and in the end hopefully both understand this protocol better myself _and_ show you how you might approach modeling a larger system in Forge. 

In this section, we'll be modeling [Raft](https://raft.github.io) in **Temporal Forge**. This isn't a distributed-systems textbook, so if you're curious about more details than I cover here, you should check out the Raft Github, some of the [implementations](https://raft.github.io/#implementations) (including [the one powering etcd](https://github.com/etcd-io/raft)), or the original 2014 [Raft paper](https://raft.github.io/raft.pdf) by Ongaro and Ousterhout.

## What is Raft?

Suppose you're storing multiple copies of the same data on different servers around the world. You'd really like to make sure that the data stored on each replica server is _actually the same_ data, i.e., that your replicas aren't gradually slipping out of agreement with one another. This is called _distributed consensus_. Raft is a protocol for achieving distributed consensus without anything like a shared clock or a trusted third party. 

Raft claims to be an "understandable" consensus protocol, or at least more understandable than the original, brilliant but famously difficult to understand [Paxos protocol](https://en.wikipedia.org/wiki/Paxos_(computer_science)). Since I don't understand Paxos either, I'm hoping that Raft lives up to that intention. 

~~~admonish note title="Full Disclosure" 
I _have_ seen a couple of lectures on Raft, one of which was delivered by the excellent [Doug Woos](https://www.dougwoos.com). Unfortunately, as with all such things, I've since forgotten almost everything I thought I'd learned. But I do have some pre-existing intuition, in my subconscious if nowhere else. 

Also, there does exist a formal model of Raft already, written in the TLA+ modeling language. I am deliberately *NOT* going to go looking at that model unless I really need to. Why not? Well, because Forge and TLA+ have somewhat different abstractions. But more importantly, I don't want bias how I think about Raft, especially early on. Reading others' formal models is useful, and if I were implementing Raft, I'd be referring to their model regularly. But I want to write my own, and understand the protocol better because of it. 
~~~

## Getting Started 

In a smaller system, we'd start by figuring out datatypes and writing examples. Here, though, there are many moving parts, and we can expect to iterate a few times on each, starting with a fairly abstract version. So we'll begin at a higher level, one that is more about sketching what's important than running Forge to get "results". 

What pieces does Raft have, or at least which pieces does it have that we expect we'll want to model? 
* Raft has a **leader election process**, wherein nodes that stop hearing from the current leader might be voted new leader by their peers. It's likely we'll need to model this election process, or at least some abstraction of leader replacement. (The time in which a specific node is the continuous leader is called a _term_.)
* Raft is based on a sequence of **log entries**, each of which describes a transaction which changes the underlying state. (This is where the name comes from: a raft is a sequence of logs.) We might not need to model the state itself, but we'll surely need to model log entries in order to detect whether they are being faithfully committed in the right order. 
* Raft runs on a network, and networks are imperfect. So some model of **message passing** seems reasonable. There are a few standard messages that Raft uses: update requests, vote requests, "heartbeat" messages from the leader, and so on. 

Now we should ask ourselves what we hope to get out of the model, because that will inform how we approach the above. Yes, I said my goal was the "understand Raft" but that's a little vague, isn't it? So let's ask a different question. What would it mean for Raft to "work"? Figure 3 of [the Raft paper](https://raft.github.io/raft.pdf) enumerates these, and I'll quote each verbatim here with my comments below each: 
* **Election Safety**: at most one leader can be elected in a given term. 
    * This seems simple enough to check. We'll just have a notion of roles for every node, and make sure that the leader role is always either empty or singleton.
* **Leader Append-Only**: a leader never overwrites or deletes entries in its log; it only appends new entries. 
    * This seems subtle to guarantee, since (it seems to me at first anyway!) network faults could cause a new leader to have bugs in its log that need resolving. But perhaps the election protocol is meant to prevent that. Anyway, this sounds like a place we can apply invariant-checking techniques we already know.
* **Log Matching**: if two logs contain an entry with the same index and term, then the logs are identical in all entries up through the given index. 
    * Ok, this seems to be saying that if two nodes think the same transaction appears in the same place under the same "reign", they can't disagree on anything beforehand. At first glance this seems like another inductive property, or at least a safety property we can check with Forge. But if we want to phrase the property identically to the paper, we'll want to model logs as indexed sequences (like arrays), not chains (like linked lists).
* **Leader Completeness**: if a log entry is committed in a given term, then that entry will be present in the logs of the leaders for all higher-numbered terms.
    * So there's some guarantee that the commitments of prior administrations will be respected by later leaders. Makes sense. Sounds like this is something else that the election protocol needs to guarantee; I'm getting a feeling that modeling leader election will be _essential_. Maybe we'll start there. 
* **State Machine Safety**: if a server has applied a log entry at a given index to its state machine, no other server will ever apply a different log entry for the same index. 
    * Like the previous property, this also sounds like it's about the distinction between the log and _committing_ entries in the log. We'll need some way to distinguish the two ideas eventually, although I'm not sure if we'll need to model the state machine fully. Let's wait to make that decision, and explore the protocol elsewhere first. 

~~~admonish warning title="Are these the right properties? We won't care right now." 
In a different setting, I'd ask you to consider whether these properties are the right ones. Although it's still a good idea to spend a minute considering that, I won't belabor the point here. Our goal is to understand the protocol, not critique it&mdash;at least not yet! So these are the properties we'll run with.
~~~

## Leader Election, Abstractly

Notice how thinking a little bit about the pieces of the system and the properties led to some idea of what's most important. The leader election seems vital to almost everything, and it's part of the protocol (as opposed to message passing, which may be vital but isn't about the protocol itself, but the network it runs on). So let's begin there. 

### Number of Servers

In Raft, every node knows how many total servers there are in the cluster. This is part of the configuration before startup, so we will assume that every server has, and agrees on, the correct cluster size. We won't create a field for this anywhere, we'll just feel free to use `#Server`&mdash;and make sure we don't allow the set of servers to vary! 

### Roles

A server can have one of three different roles. These are called "states" in the paper, but I find that a confusing term given just how many kinds of state there are here:

```forge
abstract sig Role {}
one sig Follower, Candidate, Leader extends Role {}
```

Every `Server` has exactly one role at any time. All servers begin as `Follower`s at startup. We'll express these facts as a `sig` definition and an initial-state `pred`, and add to both as we continue.

```forge
sig Server {
    var role: one Role
}
/** The initial startup state for the cluster */
pred init {
    all s: Server | { 
        s.role = Follower
    } 
}
```

### Leader Election

If a `Follower` hasn't heard from the leader recently (either via a state-update message or a heartbeat message), it will become a `Candidate`. In an actual implementation, "recently" would be concretely defined by a timeout value, but we'll try to avoid that here. The paper says: 

> To begin an election, a follower increments its current term and transitions to candidate state. It then votes for itself and issues RequestVote RPCs in parallel to each of the other servers in the cluster. A candidate continues in this state until one of three things happens: (a) it wins the election, (b) another server establishes itself as leader, or (c) a period of time goes by with no winner. 

And from Section 5.4.1,

> the voter denies its vote if its own log is more up-to-date than that of the candidate.

So we'll need to keep track of a server's current vote and enable it to send requests for votes. We'll also need to recognize the end of the election in these three different ways&mdash;we might start with just a single transition that incorporates all three, and expand it only if we need to. We'll omit modeling logs for the moment, but leave in a note so we don't forget. 

~~~admonish tip title="Be guided by the writeup!" 
I'll be guided by Figure 2 in the Raft paper, which gives field names and initial values for variables. E.g., it says that every server has a `votedFor` variable which starts out `null`. 
~~~

```forge
sig Server {
    var role: one Role,
    var votedFor: lone Server, -- NEW
    var currentTerm: one Int -- NEW
}
/** The initial startup state for the cluster */
pred init {
    all s: Server | { 
        s.role = Follower
        no s.votedFor -- NEW
        s.currentTerm = 0 -- NEW
    } 
}
```

Now let's create some abstract transitions.

#### Starting an Election

A `Follower` runs for leader if it hasn't heard from `Leader` node in some time. We haven't yet modeled message passing, and we really hope not to have to model time. But we can at least require the server be a `Follower` when it begins. 

```forge
/** Server `s` runs for election. */
pred startElection[s: Server] {
    s.role = Follower -- GUARD 
    s.role' = Candidate -- ACTION: in candidate role now
    s.votedFor' = s -- ACTION: votes for itself 
    s.currentTerm' = add[s.currentTerm, 1] -- ACTION: increments term
    -- ACTION: issues RequestVote calls
    -- ... we can't model this yet: no message passing
}
```

Ok, so should we immediately rush off to model message passing? I don't think so, we'd like to focus on the essence of leader election. So, instead, we'll have a transition that represents another server receiving that voting request, but guard it differently:

```forge
/** A server can vote for another server on request, 
    "on a first-come-first-served basis". */
pred makeVote[voter: Server, c: Server] {
    no s.votedFor -- GUARD: has not yet voted
    c.role = Candidate -- GUARD: election is running 
    noLessUpToDateThan[c, voter] -- GUARD: candidate is no less updated
    s.votedfor' = c -- ACTION: vote for c
}

/** Does the first server have a log that is no less up-to-date than
    the second server? 
*/
pred noLessUpToDateThan[moreOrSame: Server, baseline: Server] { 
    -- true (for now)
    -- TODO: once we model logs, the paper describes this relation as:
    --   the log with the later term is more up-to-date.
    --   if the logs end with the same term, then the longer log is more up-to-date.
}

#### Ending an Election

> A candidate wins an election if it receives votes from a majority of the servers in the full cluster for the same term. 

> Once a candidate wins an election, it becomes leader. It then sends heartbeat messages to all of the other servers to establish its authority and prevent new elections.

```forge
/** Server `s` wins the election. */
pred winElection[s: Server] {
    -- GUARD: won the majority
    #{voter: Server | voter.votedFor = s} > divide[#Server, 2]
    -- ACTION: become leader, send heartbeat messages
    s.role' = Leader 
    -- TODO: heartbeats
    -- For now, we'll just advance their terms and cancel votes
    -- directly, rather than using the network
    all f: Server - s | {
        f.role' = Follower
        no f.votedFor'
        f.currentTerm' = add[f.currentTerm, 1] 
    }
}

> if many followers become candidates at the same time, votes could be split so that no candidate obtains a majority. When this happens, each candidate will time out and start a new election by incrementing its term and initiating another round of RequestVote RPCs.

~~~admonish warning title="Random timeouts" 
Raft uses random timeouts to reduce the chances of a failed election. If elections fail over and over again, the cluster is stalled. We won't model this, but may have to add some assumptions later on.
~~~

```forge
/** Nobody has won the election after some time. */
pred haltElection[] {

}
```

