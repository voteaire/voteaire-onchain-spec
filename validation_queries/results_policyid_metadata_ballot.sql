------------------------------------------------------------------------------------------------
-- Results - PolicyIDMetadata type vote
--  NOTE: this requires you to run the base_views.sql and policyid_metadata_snapshot.sql script first
-------------------------------------------------------------------------------------------------
	

select 
    proposal_id, 
    question, 
    choice, 
    sum(weight) as weight, 
    count(*) as num_votes
from (
    select 
        v.tx_hash,
        p.proposal_id,
        q.question,
        c.choice,
        v.stake_address,
        s.amount as weight,
        v.vote_num
    from voteaire_votes v
        inner join voteaire_proposals p on  v.proposal_id = p.proposal_id
        inner join voteaire_questions q on  v.question_id = q.question_id
        inner join voteaire_choices c on  v.choice_id = c.choice_id
        left join (
            select 
                stake_address_id, 
                sum(amount) as amount
            from (
                select 
                    stake_address_id, 
                    (quantity * CAST((json_data ->> 0) AS int)) as amount
                from tmp_voteaire_snapshot, 
                    LATERAL jsonb_path_query(metadata, '$.id') as json_data
            ) t
            group by stake_address_id
        ) s on s.stake_address_id = v.stake_address_id
    where v.proposal_id = '26bdef23-5ee9-41d1-abc4-454f0c37571f' 
        and v.vote_num = 1 
        and v.delegation_id is not null 
) a
group by proposal_id, question, choice
