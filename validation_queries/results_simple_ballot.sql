--------------------------------------------------------------------------
-- Results - Simple Ballot
--  NOTE: you must run base_views before running this query
--------------------------------------------------------------------------

select 
    proposal_id, 
    question, 
    choice, 
    sum(weight) as weight, 
    count(*) as num_votes
from (
    -- run only this inner query to get raw results
    select 
        v.tx_hash,
        p.proposal_id,
        q.question,
        c.choice,
        v.stake_address,
        coalesce(es.amount / 1000000.0, 0) as weight,
        v.vote_num
    from voteaire_votes v
        inner join voteaire_proposals p on  v.proposal_id = p.proposal_id
        inner join voteaire_questions q on  v.question_id = q.question_id
        inner join voteaire_choices c on  v.choice_id = c.choice_id
        left join epoch_stake es on p.snapshot_epoch::int = es.epoch_no
            and es.addr_id = v.stake_address_id
    where v.proposal_id = '040b2f6e-73c5-4d2f-a0e9-f59c5e9c1a11' -- proposal_id
        and v.vote_num = 1 -- only take the first vote if they voted multiple times
        and v.delegation_id is not null --ensure this was a delegation transaction to prove ownership of stake address
) a
group by proposal_id, question, choice
