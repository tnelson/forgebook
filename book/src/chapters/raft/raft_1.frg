#lang forge/temporal

/*
  Abstract model of leader election in the Raft protocol. 
*/

/*option solver MiniSatProver
option logtranslation 1
option coregranularity 1
option core_minimization rce
*/

abstract sig Role {}
one sig Follower, Candidate, Leader extends Role {}

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

/** Server `s` runs for election. */
pred startElection[s: Server] {
    s.role = Follower -- GUARD 
    s.role' = Candidate -- ACTION: in candidate role now
    s.votedFor' = s -- ACTION: votes for itself 
    s.currentTerm' = add[s.currentTerm, 1] -- ACTION: increments term
    -- ACTION: issues RequestVote calls
    -- ... we can't model this yet: no message passing
    
    -- FRAME: role, currentTerm, votedFor for all other servers
    all other: Server - s | {
        other.votedFor' = other.votedFor
        other.currentTerm' = other.currentTerm
        other.role' = other.role
    }
}


/** A server can vote for another server on request, 
    "on a first-come-first-served basis". */
pred makeVote[voter: Server, c: Server] {
    no voter.votedFor -- GUARD: has not yet voted
    c.role = Candidate -- GUARD: election is running 
    noLessUpToDateThan[c, voter] -- GUARD: candidate is no less updated

    voter.votedFor' = c -- ACTION: vote for c
    -- FRAME role, currentTerm for voter
    -- FRAME: role, currentTerm, votedFor for all others
    all s: Server | {
        s.role' = s.role
        s.currentTerm' = s.currentTerm
        (s != voter) => (s.votedFor' = s.votedFor)
    }
    
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


/** Server `s` is supported by a majority of the cluster.*/
pred majorityVotes[s: Server] {
    #{voter: Server | voter.votedFor = s} > divide[#Server, 2]
}
/** Server `s` wins the election. */
pred winElection[s: Server] {
    -- GUARD: won the majority
    majorityVotes[s]
    -- ACTION: become leader, send heartbeat messages
    s.role' = Leader 
    s.currentTerm' = s.currentTerm
    no s.votedFor' 

    -- TODO: heartbeats
    -- For now, we'll just advance their terms and cancel votes
    -- directly as a FRAME, rather than using the network
    all f: Server - s | {
        f.role' = Follower
        no f.votedFor'
        f.currentTerm' = add[f.currentTerm, 1] 
    }
}


/** Nobody has won the election after some time. */
pred haltElection {
    -- GUARD: there is some Candidate -- i.e., there is an election running
    some s: Server | s.role = Candidate
    -- GUARD: no server with the Candidate role has received a majority vote.
    --   (There is no requirement that everyone has voted; indeed, that wouldn't 
    --    work since the network might be broken, etc.)
    no s: Server | s.role = Candidate and majorityVotes[s]
    
    -- ACTION: each Candidate (not each server, necessarily) will increment their term
    --    and clear their vote.
    all c: Server | { 
        c.role = Candidate => c.currentTerm' = add[c.currentTerm, 1]
                         else c.currentTerm' = c.currentTerm
        no c.votedFor'
    }
    -- ACTION: initiating another round of RequestVote
    -- ... we can't model this yet: no message passing

    -- FRAME: nobody's role changes
    all c: Server | c.role' = c.role

}

pred election_doNothing {
    -- ACTION: no change
    role' = role
    votedFor' = votedFor
    currentTerm' = currentTerm
}

pred electionSystemTrace {
    init 
    always { 
        (some s: Server | startElection[s])
        or
        (some s, c: Server | makeVote[s, c])
        or 
        (some s: Server | winElection[s])
        or
        (haltElection)
        or 
        (election_doNothing)
    }
}

run { 
    electionSystemTrace 
    eventually {some s: Server | winElection[s]}
    #Server > 1
}