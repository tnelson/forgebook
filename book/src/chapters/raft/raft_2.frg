#lang forge/temporal

/*
  Abstract model of leader election in the Raft protocol. 
*/

open "messages.frg"
open "rpc.frg"

option max_tracelength 10

//option verbose 10

/*
option solver MiniSatProver
option logtranslation 2
option coregranularity 2
option core_minimization rce
*/

/** The initial startup state for the cluster */
pred init {
    message_init -- no messages in flight
    all s: Server | { 
        s.role = Follower
        no s.votedFor
        s.currentTerm = 0 
    } 
}

/** Server `s` runs for election. */
pred startElection[s: Server] {
    s.role = Follower -- GUARD 
    s.role' = Candidate -- ACTION: in candidate role now
    s.votedFor' = s -- ACTION: votes for itself 

    s.currentTerm' = add[s.currentTerm, 1] -- ACTION: increments term
    
    -- ACTION: issues RequestVote calls (MODIFIED)
    // The set of unused messages exists
    all other: Server - s | { some rv: RequestVote | { rvFor[s, other, rv] } }
    // They are all actually sent, with nothing received
    sendAndReceive[{rv: RequestVote | some other: Server | rvFor[s, other, rv]}, 
                   none & Message]
                   -- ^ Interestingly we need to do the intersection here, so the checker understands this empty set 
                   -- can't have type `Int`. 

    -- FRAME: role, currentTerm, votedFor for all other servers
    all other: Server - s | {
        other.votedFor' = other.votedFor
        other.currentTerm' = other.currentTerm
        other.role' = other.role
    }
}

/** Factor this out, since we'll use it twice (existence, set-builder) */
pred rvFor[s: Server, other: Server, rv: RequestVote] {
    rv not in Network.messages -- not currently being used
    rv.from = s
    rv.to = other
    rv.requestVoteTerm = s.currentTerm
    rv.candidateID = s
    rv.lastLogIndex = -1 -- TODO: NOT MODELING YET
    rv.lastLogTerm = -1 -- TODO: NOT MODELING YET
}



/** A server can vote for another server on request, 
    "on a first-come-first-served basis". */
pred makeVote[voter: Server, c: Server] {
    -- GUARD: has not yet voted *OR* has voted for this candidate (CHANGED)
    (no voter.votedFor or voter.votedFor = c) 
    voter.role in Follower + Candidate -- GUARD: avoid Leaders voting
    -- Removed, now that we see an explicit message
    --c.role = Candidate -- GUARD: election is running 
    noLessUpToDateThan[c, voter] -- GUARD: candidate is no less updated

    -- ACTION/GUARD: must receive a RequestVote message (NEW)
    -- ACTION/GUARD: must send a RequestVoteReply message (NEW)
    some rv: RequestVote, rvp: RequestVoteReply  | { 
        rv.to = voter
        rv.from = c
        voter.currentTerm <= rv.requestVoteTerm     
        
        rvp.to = c
        rvp.from = voter
        rvp.voteGranted = c -- stand-in for boolean true
        rvp.replyRequestVoteTerm = rv.requestVoteTerm

        sendAndReceive[rvp, rv] -- enforces message "unused"/"used" respectively
    }

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


/** Server `s` is supported by a majority of the cluster. E.g., 
  |cluster| = 5 ---> need 5/2 + 1 = 3 votes. */
pred receiveMajorityVotes[s: Server] {
    --#{voter: Server | voter.votedFor = s} > divide[#Server, 2]
    -- This formulation identifies the set of replies destined for this server, 
    -- and evaluates to true if they get removed from the message bag and there are 
    -- a sufficient number of them granting a vote.
    let voteReplies = {m: Network.messages & RequestVoteReply | m.to = s} | {
        receive[voteReplies]
        #{m: voteReplies | some m.voteGranted} > divide[#Server, 2]
    }
}
/** Server `s` wins the election. */
pred winElection[s: Server] {
    -- GUARD: won the majority (NOTE: this invokes a message predicate)
    receiveMajorityVotes[s]
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

    -- Frame the network state explicitly
    -- sendAndReceive[none & Message, none & Message]
    -- We don't need to do this, since the `receiveMajorityVotes` predicate does already.
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
    -- ... we can't model this yet: no message passing (TODO)

    -- FRAME: nobody's role changes
    all c: Server | c.role' = c.role

    -- Frame the network state explicitly
    sendAndReceive[none & Message, none & Message]
}

/** If a candidate or leader discovers that its term is out of date, it immediately reverts to follower state. 
    If the leader’s term (included in its RPC) is at least as large as the candidate’s current term, then the 
    candidate recognizes the leader as legitimate and returns to follower state. 
*/
pred stepDown[s: Server] {
    -- Two guard cases
    {
        -- GUARD: is leader, someone has a higher term (abstracted out message)
        s.role in Leader
        and
        (some s2: Server-s | s2.currentTerm > s.currentTerm)
    } or {
        -- GUARD: is candidate, someone claims to be leader and has term no smaller
        s.role in Candidate 
        and 
        (some s2: Server-s | s2.role = Leader and s2.currentTerm >= s.currentTerm)
    }

    -- ACTION: step down
    s.role' = Follower
    
    -- FRAME: all others equal; s same currentTerm and votedfor.
    all x: Server | {
        x.currentTerm' = x.currentTerm
        x.votedFor' = x.votedFor 
        (x != s) => x.role' = x.role
    }

    -- Frame the network state explicitly
    sendAndReceive[none & Message, none & Message]
}

/** Guardless no-op */
pred election_doNothing {
    -- ACTION: no change
    role' = role
    votedFor' = votedFor
    currentTerm' = currentTerm

    -- Frame the network state explicitly
    sendAndReceive[none & Message, none & Message]
}

/** Allow arbitrary no-op ("stutter") transitions, a la TLA+. We'll either 
    assert fairness, or use some other means to avoid useless traces. */ 
pred electionSystemTrace {
    init
    always { 
        (some s: Server | startElection[s])
        or
        (some s, c: Server | makeVote[s, c])
        or 
        (some s: Server | winElection[s])
        or 
        (some s: Server | stepDown[s])
        or
        (haltElection)
        or 
        (election_doNothing)
    }
}


/*
run { 
    electionSystemTrace 
    eventually {some s: Server | winElection[s]}
    #Server > 1
}
*/


-----------------------------
-- VALIDATION
-----------------------------

/*
-- Transition-system checks for combinations of transitions; no use of the trace pred yet.
test expect {
  -- All of these transitions (except the no-op) should be mututally exclusive. 
  overlap_start_make: {eventually {some s1, s2, s3: Server | startElection[s1] and makeVote[s2, s3]}} is unsat
  overlap_start_win: {eventually {some s1, s2: Server | startElection[s1] and winElection[s2]}} is unsat
  overlap_start_halt: {eventually {some s1: Server |     startElection[s1] and haltElection }} is unsat
  overlap_make_win: {eventually {some s1, s2, s3: Server | makeVote[s1, s2] and winElection[s3]}} is unsat
  overlap_make_halt: {eventually {some s1, s2: Server |     makeVote[s1, s2] and haltElection}} is unsat
  overlap_win_halt: {eventually {some s1: Server |     winElection[s1] and haltElection}} is unsat
  
  -- It should be possible to execute all the transitions. We'll encode this as specific
  -- orderings, rather than as 4 different "eventually transition_k" checks.
  
  -- Start -> Vote -> Win
  sat_start_make_win: {
    (some s: Server | startElection[s])
    next_state (some s1, s2: Server | makeVote[s1, s2])
    next_state next_state (some s: Server | winElection[s])
  } for 6 Message is sat 
  -- Start -> Vote -> Halt 
  sat_start_make_halt: {
    (some s: Server | startElection[s])
    next_state (some s1, s2: Server | makeVote[s1, s2])
    next_state next_state (haltElection)
  } is sat 
  -- Start -> Halt
  sat_start_halt: {
    (some s: Server | startElection[s])
    next_state (haltElection)
  } is sat 
  
  -- Start -> Vote -> Win -> Start
  sat_start_make_win_start: {
    (some s: Server | startElection[s])
    next_state (some s1, s2: Server | makeVote[s1, s2])
    next_state next_state (some s: Server | winElection[s])
    next_state next_state next_state (some s: Server | startElection[s])
  } is sat 
  

}



-- Transition-system checks that are aware of the trace predicate, but focus on interplay/ordering 
-- of individual transitions.
test expect {
  -- Cannot Halt, Vote, or Win until started
  win_implies_started: {
    electionSystemTrace implies
    (some s: Server | winElection[s]) implies 
    once (some s: Server | startElection[s])
  } is theorem 
  halt_implies_started: {
    electionSystemTrace implies
    (haltElection) implies 
    once (some s: Server | startElection[s])
  } is theorem 
  vote_implies_started: {
    electionSystemTrace implies
    (some s1, s2: Server | makeVote[s1, s2]) implies 
    once (some s: Server | startElection[s])
  } is theorem 
}

-- Domain-specific checks involving the trace pred
test expect {
  -- No server should ever transition directly from `Leader` to `Candidate`. 
  no_direct_leader_to_candidate: {
    electionSystemTrace implies
    (all s: Server | {
      always {s.role = Leader implies s.role' != Candidate}
    })} is theorem

  -- It should be possible to witness two elections in a row.
  two_elections_in_a_row: { 
    electionSystemTrace
    eventually {
        some s: Server | startElection[s] 
        next_state eventually (some s2: Server | startElection[s2])
    }
  } is sat

  -- It should be possible for two different servers to win elections in the same trace. 
  two_different_winners_in_succession: {
    electionSystemTrace
    some disj s1, s2: Server | {
        eventually s1.role = Leader 
        eventually s2.role = Leader 
    } } is sat

  -- It should be invariant that there is only ever at most one `Leader`. 
  invariant_lone_leader: {
    electionSystemTrace implies
    always {lone role.Leader}
  } is theorem
}
*/

run {
    init
    (some s: Server | startElection[s])
    next_state (some s1, s2: Server | makeVote[s1, s2])
    next_state next_state (some s1, s2: Server | makeVote[s1, s2])
    next_state next_state next_state (some s: Server | winElection[s])
} for exactly 3 Server, 10 Message
