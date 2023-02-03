------------------------------------------------------------------------------------------------
-- Results - PolicyID type vote
--  NOTE: this requires you to run the base_views.sql and policyid_snapshot.sql script first
-------------------------------------------------------------------------------------------------
	

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
        s.amount  as weight,
        v.vote_num
    from voteaire_votes v
        inner join voteaire_proposals p on  v.proposal_id = p.proposal_id
        inner join voteaire_questions q on  v.question_id = q.question_id
        inner join voteaire_choices c on  v.choice_id = c.choice_id
        left join (
            select stake_address_id, sum(quantity) as amount
            from tmp_voteaire_snapshot
            group by stake_address_id
        ) s on s.stake_address_id = v.stake_address_id
    where v.proposal_id = 'c3e7e1cc-f5e1-4144-8a36-0da025c37d76' -- proposal_id
        and v.vote_num = 1 -- only take the first vote if they voted multiple times
        and v.delegation_id is not null --ensure this was a delegation transaction to prove ownership of stake address
) a
group by proposal_id, question, choice